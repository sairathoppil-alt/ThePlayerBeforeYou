extends Node3D

const TOWN_SCENE: PackedScene = preload("res://scenes/world/town_environment.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const INTERACTABLE_SCRIPT: Script = preload("res://scripts/world/adventure_interactable.gd")
const TOWN_LOCATIONS = preload("res://scripts/core/town_locations.gd")
const LAN_REPOSITORY_SCRIPT = preload("res://scripts/core/lan_state_repository.gd")
const DEFAULT_PLAYER_SPAWN := Vector3(14.0, 0.0, 31.0)
const WATER_LEVEL_SEQUENCE := [
	"water.level.lower",
	"water.level.bypass",
	"water.level.release",
]
const ELECTRICAL_SEQUENCE := [
	"electrical.route.cyan",
	"electrical.route.amber",
	"electrical.route.white",
]

@onready var _world_root: Node3D = $WorldRoot
@onready var _hud: CanvasLayer = $AdventureHUD

var _town_environment: Node3D
var _player: CharacterBody3D
var _remote_avatar: CharacterBody3D
var _timeline_role := "past"
var _network_mode := false
var _selected_slot := -1
var _temporal_flashlight_active := false
var _flashlight: SpotLight3D
var _save_timer := 0.0
var _remote_transform := Transform3D.IDENTITY
var _remote_state_available := false
var _remote_moving := false
var _remote_selected_item := ""
var _displayed_vision_active := false
var _last_time_echo_active := false
var _recorded_echo_active := false
var _recorded_echo_frames: Array = []
var _recorded_frame_index := 0
var _recorded_frame_timer := 0.0
var _recording_timer := 0.0
var _shared_repository: RefCounted
var _checkpoint_relocated := false


func _ready() -> void:
	_network_mode = not NetworkSession.room_address.is_empty()
	_timeline_role = NetworkSession.timeline_role if _network_mode else str(AdventureState.get_state().get("timeline", "past"))
	_shared_repository = LAN_REPOSITORY_SCRIPT.new() if _network_mode else null
	if _timeline_role not in ["past", "future"]:
		_timeline_role = "past"
	_spawn_town()
	_spawn_player()
	_spawn_collectibles()
	_spawn_controls()
	_spawn_mission_interactables()
	_spawn_puzzle_interactables()
	_connect_signals()
	_update_timeline_ui()
	_update_mission_marker_visibility()
	_hud.call(
		"setup_temporal_view",
		TOWN_SCENE,
		2046 if _timeline_role == "past" else 2026,
		_player.get_node("CameraPivot/SpringArm3D/Camera3D")
	)
	_hud.call("set_mouse_captured", true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_hud.call("show_notice", _start_message())
	if _checkpoint_relocated:
		_hud.call("show_notice", "Your first-mission checkpoint was too close to the dam; you were moved to the town square.")


func _process(delta: float) -> void:
	_update_interaction_prompt()
	_update_recorded_echo(delta)
	_record_partner_movement(delta)
	if _temporal_flashlight_active:
		_update_flashlight_target()
	_save_timer += delta
	if _save_timer >= 15.0:
		_save_timer = 0.0
		_save_checkpoint()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F4:
		if not _network_mode:
			_switch_local_timeline()
			get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if is_instance_valid(_player):
		_save_checkpoint()
	if TemporalEnergy.is_active("time_echo"):
		TemporalEnergy.deactivate("time_echo", "scene changed")
	if TemporalEnergy.is_active("temporal_vision"):
		TemporalEnergy.deactivate("temporal_vision", "scene changed")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _spawn_town() -> void:
	var year := 2046 if _timeline_role == "future" else 2026
	_town_environment = TOWN_SCENE.instantiate() as Node3D
	_town_environment.name = "Willowbrook_%d" % year
	_town_environment.set("timeline_year", year)
	_town_environment.set("create_interactive_structures", false)
	_world_root.add_child(_town_environment)


func _spawn_player() -> void:
	var checkpoint := AdventureState.get_player_checkpoint()
	var spawn_position: Vector3 = checkpoint["position"]
	var spawn_yaw := float(checkpoint["yaw"])
	var mission_progress: Dictionary = MissionSystem.get_progress()
	var mission_objectives: Dictionary = mission_progress.get("objectives", {})
	var is_first_mission := (
		str(mission_progress.get("active_mission", "")) == "echo_awakening"
		and mission_objectives.is_empty()
	)
	var dam_position: Vector3 = TOWN_LOCATIONS.LOCATIONS["river.dam"]
	if (
		is_first_mission
		and absf(spawn_position.x - dam_position.x) < 4.0
		and absf(spawn_position.z - dam_position.z) < 15.0
	):
		spawn_position = DEFAULT_PLAYER_SPAWN
		spawn_yaw = 0.0
		_checkpoint_relocated = true
	_player = PLAYER_SCENE.instantiate() as CharacterBody3D
	_player.name = "LocalPlayer"
	_player.set_meta("timeline_role", _timeline_role)
	_player.position = spawn_position
	_player.get_node("Visuals").rotation.y = spawn_yaw
	_player.get_node("CameraPivot").rotation.y = spawn_yaw
	_world_root.add_child(_player)
	_player.call("set_time_echo_device_owned", _has_item("item.time_echo_device"))
	_player.interact_requested.connect(_on_interact_requested)
	_player.pause_requested.connect(_on_pause_requested)
	_player.utility_requested.connect(_on_utility_requested)
	_player.ability_requested.connect(_on_ability_requested)
	_player.drop_requested.connect(_drop_selected_item)
	_player.slot_selected.connect(_select_slot)


func _spawn_collectibles() -> void:
	var source_items: Array[Dictionary] = [
		{"id": "item.wrench", "name": "Wrench", "category": "tool", "location": "town.workshop", "offset": Vector3(5.2, 0.4, 3.2)},
		{"id": "item.archive_plan", "name": "Construction Plan", "category": "document", "location": "town.archives", "offset": Vector3(-4.8, 0.2, 3.8)},
		{"id": "item.maintenance_key", "name": "Maintenance Key", "category": "key", "location": "town.maintenance_facility", "offset": Vector3(-5.0, 0.2, 0.0)},
		{"id": "item.copper_cable", "name": "Copper Cable", "category": "component", "location": "town.electrical_station", "offset": Vector3(5.0, 0.2, -2.0)},
		{"id": "item.shovel", "name": "Shovel", "category": "tool", "location": "town.construction_site", "offset": Vector3(5.1, 0.2, 3.5)},
		{"id": "item.field_recorder", "name": "Field Recorder", "category": "equipment", "location": "town.general_store", "offset": Vector3(5.0, 0.2, 2.0)},
		{"id": "item.plank_left", "name": "Support Timber A", "category": "component", "location": "town.workshop", "offset": Vector3(4.5, 0.2, 4.0), "required_timeline": "past"},
		{"id": "item.plank_right", "name": "Support Timber B", "category": "component", "location": "town.archives", "offset": Vector3(4.5, 0.2, 4.0), "required_timeline": "past"},
		{"id": "item.support_beam", "name": "Deck Beam", "category": "component", "location": "town.construction_site", "offset": Vector3(3.0, 0.2, -4.0), "required_timeline": "past"},
		{"id": "item.pump_capacitor", "name": "Pump Capacitor", "category": "component", "location": "town.workshop", "offset": Vector3(4.8, 0.2, -4.0), "required_timeline": "past"},
	]
	for item_data in source_items:
		if AdventureState.item_is_held_or_spent(str(item_data["id"])) or _is_item_dropped(str(item_data["id"])):
			continue
		var position: Vector3 = TOWN_LOCATIONS.LOCATIONS[item_data["location"]] + item_data["offset"]
		_spawn_world_item(item_data, position)
	for dropped_item in AdventureState.get_dropped_items():
		var coordinates: Array = dropped_item.get("position", [0.0, 0.0, 0.0])
		var item_data := {
			"id": str(dropped_item.get("id", "")),
			"name": str(dropped_item.get("name", "Dropped item")),
			"category": str(dropped_item.get("category", "tool")),
			"location": str(dropped_item.get("source", "world")),
			"offset": Vector3.ZERO,
		}
		_spawn_world_item(
			item_data,
			Vector3(float(coordinates[0]), float(coordinates[1]), float(coordinates[2]))
		)


func _spawn_world_item(item_data: Dictionary, item_position: Vector3) -> void:
	var item := Area3D.new()
	item.name = str(item_data.get("id", "WorldItem")).replace(".", "_")
	item.set_script(INTERACTABLE_SCRIPT)
	item.set("interaction_id", str(item_data.get("id", "")))
	item.set("display_name", str(item_data.get("name", "Item")))
	item.set("interaction_description", "A useful item found in Willowbrook.")
	item.set("interaction_kind", "pickup")
	item.set("required_timeline", str(item_data.get("required_timeline", "")))
	item.set("persistent_item_id", str(item_data.get("id", "")))
	item.set("item_name", str(item_data.get("name", "Item")))
	item.set("item_category", str(item_data.get("category", "tool")))
	item.set("interaction_radius", 2.3)
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.15
	collision.shape = sphere
	item.add_child(collision)
	var pickup := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.65, 0.2, 0.28)
	pickup.mesh = mesh
	pickup.position.y = 0.55
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#d0a855") if str(item_data.get("category", "")) == "tool" else Color("#78b5c3")
	material.metallic = 0.35
	pickup.material_override = material
	item.add_child(pickup)
	var marker := Label3D.new()
	marker.text = str(item_data.get("name", "ITEM")).to_upper()
	marker.position.y = 1.15
	marker.font_size = 24
	marker.pixel_size = 0.007
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.modulate = Color("#e6d6ad")
	marker.outline_size = 4
	marker.outline_modulate = Color("#15222a")
	item.add_child(marker)
	item.position = item_position
	_world_root.add_child(item)


func _spawn_controls() -> void:
	if not AdventureState.has_world_flag("drainage.valve_open"):
		var tunnel: Vector3 = TOWN_LOCATIONS.LOCATIONS["drainage.tunnel_entrance"]
		_spawn_toggle(
			"water.level.lower", "Lower Inlet",
			tunnel + Vector3(-3.2, 0, 0),
			"Set the lower inlet first, following the future flood marks.",
			"item.wrench"
		)
		_spawn_toggle(
			"water.level.bypass", "Bypass Channel",
			tunnel + Vector3(0, 0, 4.0),
			"Open the bypass only after the lower inlet.",
			"item.wrench"
		)
		_spawn_toggle(
			"water.level.release", "Relief Release",
			tunnel + Vector3(3.2, 0, 0),
			"Open the relief release last to lower the future street water.",
			"item.wrench"
		)
	var panel := TOWN_LOCATIONS.LOCATIONS["town.electrical_station"] + Vector3(0, 0, -6.0)
	for index in range(ELECTRICAL_SEQUENCE.size()):
		var connection_id: String = ELECTRICAL_SEQUENCE[index]
		_spawn_puzzle_target(
			connection_id,
			"Connection %d" % (index + 1),
			"Route the cable through the matching station terminal.",
			panel + Vector3((float(index) - 1.0) * 1.6, 0.0, 0.0),
			"past",
			"electrical_connection",
			"item.copper_cable"
		)


func _spawn_puzzle_interactables() -> void:
	var construction_site: Vector3 = TOWN_LOCATIONS.LOCATIONS["town.construction_site"]
	_spawn_puzzle_target(
		"cement.surface", "Wet Cement Slab",
		"Leave a freehand message in the unfinished shelter foundation.",
		construction_site + Vector3(-5.0, 0.0, 2.0),
		"past", "cement_draw"
	)
	var capsule_position: Vector3 = TOWN_LOCATIONS.LOCATIONS["town.workshop"] + Vector3(-3.0, 0.0, 4.0)
	_spawn_puzzle_target(
		"capsule.pump", "Waterproof Time Capsule",
		"Place the identified pump capacitor inside, or retrieve it from 2046.",
		capsule_position, "", "pump_capsule"
	)
	var music_station: Vector3 = TOWN_LOCATIONS.LOCATIONS["town.general_store"] + Vector3(-3.0, 0.0, -3.0)
	for note_index in range(4):
		var note_id := "music.note.%d" % note_index
		_spawn_puzzle_target(
			note_id, ["C", "E", "G", "A"][note_index],
			"Strike this bell to record its tone in the past.",
			music_station + Vector3((float(note_index) - 1.5) * 1.15, 0.0, 0.0),
			"past", "music_note"
		)
	_spawn_puzzle_target(
		"music.clear", "New Recording",
		"Clear the old score before recording a new sequence.",
		music_station + Vector3(0.0, 0.0, 2.0),
		"past", "music_clear"
	)
	_spawn_puzzle_target(
		"music.playback", "Historical Recorder",
		"Replay the exact sequence preserved in the 2026 bell recording.",
		music_station + Vector3(0.0, 0.0, -2.0),
		"future", "music_playback"
	)


func _spawn_puzzle_target(
	interaction_id: String,
	label_text: String,
	description: String,
	location: Vector3,
	required_timeline: String,
	action: String,
	required_item_id: String = ""
) -> void:
	var target := Area3D.new()
	target.name = interaction_id.replace(".", "_")
	target.set_script(INTERACTABLE_SCRIPT)
	target.set("interaction_id", interaction_id)
	target.set("display_name", label_text)
	target.set("interaction_description", description)
	target.set("interaction_kind", "puzzle")
	target.set("mission_action", action)
	target.set("required_timeline", required_timeline)
	target.set("required_item_id", required_item_id)
	target.set("interaction_radius", 2.6)
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.3
	collision.shape = sphere
	target.add_child(collision)
	var marker := Label3D.new()
	marker.text = label_text.to_upper()
	marker.position.y = 1.25
	marker.font_size = 20
	marker.pixel_size = 0.007
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.modulate = Color("#f0c77d") if required_timeline == "future" else Color("#80dce5")
	marker.outline_size = 4
	marker.outline_modulate = Color("#172128")
	marker.visible = required_timeline.is_empty() or required_timeline == _timeline_role
	marker.visibility_range_end = 24.0
	target.add_child(marker)
	if action in ["music_note", "electrical_connection"]:
		var mesh_instance := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.28
		mesh.bottom_radius = 0.38
		mesh.height = 0.58
		mesh.radial_segments = 8
		mesh_instance.mesh = mesh
		mesh_instance.position.y = 0.28
		var colors: Array[Color] = [Color("#5fcde0"), Color("#e7b369"), Color("#f0eee3")]
		mesh_instance.material_override = _make_material(
			Color("#62cfdb") if action == "music_note" else colors[
				ELECTRICAL_SEQUENCE.find(interaction_id)
			]
		)
		target.add_child(mesh_instance)
	target.position = location
	_world_root.add_child(target)


func _spawn_mission_interactables() -> void:
	_spawn_mission_point(
		"echo.past.arrival", "Town Square", "Inspect the town square and its flood notice.",
		TOWN_LOCATIONS.LOCATIONS["town.square"] + Vector3(0, 0, 4), "past"
	)
	_spawn_mission_point(
		"echo.future.arrival", "Flooded Archive", "Inspect the archive's water-damaged records.",
		TOWN_LOCATIONS.LOCATIONS["town.archives"] + Vector3(4, 0, 4), "future"
	)
	_spawn_mission_point(
		"photo.future.discover", "Historical Photograph", "A photograph shows a blocked maintenance route beside the dam.",
		TOWN_LOCATIONS.LOCATIONS["town.archives"] + Vector3(5, 0, 0), "future", "", "show_photo"
	)
	_spawn_mission_point(
		"photo.past.crate", "Move Dam Crate", "Move the crate away from the service passage.",
		TOWN_LOCATIONS.LOCATIONS["river.dam"] + Vector3(5, 0, -4), "past", "", "refresh_environment"
	)
	_spawn_mission_point(
		"photo.past.barrier", "Clear Service Barrier", "Clear the barrier from the maintenance access.",
		TOWN_LOCATIONS.LOCATIONS["river.dam"] + Vector3(5, 0, 4), "past", "", "refresh_environment"
	)
	_spawn_mission_point(
		"photo.future.access", "Maintenance Access", "The passage is now clear. Record the newly revealed access.",
		TOWN_LOCATIONS.LOCATIONS["river.dam"] + Vector3(5, 0, 0), "future"
	)
	_spawn_mission_point(
		"room.future.discover", "Blocked Workshop Room", "A wall conceals a room that does not appear on the 2046 floor plan.",
		TOWN_LOCATIONS.LOCATIONS["town.workshop"] + Vector3(6, 0, 12), "future"
	)
	_spawn_mission_point(
		"room.past.revise", "Workshop Construction Plan", "Move the original wall module to create the missing doorway.",
		TOWN_LOCATIONS.LOCATIONS["town.workshop"] + Vector3(5, 0, 12), "past", "", "refresh_environment"
	)
	_spawn_mission_point(
		"room.future.enter", "Hidden Room Entrance", "Enter the room revealed by the 2026 layout change.",
		TOWN_LOCATIONS.LOCATIONS["town.workshop"] + Vector3(6, 0, 8), "future"
	)
	_spawn_mission_point(
		"room.future.document", "Construction Record", "Recover the record left inside the hidden room.",
		TOWN_LOCATIONS.LOCATIONS["town.workshop"] + Vector3(7, 0, 8), "future"
	)
	_spawn_mission_point(
		"machine.future.inspect", "Damaged Pump", "Inspect the missing capacitor socket and its faded color label.",
		TOWN_LOCATIONS.LOCATIONS["town.electrical_station"] + Vector3(-3, 0, 0), "future"
	)
	_spawn_mission_point(
		"machine.past.identify", "Complete Pump Layout", "Compare the pump's original component arrangement.",
		TOWN_LOCATIONS.LOCATIONS["town.electrical_station"] + Vector3(-3, 0, 0), "past"
	)
	_spawn_mission_point(
		"machine.past.capsule", "Time Capsule", "Place the identified capacitor in the sealed capsule.",
		TOWN_LOCATIONS.LOCATIONS["town.workshop"] + Vector3(-3, 0, 4), "past", "item.pump_capacitor", "refresh_environment"
	)
	_spawn_mission_point(
		"machine.future.retrieve", "Time Capsule Delivery", "Retrieve the capacitor delivered from 2026.",
		TOWN_LOCATIONS.LOCATIONS["town.workshop"] + Vector3(-3, 0, 4), "future", "", "retrieve_capacitor"
	)
	_spawn_mission_point(
		"machine.future.repair", "Pump Capacitor Socket", "Install the recovered component in the empty socket.",
		TOWN_LOCATIONS.LOCATIONS["town.electrical_station"] + Vector3(-3, 0, 2), "future", "item.pump_capacitor_future", "refresh_environment"
	)
	_spawn_mission_point(
		"town.past.preserve_supplies", "Willowbrook Shopkeeper", "Discuss moving the emergency supplies above the flood line.",
		TOWN_LOCATIONS.LOCATIONS["town.general_store"] + Vector3(5, 0, 3), "past", "", "shopkeeper_dialogue"
	)
	_spawn_mission_point(
		"town.future.retrieve_supplies", "Preserved Supplies", "Recover the crates kept safe in the upper storeroom.",
		TOWN_LOCATIONS.LOCATIONS["town.general_store"] + Vector3(5, 0, 3), "future", "", "refresh_environment"
	)
	_spawn_mission_point(
		"blueprint.future.request", "Shelter Blueprint Request",
		"Share the plan for a raised footbridge to the shelter site.",
		TOWN_LOCATIONS.LOCATIONS["town.electrical_station"] + Vector3(5, 0, 3), "future", "", "share_blueprint"
	)
	_spawn_mission_point(
		"blueprint.past.left", "Left Footbridge Support", "Fit the first timber into the left support.",
		TOWN_LOCATIONS.LOCATIONS["town.shelter_site"] + Vector3(-2, 0, 2), "past", "item.plank_left", "refresh_environment"
	)
	_spawn_mission_point(
		"blueprint.past.right", "Right Footbridge Support", "Fit the second timber into the right support.",
		TOWN_LOCATIONS.LOCATIONS["town.shelter_site"], "past", "item.plank_right", "refresh_environment"
	)
	_spawn_mission_point(
		"blueprint.past.deck", "Footbridge Deck", "Secure the deck beam across the supports.",
		TOWN_LOCATIONS.LOCATIONS["town.shelter_site"] + Vector3(2, 0, -2), "past", "item.support_beam", "refresh_environment"
	)
	_spawn_mission_point(
		"blueprint.future.traverse", "Shelter Footbridge", "Cross the completed footbridge to verify the route.",
		TOWN_LOCATIONS.LOCATIONS["town.shelter_site"] + Vector3(5, 0, -5), "future"
	)
	_spawn_mission_point(
		"power.future.pattern", "Emergency Light Pattern", "Read the station's repeating emergency-light sequence.",
		TOWN_LOCATIONS.LOCATIONS["town.electrical_station"] + Vector3(0, 0, -6), "future"
	)
	_spawn_mission_point(
		"power.future.restore", "Restored Power Station", "Confirm the emergency lights return in the flooded station.",
		TOWN_LOCATIONS.LOCATIONS["town.electrical_station"] + Vector3(0, 0, -8), "future"
	)
	_spawn_mission_point(
		"drainage.future.survey", "Flooded Drainage Tunnel",
		"Flood marks show the safe sequence: lower inlet, bypass channel, then relief release.",
		TOWN_LOCATIONS.LOCATIONS["drainage.tunnel_entrance"] + Vector3(0, 0, 3), "future"
	)
	_spawn_mission_point(
		"drainage.future.control", "Lower Control Room", "Check the lower control room after the water recedes.",
		TOWN_LOCATIONS.LOCATIONS["drainage.tunnel_entrance"] + Vector3(0, 0, 8), "future"
	)
	_spawn_mission_point(
		"flood.future.inspect", "Floodgate Evidence", "Inspect the damaged controls and document the failure pattern.",
		TOWN_LOCATIONS.LOCATIONS["river.dam"] + Vector3(5, 0, 8), "future"
	)
	_spawn_mission_point(
		"flood.past.configure", "Floodgate Controls", "Use the maintenance key to configure the floodgate.",
		TOWN_LOCATIONS.LOCATIONS["river.dam"] + Vector3(5, 0, -8), "past", "item.maintenance_key", "configure_floodgate"
	)
	_spawn_mission_point(
		"flood.future.confirm", "Changed Flood Outcome", "Inspect the spillway and confirm the safer future.",
		TOWN_LOCATIONS.LOCATIONS["river.dam"] + Vector3(6, 0, 0), "future"
	)


func _spawn_mission_point(
	objective_id: String,
	label_text: String,
	description: String,
	location: Vector3,
	required_timeline: String,
	required_item_id: String = "",
	action: String = ""
) -> void:
	var point := Area3D.new()
	point.name = objective_id.replace(".", "_")
	point.set_script(INTERACTABLE_SCRIPT)
	point.set("interaction_id", objective_id)
	point.set("display_name", label_text)
	point.set("interaction_description", description)
	point.set("interaction_kind", "mission")
	point.set("mission_objective_id", objective_id)
	point.set("mission_action", action)
	point.set("required_timeline", required_timeline)
	point.set("required_item_id", required_item_id)
	point.set("interaction_radius", 3.2)
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.0
	collision.shape = sphere
	point.add_child(collision)
	var marker := Label3D.new()
	marker.text = label_text.to_upper()
	marker.position.y = 1.8
	marker.font_size = 22
	marker.pixel_size = 0.007
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.modulate = Color("#f0c77d") if required_timeline == "future" else Color("#80dce5")
	marker.outline_size = 4
	marker.outline_modulate = Color("#172128")
	marker.visible = required_timeline.is_empty() or required_timeline == _timeline_role
	marker.visibility_range_end = 26.0
	point.add_child(marker)
	if objective_id.begins_with("blueprint.past."):
		var snap_preview := MeshInstance3D.new()
		snap_preview.name = "Translucent Material Snap Preview"
		var preview_mesh := BoxMesh.new()
		preview_mesh.size = Vector3(2.2, 0.16, 1.4)
		snap_preview.mesh = preview_mesh
		snap_preview.position.y = 0.15
		var preview_material := StandardMaterial3D.new()
		preview_material.albedo_color = Color("#64d5df", 0.32)
		preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		preview_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		snap_preview.material_override = preview_material
		point.add_child(snap_preview)
	point.position = location
	point.add_to_group("mission_point")
	_world_root.add_child(point)


func _spawn_toggle(
	flag_id: String,
	label_text: String,
	location: Vector3,
	description: String,
	required_item_id: String
) -> void:
	var control := Area3D.new()
	control.name = flag_id.replace(".", "_")
	control.set_script(INTERACTABLE_SCRIPT)
	control.set("interaction_id", flag_id)
	control.set("display_name", label_text)
	control.set("interaction_description", description)
	control.set("interaction_kind", "toggle")
	control.set("interaction_radius", 3.5)
	control.set("required_item_id", required_item_id)
	control.set("required_timeline", "past")
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.75
	collision.shape = sphere
	control.add_child(collision)
	var base := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.45
	cylinder.bottom_radius = 0.55
	cylinder.height = 0.9
	base.mesh = cylinder
	base.position.y = 0.45
	base.material_override = _make_material(Color("#505e62"))
	control.add_child(base)
	var lever := MeshInstance3D.new()
	var beam := BoxMesh.new()
	beam.size = Vector3(0.12, 0.9, 0.12)
	lever.mesh = beam
	lever.position = Vector3(0, 1.0, 0)
	lever.material_override = _make_material(Color("#ceae70"))
	control.add_child(lever)
	var marker := Label3D.new()
	marker.text = label_text.to_upper()
	marker.position.y = 1.8
	marker.font_size = 22
	marker.pixel_size = 0.007
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.modulate = Color("#f0c77d")
	marker.outline_size = 4
	marker.outline_modulate = Color("#172128")
	control.add_child(marker)
	control.position = location
	_world_root.add_child(control)


func _connect_signals() -> void:
	_hud.call("set_ability_status", TemporalEnergy.energy, {}, 0.0)
	_hud.connect("modal_closed", _on_modal_closed)
	_hud.connect("inventory_action", _on_inventory_action)
	_hud.connect("chat_send_requested", _on_chat_send)
	_hud.connect("marker_requested", _on_marker_requested)
	_hud.connect("dialogue_choice_requested", _on_dialogue_choice_requested)
	_hud.connect("cement_message_save_requested", _on_cement_message_save_requested)
	_hud.connect("photo_requested", _on_photo_requested)
	_hud.connect("pause_action", _on_pause_action)
	TemporalEnergy.ability_state_changed.connect(_on_ability_state_changed)
	TemporalEnergy.ability_ended.connect(_on_ability_ended)
	NetworkSession.remote_player_moved.connect(_on_remote_player_moved)
	NetworkSession.chat_received.connect(_on_chat_received)
	NetworkSession.marker_received.connect(_on_marker_received)
	NetworkSession.journal_received.connect(_on_journal_received)
	NetworkSession.world_flag_received.connect(_on_world_flag_received)
	NetworkSession.puzzle_state_received.connect(_on_puzzle_state_received)
	MissionSystem.objective_completed.connect(_on_mission_objective_completed)
	MissionSystem.mission_completed.connect(_on_mission_completed)
	MissionSystem.mission_changed.connect(_on_mission_changed)
	NetworkSession.connection_changed.connect(_on_network_connection_changed)
	NetworkSession.connection_failed.connect(func(message: String) -> void: _hud.call("show_notice", message))
	_update_mission_marker_visibility()


func _start_message() -> String:
	if _network_mode:
		return "LAN room · %s timeline · Share the host's IP and UDP port %d." % [
			_timeline_role.capitalize(), NetworkSession.DEFAULT_PORT
		]
	return "Local demonstration · F4 switches timelines · no partner is simulated."


func _on_interact_requested() -> void:
	if _hud.call("is_modal_open"):
		return
	var target := _nearest_interactable()
	if target == null:
		_hud.call("show_notice", "Nothing nearby to interact with.")
		return
	var kind := str(target.get("interaction_kind"))
	var required_timeline := str(target.get("required_timeline"))
	if not required_timeline.is_empty() and required_timeline != _timeline_role:
		_hud.call("show_notice", "This interaction belongs to the %s timeline." % required_timeline.capitalize())
		return
	if kind == "toggle" and _timeline_role != "past":
		_hud.call("show_notice", "Only the 2026 Past Player can change historical machinery.")
		return
	var required_item_id := str(target.get("required_item_id"))
	if kind in ["toggle", "mission", "puzzle"] and not required_item_id.is_empty() and not _has_selected_item(required_item_id):
		_hud.call("show_notice", "Equip the required tool or component before operating this control.")
		return
	if kind == "mission":
		_complete_mission_interaction(target)
		return
	if kind == "puzzle":
		_perform_puzzle_interaction(target)
		return
	var interaction_id := str(target.get("interaction_id"))
	if kind == "toggle" and WATER_LEVEL_SEQUENCE.has(interaction_id):
		_operate_water_level_control(interaction_id)
		return
	var message := str(target.call("perform_interaction"))
	_hud.call("show_notice", message)
	if kind == "toggle":
		var flag_id := str(target.get("interaction_id"))
		var value := AdventureState.has_world_flag(flag_id)
		if _shared_repository != null:
			if not bool(_shared_repository.call(
				"publish_event", {"type": "world_flag", "id": flag_id, "value": value}
			)):
				_hud.call("show_notice", "%s Local change saved; shared sync is unavailable." % message)
		_refresh_town_environment()
	elif kind == "inspect" and _shared_repository != null:
		var published := bool(_shared_repository.call(
			"publish_event",
			{
				"type": "journal",
				"id": str(target.get("interaction_id")),
				"text": str(target.get("interaction_description")),
			}
		))
		if not published:
			_hud.call("show_notice", "%s Discovery saved locally; partner sync is unavailable." % message)
	if kind == "pickup":
		var picked_item_id := str(target.get("persistent_item_id"))
		if picked_item_id == "item.time_echo_device":
			_player.call("set_time_echo_device_owned", true)
		_select_slot(mini(_selected_slot, AdventureState.get_state().get("inventory", []).size() - 1))
	_update_interaction_prompt()


func _publish_puzzle_state(update_type: String, payload: Dictionary) -> void:
	if not _network_mode or _shared_repository == null:
		return
	if not bool(_shared_repository.call("publish_event", {
		"type": "puzzle_state",
		"update_type": update_type,
		"payload": payload
	})):
		_hud.call("show_notice", "Puzzle saved locally; the partner could not be updated.")


func _operate_water_level_control(interaction_id: String) -> void:
	if AdventureState.has_world_flag("drainage.valve_open"):
		_hud.call("show_notice", "The drainage route is already stabilized.")
		return
	if not MissionSystem.is_objective_active("drainage.past.valve", _timeline_role):
		_hud.call("show_notice", "The future player must first survey the tunnel flood marks.")
		return
	var sequence_index := 0
	for flag_id in WATER_LEVEL_SEQUENCE:
		if not AdventureState.has_world_flag(flag_id):
			break
		sequence_index += 1
	if sequence_index >= WATER_LEVEL_SEQUENCE.size():
		_hud.call("show_notice", "The valve sequence is set; the mission record is syncing.")
		return
	if interaction_id != WATER_LEVEL_SEQUENCE[sequence_index]:
		_hud.call("show_notice", "Follow the flood marks: lower inlet, bypass channel, then relief release.")
		return
	if not AdventureState.set_world_flag(interaction_id, true, true):
		_hud.call("show_notice", AdventureState.last_error)
		return
	if _shared_repository != null and not bool(_shared_repository.call(
		"publish_event", {"type": "world_flag", "id": interaction_id, "value": true}
	)):
		_hud.call("show_notice", "Valve state saved locally; the partner could not be updated.")
	sequence_index += 1
	if sequence_index == WATER_LEVEL_SEQUENCE.size():
		if not MissionSystem.complete_objective("drainage.past.valve", _timeline_role):
			_hud.call("show_notice", MissionSystem.last_error)
			return
		_hud.call("show_notice", "Water level stabilized. The floodwater recedes in 2046.")
	else:
		_hud.call("show_notice", "Valve sequence %d of %d set." % [
			sequence_index, WATER_LEVEL_SEQUENCE.size()
		])
	_refresh_town_environment()


func _perform_puzzle_interaction(target: Area3D) -> void:
	var action := str(target.get("mission_action"))
	var interaction_id := str(target.get("interaction_id"))
	match action:
		"cement_draw":
			_set_modal_input()
			_hud.call("show_cement_canvas")
		"pump_capsule":
			_operate_pump_capsule()
		"electrical_connection":
			_operate_electrical_connection(interaction_id)
		"music_note":
			var note_index := int(interaction_id.get_slice(".", 2))
			if AdventureState.append_musical_note(note_index):
				_play_musical_sequence([note_index])
				_publish_puzzle_state("music_sequence", {
					"id": "willowbrook-sequence",
					"notes": AdventureState.get_musical_sequence()
				})
				_hud.call("show_notice", "Bell recorded · %d notes saved." % AdventureState.get_musical_sequence().size())
			else:
				_hud.call("show_notice", AdventureState.last_error)
		"music_clear":
			if AdventureState.clear_musical_sequence():
				_publish_puzzle_state("music_sequence", {
					"id": "willowbrook-sequence",
					"notes": []
				})
				_hud.call("show_notice", "The old musical recording was cleared.")
			else:
				_hud.call("show_notice", AdventureState.last_error)
		"music_playback":
			var notes := AdventureState.get_musical_sequence()
			if notes.is_empty():
				_hud.call("show_notice", "No historical musical recording has been preserved.")
				return
			_play_musical_sequence(notes)
			_hud.call("show_notice", "Playing the exact %d-note recording from 2026." % notes.size())


func _operate_pump_capsule() -> void:
	if _timeline_role == "past":
		if not MissionSystem.is_objective_active("machine.past.capsule", _timeline_role):
			_hud.call("show_notice", "Identify the pump in both timelines before sealing its component.")
			return
		if not _has_selected_item("item.pump_capacitor"):
			_hud.call("show_notice", "Select the original Pump Capacitor before burying the capsule.")
			return
		var capsule_position: Vector3 = TOWN_LOCATIONS.LOCATIONS["town.workshop"] + Vector3(-3.0, 0.0, 4.0)
		if not AdventureState.bury_item_in_capsule("capsule.pump", "item.pump_capacitor", capsule_position):
			_hud.call("show_notice", AdventureState.last_error)
			return
		if not MissionSystem.complete_objective("machine.past.capsule", _timeline_role):
			_hud.call("show_notice", MissionSystem.last_error)
			return
		var capsules: Array = AdventureState.state.get("time_capsules", [])
		if not capsules.is_empty():
			_publish_puzzle_state("capsule", capsules.back())
		_hud.call("show_notice", "The unique pump capacitor is sealed in the buried waterproof capsule.")
	else:
		if not MissionSystem.is_objective_active("machine.future.retrieve", _timeline_role):
			_hud.call("show_notice", "There is no capsule delivery ready to recover here yet.")
			return
		var recovered: Dictionary = AdventureState.retrieve_time_capsule("capsule.pump")
		if recovered.is_empty():
			_hud.call("show_notice", AdventureState.last_error)
			return
		if not MissionSystem.complete_objective("machine.future.retrieve", _timeline_role):
			_hud.call("show_notice", MissionSystem.last_error)
			return
		for capsule in AdventureState.state.get("time_capsules", []):
			if str(capsule.get("id", "")) == "capsule.pump":
				_publish_puzzle_state("capsule", capsule)
				break
		_hud.call("show_notice", "Recovered the original %s from the time capsule." % recovered.get("name", "component"))
	if _shared_repository != null:
		_shared_repository.call("publish_event", {
			"type": "world_flag",
			"id": "capsule.capacitor_sent" if _timeline_role == "past" else "capsule.capacitor_retrieved",
			"value": true
		})
	_refresh_town_environment()


func _operate_electrical_connection(interaction_id: String) -> void:
	if AdventureState.has_world_flag("electrical.power_routed"):
		_hud.call("show_notice", "The station circuit is already restored.")
		return
	if not MissionSystem.is_objective_active("power.past.route", _timeline_role):
		_hud.call("show_notice", "Read the emergency-light pattern in the future first.")
		return
	var sequence_index := 0
	for connection_id in ELECTRICAL_SEQUENCE:
		if not AdventureState.has_world_flag(connection_id):
			break
		sequence_index += 1
	if sequence_index >= ELECTRICAL_SEQUENCE.size():
		_hud.call("show_notice", "All terminals are connected; the power route is syncing.")
		return
	if interaction_id != ELECTRICAL_SEQUENCE[sequence_index]:
		_hud.call("show_notice", "Follow the future pattern: cyan, amber, then white.")
		return
	if not AdventureState.set_world_flag(interaction_id, true):
		_hud.call("show_notice", AdventureState.last_error)
		return
	if _shared_repository != null and not bool(_shared_repository.call(
		"publish_event", {"type": "world_flag", "id": interaction_id, "value": true}
	)):
		_hud.call("show_notice", "Terminal saved locally; the partner could not be updated.")
	sequence_index += 1
	if sequence_index == ELECTRICAL_SEQUENCE.size():
		if not MissionSystem.complete_objective("power.past.route", _timeline_role):
			_hud.call("show_notice", MissionSystem.last_error)
			return
		_hud.call("show_notice", "The three cable connections restore the station circuit.")
	else:
		_hud.call("show_notice", "Electrical connection %d of %d set." % [
			sequence_index, ELECTRICAL_SEQUENCE.size()
		])
	_refresh_town_environment()


func _play_musical_sequence(notes: Array) -> void:
	var sample_rate := 22050
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = true
	var data := PackedByteArray()
	var frequencies := [261.63, 329.63, 392.0, 440.0]
	for note in notes:
		var frequency: float = frequencies[int(note)]
		var sample_count := int(sample_rate * 0.22)
		for sample_index in range(sample_count):
			var envelope := minf(1.0, float(sample_index) / 240.0)
			var value := int(sin(TAU * frequency * float(sample_index) / float(sample_rate)) * 7000.0 * envelope)
			var unsigned_value := value & 0xffff
			data.append(unsigned_value & 0xff)
			data.append((unsigned_value >> 8) & 0xff)
			data.append(unsigned_value & 0xff)
			data.append((unsigned_value >> 8) & 0xff)
		for _silence in range(int(sample_rate * 0.06)):
			data.append(0)
			data.append(0)
			data.append(0)
			data.append(0)
	stream.data = data
	var player := AudioStreamPlayer3D.new()
	player.name = "HistoricalSequencePlayback"
	player.stream = stream
	player.position = TOWN_LOCATIONS.LOCATIONS["town.general_store"] + Vector3(-3.0, 1.0, -3.0)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _on_cement_message_save_requested(strokes: Array) -> void:
	if _timeline_role != "past":
		_hud.call("show_notice", "Only the 2026 timeline can mark wet cement.")
		return
	if not AdventureState.save_cement_message(strokes):
		_hud.call("show_notice", AdventureState.last_error)
		return
	var saved_messages: Array = AdventureState.state.get("cement_messages", [])
	if not saved_messages.is_empty():
		_publish_puzzle_state("cement_message", saved_messages.back())
	var message_number: int = AdventureState.state.get("cement_messages", []).size()
	AdventureState.add_journal_entry(
		"cement.message.%d" % message_number,
		"A freehand mark was preserved on the shelter foundation for the future timeline."
	)
	_hud.call("show_notice", "Your exact freehand strokes are preserved in the future cement.")
	_refresh_town_environment()


func _rewind_timeline_action() -> void:
	if _timeline_role != "past":
		_hud.call("show_notice", "Only the 2026 Past Player can rewind a shared environmental action.")
		return
	if not AdventureState.rewind_last_timeline_action():
		_hud.call("show_notice", AdventureState.last_error)
		return
	var events: Array = AdventureState.state.get("event_history", [])
	var latest: Dictionary = events.back() if not events.is_empty() else {}
	var payload: Dictionary = latest.get("payload", {})
	var flag_id := str(payload.get("flag_id", ""))
	if _shared_repository != null and not flag_id.is_empty():
		_shared_repository.call("publish_event", {"type": "world_flag", "id": flag_id, "value": false})
	_hud.call("show_notice", "The last safe water-control change was rewound.")
	_refresh_town_environment()


func _complete_mission_interaction(target: Area3D) -> void:
	var objective_id := str(target.get("mission_objective_id"))
	if not MissionSystem.is_objective_active(objective_id, _timeline_role):
		_hud.call("show_notice", "That mission step is not available yet.")
		return
	if str(target.get("mission_action")) == "shopkeeper_dialogue":
		_set_modal_input()
		_hud.call(
			"show_npc_dialogue",
			"Willowbrook Shopkeeper",
			"The river has been rising earlier each season. I can move the emergency food and blankets to the upper storeroom if the town agrees."
		)
		return
	var description := str(target.get("interaction_description"))
	if not MissionSystem.complete_objective(objective_id, _timeline_role):
		_hud.call("show_notice", MissionSystem.last_error)
		return
	AdventureState.add_journal_entry(objective_id, description)
	if _shared_repository != null:
		_shared_repository.call("publish_event", {
			"type": "journal", "id": objective_id, "text": description
		})
	var action := str(target.get("mission_action"))
	if action == "refresh_environment" or action == "configure_floodgate":
		_refresh_town_environment()
	if action == "share_blueprint":
		_hud.call("show_notice", "Blueprint request recorded in the shared mission log.")
		if NetworkSession.is_connected_to_partner() and not NetworkSession.send_chat(
			"Blueprint request: assemble the elevated footbridge at the shelter site."
		):
			_hud.call("show_notice", NetworkSession.last_error)
	if action == "show_photo":
		_set_modal_input()
		_hud.call("show_historical_photo", TOWN_SCENE)
	else:
		_hud.call("show_notice", description)
	if not str(target.get("required_item_id")).is_empty():
		_select_slot(mini(_selected_slot, AdventureState.get_state().get("inventory", []).size() - 1))
	_update_interaction_prompt()


func _nearest_interactable() -> Area3D:
	var nearest: Area3D
	var nearest_distance := INF
	for node in get_tree().get_nodes_in_group("adventure_interactable"):
		if not is_instance_valid(node) or not node is Area3D:
			continue
		var required_timeline := str(node.get("required_timeline"))
		if not required_timeline.is_empty() and required_timeline != _timeline_role:
			continue
		var objective_id := str(node.get("mission_objective_id"))
		if not objective_id.is_empty() and not MissionSystem.is_objective_active(objective_id, _timeline_role):
			continue
		var distance := _player.global_position.distance_to(node.global_position)
		if distance <= float(node.get("interaction_radius")) and distance < nearest_distance:
			nearest = node
			nearest_distance = distance
	return nearest


func _update_interaction_prompt() -> void:
	if _hud.call("is_modal_open"):
		_hud.call("set_interaction_prompt", "")
		return
	var target := _nearest_interactable()
	if target == null:
		_hud.call("set_interaction_prompt", "")
		return
	var prompt := "E  ·  %s" % str(target.get("display_name"))
	if str(target.get("interaction_kind")) == "pickup":
		prompt = "E  ·  Pick up %s" % str(target.get("item_name"))
	_hud.call("set_interaction_prompt", prompt)


func _on_utility_requested(utility_id: String) -> void:
	match utility_id:
		"inventory":
			_open_inventory()
		"map":
			_open_map()
		"journal":
			_open_journal()
		"echo_link":
			_open_echo_link()
		"temporal_flashlight":
			_toggle_temporal_flashlight()
		"rewind":
			_rewind_timeline_action()
		"switch_timeline":
			_switch_local_timeline()


func _on_ability_requested(ability_id: String) -> void:
	if ability_id == "time_echo":
		_toggle_time_echo()
	elif ability_id == "temporal_vision":
		_toggle_temporal_vision()


func _open_inventory() -> void:
	_set_modal_input()
	var inventory: Array = AdventureState.get_state().get("inventory", [])
	_hud.call("show_inventory", inventory, _selected_slot)


func _open_map() -> void:
	_set_modal_input()
	_hud.call(
		"show_map",
		TOWN_LOCATIONS.LOCATIONS,
		AdventureState.get_state().get("markers", []),
		NetworkSession.is_connected_to_partner(),
		_player.global_position,
		_remote_transform.origin,
		_remote_state_available
	)


func _open_journal() -> void:
	_set_modal_input()
	var mission_progress: Dictionary = MissionSystem.get_progress()
	_hud.call("show_journal", AdventureState.get_state().get("journal", []), {
		"mission": MissionSystem.get_current_mission(),
		"objectives": MissionSystem.get_current_objectives(),
		"photo_available": mission_progress.get("objectives", {}).has("photo.future.discover")
	})


func _open_echo_link() -> void:
	_set_modal_input()
	_hud.call(
		"show_echo_link",
		AdventureState.get_state().get("messages", []),
		NetworkSession.is_connected_to_partner()
	)


func _set_modal_input() -> void:
	if _player != null:
		_player.call("set_mouse_captured", false)


func _on_modal_closed() -> void:
	if _player != null:
		_player.call("set_mouse_captured", true)
		_hud.call("set_mouse_captured", true)


func _on_pause_requested() -> void:
	if _hud.call("is_modal_open"):
		_hud.call("close_current_modal")
		return
	_set_modal_input()
	_hud.call("show_pause_menu")


func _on_pause_action(action: String) -> void:
	if action == "save":
		_save_checkpoint()
		_hud.call("show_notice", "Adventure checkpoint saved.")
	elif action == "menu":
		_save_checkpoint()
		if _network_mode:
			NetworkSession.leave_room()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_inventory_action(action: String, item_id: String) -> void:
	var inventory: Array = AdventureState.get_state().get("inventory", [])
	if action == "select":
		_select_slot(int(item_id))
		_open_inventory()
	elif action == "use":
		if _selected_slot < 0 or _selected_slot >= inventory.size():
			_hud.call("show_notice", "Select an item first.")
			return
		_hud.call("show_notice", "%s equipped. Use E near compatible machinery." % str(inventory[_selected_slot].get("name", "Item")))
		_hud.call("close_current_modal")
	elif action == "drop":
		_drop_selected_item()
		_open_inventory()


func _select_slot(slot_index: int) -> void:
	var inventory: Array = AdventureState.get_state().get("inventory", [])
	if slot_index < 0 or slot_index >= inventory.size():
		_selected_slot = -1
		_player.call("set_equipped_item", "")
		return
	_selected_slot = slot_index
	_player.call("set_equipped_item", str(inventory[slot_index].get("id", "")))
	_hud.call("show_notice", "Selected %s." % str(inventory[slot_index].get("name", "item")))


func _has_selected_item(item_id: String) -> bool:
	var inventory: Array = AdventureState.get_state().get("inventory", [])
	return (
		_selected_slot >= 0
		and _selected_slot < inventory.size()
		and str(inventory[_selected_slot].get("id", "")) == item_id
	)


func _drop_selected_item() -> void:
	var inventory: Array = AdventureState.get_state().get("inventory", [])
	if _selected_slot < 0 or _selected_slot >= inventory.size():
		_hud.call("show_notice", "Select an item to drop.")
		return
	var item_data: Dictionary = inventory[_selected_slot]
	var item_id := str(item_data.get("id", ""))
	if item_id == "item.time_echo_device":
		if TemporalEnergy.is_active("time_echo"):
			TemporalEnergy.deactivate("time_echo", "device dropped")
		if TemporalEnergy.is_active("temporal_vision"):
			TemporalEnergy.deactivate("temporal_vision", "device dropped")
	var drop_position := _player.global_position + (-_player.global_basis.z * 1.5)
	drop_position.y = 0.2
	var dropped := AdventureState.drop_inventory_item(item_id, drop_position)
	if dropped.is_empty():
		_hud.call("show_notice", AdventureState.last_error)
		return
	_selected_slot = -1
	_player.call("set_equipped_item", "")
	if item_id == "item.time_echo_device":
		_player.call("set_time_echo_device_owned", false)
	_spawn_world_item(dropped, drop_position)
	_hud.call("show_notice", "%s dropped." % str(dropped.get("name", item_id)))


func _on_chat_send(text: String) -> void:
	if not NetworkSession.send_chat(text):
		_hud.call("show_notice", NetworkSession.last_error)
		return
	if MissionSystem.is_objective_active("echo.link", _timeline_role):
		MissionSystem.complete_objective("echo.link", _timeline_role)


func _on_photo_requested() -> void:
	_set_modal_input()
	_hud.call("show_historical_photo", TOWN_SCENE)


func _on_dialogue_choice_requested(choice_id: String) -> void:
	var moved_supplies := choice_id == "relocate_supplies"
	if not moved_supplies and choice_id != "leave_supplies":
		_hud.call("show_notice", "The shopkeeper did not recognize that choice.")
		return
	if not MissionSystem.is_objective_active("town.past.preserve_supplies", _timeline_role):
		return
	var outcome_flag := "npc.supplies_relocated" if moved_supplies else "npc.supplies_declined"
	if not MissionSystem.complete_objective_with_flag(
		"town.past.preserve_supplies", _timeline_role, outcome_flag
	):
		_hud.call("show_notice", MissionSystem.last_error)
		return
	var outcome_text := (
		"The shopkeeper moved emergency food and blankets to the upper storeroom."
		if moved_supplies
		else "The supplies were left below the flood line and were lost to the flood."
	)
	AdventureState.add_journal_entry(
		"town.past.preserve_supplies",
		outcome_text
	)
	if _shared_repository != null:
		_shared_repository.call("publish_event", {
			"type": "world_flag",
			"id": outcome_flag,
			"value": true
		})
		_shared_repository.call("publish_event", {
			"type": "journal",
			"id": "town.past.preserve_supplies",
			"text": outcome_text
		})
	_refresh_town_environment()
	_hud.call("show_notice", outcome_text)


func _on_chat_received(peer_id: int, text: String, sent_at: int) -> void:
	var sender_id := _timeline_role if peer_id == multiplayer.get_unique_id() else ("future" if _timeline_role == "past" else "past")
	AdventureState.add_message(sender_id, text)
	if _hud.call("is_modal_open"):
		_open_echo_link()


func _on_marker_requested(location_id: String, label: String) -> void:
	if NetworkSession.is_connected_to_partner():
		var success := bool(_shared_repository.call(
			"publish_event", {"type": "marker", "location_id": location_id, "label": label}
		)) if _shared_repository != null else NetworkSession.send_marker(location_id, label)
		if not success:
			_hud.call("show_notice", NetworkSession.last_error)
	else:
		AdventureState.add_location_marker(location_id, label, _timeline_role)
		_hud.call("show_notice", "Local marker placed at %s." % location_id.replace(".", " "))
	_open_map()


func _on_journal_received(peer_id: int, entry_id: String, text: String) -> void:
	var sender_id := _timeline_role if peer_id == multiplayer.get_unique_id() else ("future" if _timeline_role == "past" else "past")
	AdventureState.add_journal_entry(entry_id, "%s: %s" % [sender_id.capitalize(), text])
	if _hud.call("is_modal_open"):
		_open_journal()


func _on_marker_received(peer_id: int, location_id: String, label: String) -> void:
	var sender_id := _timeline_role if peer_id == multiplayer.get_unique_id() else ("future" if _timeline_role == "past" else "past")
	AdventureState.add_location_marker(location_id, label, sender_id)
	_hud.call("show_notice", "Shared marker received: %s." % location_id.replace(".", " "))
	if _hud.call("is_modal_open"):
		_open_map()


func _on_world_flag_received(_peer_id: int, flag_id: String, value: bool) -> void:
	if AdventureState.has_world_flag(flag_id) != value:
		AdventureState.set_world_flag(flag_id, value)
		_refresh_town_environment()


func _on_puzzle_state_received(update_type: String, _payload: Dictionary) -> void:
	if update_type in ["capsule", "cement_message"]:
		_refresh_town_environment()


func _on_remote_player_moved(peer_id: int, transform: Transform3D, moving: bool, selected_item: String) -> void:
	if peer_id == multiplayer.get_unique_id():
		return
	_remote_transform = transform
	_remote_state_available = true
	_remote_moving = moving
	_remote_selected_item = selected_item
	if _remote_avatar == null or not is_instance_valid(_remote_avatar):
		_remote_avatar = PLAYER_SCENE.instantiate() as CharacterBody3D
		_remote_avatar.name = "RemotePartner"
		var remote_role := "future" if _timeline_role == "past" else "past"
		_remote_avatar.set_meta("network_remote", true)
		_remote_avatar.set_meta("timeline_role", remote_role)
		_world_root.add_child(_remote_avatar)
		_remote_avatar.call("set_spectral_mode", TemporalEnergy.is_active("time_echo"), remote_role)
		_remote_avatar.visible = TemporalEnergy.is_active("time_echo")
	_remote_avatar.call("update_remote_state", transform, moving, selected_item)
	_update_temporal_partner_projection()


func _toggle_time_echo() -> void:
	if TemporalEnergy.is_active("time_echo"):
		TemporalEnergy.deactivate("time_echo")
		return
	if not _has_item("item.time_echo_device"):
		_hud.call("show_notice", "Equip the Time Echo device before activation.")
		return
	var source_timeline := "future" if _timeline_role == "past" else "past"
	var live_partner := NetworkSession.is_connected_to_partner() and _remote_state_available
	_recorded_echo_frames = AdventureState.get_recorded_echo(source_timeline)
	if not live_partner and _recorded_echo_frames.is_empty():
		_hud.call("show_notice", "Time Echo unavailable: no live partner or recorded echo is available.")
		return
	if not TemporalEnergy.activate("time_echo", live_partner or not _recorded_echo_frames.is_empty()):
		_hud.call("show_notice", "Temporal energy is below the activation threshold.")
		return
	_recorded_echo_active = not live_partner
	if MissionSystem.is_objective_active("echo.time_echo", _timeline_role):
		MissionSystem.complete_objective("echo.time_echo", _timeline_role)
	if live_partner and _remote_avatar != null:
		_remote_avatar.visible = true
		_remote_avatar.call("set_spectral_mode", true, source_timeline)
	elif _recorded_echo_active:
		_spawn_recorded_echo(source_timeline)
	_hud.call(
		"show_notice",
		"Time Echo active — live partner." if live_partner else "Historical recording — actual saved partner movements."
	)
	_update_temporal_partner_projection()


func _toggle_temporal_vision() -> void:
	if TemporalEnergy.is_active("temporal_vision"):
		TemporalEnergy.deactivate("temporal_vision")
		return
	if not _has_item("item.time_echo_device"):
		_hud.call("show_notice", "Equip the Time Echo device before activation.")
		return
	if not TemporalEnergy.activate("temporal_vision"):
		_hud.call("show_notice", "Temporal energy is below the activation threshold.")
		return


func _on_ability_state_changed(energy: float, active: Dictionary, seconds_left: float) -> void:
	_hud.call("set_ability_status", energy, active, seconds_left)
	var echo_active := bool(active.get("time_echo", false))
	if echo_active != _last_time_echo_active:
		_last_time_echo_active = echo_active
		if _remote_avatar != null:
			_remote_avatar.visible = echo_active
			_remote_avatar.call(
				"set_spectral_mode", echo_active, "future" if _timeline_role == "past" else "past"
			)
	var vision_active := bool(active.get("temporal_vision", false))
	if vision_active != _displayed_vision_active:
		_displayed_vision_active = vision_active
		_hud.call("set_temporal_vision_active", vision_active)
		if vision_active:
			var vision_objective := "echo.%s.vision" % _timeline_role
			if MissionSystem.is_objective_active(vision_objective, _timeline_role):
				MissionSystem.complete_objective(vision_objective, _timeline_role)
	if _player != null:
		_player.call("set_time_echo_device_active", echo_active or vision_active)
	_update_temporal_partner_projection()


func _on_mission_objective_completed(objective_id: String, role: String, source: String) -> void:
	_update_mission_marker_visibility()
	if source == "remote" and objective_id in [
		"photo.past.crate",
		"photo.past.barrier",
		"room.past.revise",
		"machine.past.capsule",
		"machine.future.repair",
		"town.past.preserve_supplies",
		"town.future.retrieve_supplies",
		"blueprint.past.left",
		"blueprint.past.right",
		"blueprint.past.deck",
		"power.past.route",
		"drainage.past.valve",
		"flood.past.configure"
	]:
		_refresh_town_environment()
	_hud.call("refresh_historical_photo")
	if _network_mode and source != "remote" and _shared_repository != null:
		if not bool(_shared_repository.call("publish_event", {"type": "mission", "id": objective_id})):
			_hud.call("show_notice", "Objective saved locally; the partner could not be updated.")
	if objective_id == "echo.time_echo":
		_hud.call("show_notice", "Time Echo training objective completed.")
	elif objective_id != "echo.link":
		_hud.call("show_notice", "Objective completed (%s): %s" % [role, objective_id.replace(".", " ").capitalize()])


func _on_mission_completed(mission_id: String, title: String) -> void:
	if str(MissionSystem.get_progress().get("active_mission", "")).is_empty():
		_hud.call("show_notice", "Mission complete: %s." % title)
		get_tree().create_timer(1.2).timeout.connect(_show_adventure_ending)
	else:
		_hud.call("show_notice", "%s complete. Next: %s." % [
			title, str(MissionSystem.get_current_mission().get("title", "Next mission"))
		])


func _on_mission_changed(_mission_id: String) -> void:
	_update_mission_marker_visibility()
	_refresh_town_environment()


func _update_mission_marker_visibility() -> void:
	for node in get_tree().get_nodes_in_group("mission_point"):
		if not is_instance_valid(node):
			continue
		var timeline := str(node.get("required_timeline"))
		var objective_id := str(node.get("mission_objective_id"))
		var marker := node.get_child(1) as Label3D if node.get_child_count() > 1 else null
		var objective_available: bool = (
			(timeline.is_empty() or timeline == _timeline_role)
			and MissionSystem.is_objective_active(objective_id, _timeline_role)
		)
		if marker != null:
			marker.visible = objective_available
		var snap_preview := node.get_node_or_null("Translucent Material Snap Preview") as MeshInstance3D
		if snap_preview != null:
			snap_preview.visible = objective_available
	for node in get_tree().get_nodes_in_group("adventure_interactable"):
		if not is_instance_valid(node) or str(node.get("interaction_kind")) != "puzzle":
			continue
		var timeline := str(node.get("required_timeline"))
		node.visible = timeline.is_empty() or timeline == _timeline_role


func _show_adventure_ending() -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scenes/ui/adventure_ending.tscn")


func _update_temporal_partner_projection() -> void:
	var echo_active := TemporalEnergy.is_active("time_echo")
	var vision_active := TemporalEnergy.is_active("temporal_vision")
	var source_timeline := "future" if _timeline_role == "past" else "past"
	var projection_visible := (
		(echo_active and (_remote_state_available or _recorded_echo_active))
		or (vision_active and _remote_state_available)
	)
	_hud.call(
		"set_temporal_partner_state",
		projection_visible,
		_remote_transform,
		_remote_moving,
		source_timeline,
		_remote_selected_item
	)


func _spawn_recorded_echo(source_timeline: String) -> void:
	if _recorded_echo_frames.is_empty():
		return
	var first_frame: Dictionary = _recorded_echo_frames[0]
	_remote_transform = _transform_from_echo_frame(first_frame)
	_remote_moving = bool(first_frame.get("moving", false))
	_remote_selected_item = str(first_frame.get("selected_item", ""))
	_recorded_frame_index = 0
	_recorded_frame_timer = 0.0
	if _remote_avatar == null or not is_instance_valid(_remote_avatar):
		_remote_avatar = PLAYER_SCENE.instantiate() as CharacterBody3D
		_remote_avatar.name = "RecordedPartnerEcho"
		_remote_avatar.set_meta("network_remote", true)
		_remote_avatar.set_meta("timeline_role", source_timeline)
		_world_root.add_child(_remote_avatar)
	_remote_avatar.call("set_spectral_mode", true, source_timeline)
	_remote_avatar.call("update_remote_state", _remote_transform, _remote_moving, _remote_selected_item)
	_remote_avatar.visible = true


func _update_recorded_echo(delta: float) -> void:
	if not _recorded_echo_active or not TemporalEnergy.is_active("time_echo"):
		return
	if _recorded_echo_frames.size() < 2:
		return
	_recorded_frame_timer += delta
	if _recorded_frame_timer < 0.8:
		return
	_recorded_frame_timer = 0.0
	_recorded_frame_index = mini(_recorded_frame_index + 1, _recorded_echo_frames.size() - 1)
	var frame: Dictionary = _recorded_echo_frames[_recorded_frame_index]
	_remote_transform = _transform_from_echo_frame(frame)
	_remote_moving = bool(frame.get("moving", false))
	_remote_selected_item = str(frame.get("selected_item", ""))
	if _remote_avatar != null:
		_remote_avatar.call("update_remote_state", _remote_transform, _remote_moving, _remote_selected_item)
	_update_temporal_partner_projection()


func _record_partner_movement(delta: float) -> void:
	if not NetworkSession.is_connected_to_partner() or not _remote_state_available:
		return
	_recording_timer += delta
	if _recording_timer < 1.0:
		return
	_recording_timer = 0.0
	var source_timeline := "future" if _timeline_role == "past" else "past"
	AdventureState.record_echo_frame(
		source_timeline, _remote_transform, _remote_moving, _remote_selected_item
	)


func _transform_from_echo_frame(frame: Dictionary) -> Transform3D:
	var position_data: Array = frame.get("position", [0.0, 0.0, 0.0])
	return Transform3D(
		Basis(Vector3.UP, float(frame.get("yaw", 0.0))),
		Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
	)


func _on_network_connection_changed(connected: bool) -> void:
	if not connected and TemporalEnergy.is_active("time_echo"):
		TemporalEnergy.deactivate("time_echo", "partner disconnected")
	_remote_state_available = false if not connected else _remote_state_available
	if not connected and _network_mode:
		_hud.call("show_notice", "Partner disconnected. Live Time Echo is unavailable.")


func _on_ability_ended(ability_id: String, reason: String) -> void:
	_hud.call("show_notice", "%s ended: %s." % [
		"Time Echo" if ability_id == "time_echo" else "Temporal Vision", reason
	])
	AdventureState.set_temporal_energy(TemporalEnergy.energy)
	if ability_id == "time_echo":
		_recorded_echo_active = false
		_update_temporal_partner_projection()


func _toggle_temporal_flashlight() -> void:
	if _timeline_role != "future":
		_hud.call("show_notice", "The Temporal Flashlight is available in 2046.")
		return
	_temporal_flashlight_active = not _temporal_flashlight_active
	if _temporal_flashlight_active:
		_flashlight = SpotLight3D.new()
		_flashlight.name = "TemporalFlashlight"
		_flashlight.light_color = Color("#91e6f4")
		_flashlight.light_energy = 2.4
		_flashlight.spot_range = 18.0
		_flashlight.spot_angle = 33.0
		_flashlight.shadow_enabled = false
		_player.get_node("CameraPivot/SpringArm3D/Camera3D").add_child(_flashlight)
		_flashlight.position = Vector3(0, 0, -0.5)
		_hud.call("show_notice", "Temporal Flashlight active — aim at damaged structures.")
	else:
		if _flashlight != null:
			_flashlight.queue_free()
			_flashlight = null
		_hide_all_historic_reveals()
		_hud.call("show_notice", "Temporal Flashlight off.")


func _update_flashlight_target() -> void:
	var camera: Camera3D = _player.get_node("CameraPivot/SpringArm3D/Camera3D")
	var origin := camera.global_position
	var destination := origin + (-camera.global_basis.z * 20.0)
	var query := PhysicsRayQueryParameters3D.create(origin, destination, 1)
	var result := _player.get_world_3d().direct_space_state.intersect_ray(query)
	var target_id := ""
	if not result.is_empty():
		var target_position: Vector3 = result["position"]
		for node in get_tree().get_nodes_in_group("temporal_inspectable"):
			if not _town_environment.is_ancestor_of(node):
				continue
			if node.global_position.distance_to(target_position) < 9.0:
				node.call("set_historic_reveal", true)
				target_id = str(node.get_instance_id())
			elif node.has_method("set_historic_reveal"):
				node.call("set_historic_reveal", false)
	if target_id.is_empty() and result.is_empty():
		_hide_all_historic_reveals()


func _hide_all_historic_reveals() -> void:
	for node in get_tree().get_nodes_in_group("temporal_inspectable"):
		if _town_environment.is_ancestor_of(node) and node.has_method("set_historic_reveal"):
			node.call("set_historic_reveal", false)


func _switch_local_timeline() -> void:
	if _network_mode:
		_hud.call("show_notice", "Timeline roles are fixed while connected to a co-op room.")
		return
	if _hud.call("is_modal_open"):
		_hud.call("close_current_modal")
	if TemporalEnergy.is_active("time_echo"):
		TemporalEnergy.deactivate("time_echo", "timeline switched")
	if TemporalEnergy.is_active("temporal_vision"):
		TemporalEnergy.deactivate("temporal_vision", "timeline switched")
	var next_role := "future" if _timeline_role == "past" else "past"
	AdventureState.set_player_checkpoint(_player.global_position, _player.get_node("CameraPivot").rotation.y)
	_timeline_role = next_role
	_player.set_meta("timeline_role", _timeline_role)
	AdventureState.set_timeline(_timeline_role)
	_refresh_town_environment()
	_update_timeline_ui()
	_update_mission_marker_visibility()
	_hud.call(
		"setup_temporal_view",
		TOWN_SCENE,
		2026 if _timeline_role == "future" else 2046,
		_player.get_node("CameraPivot/SpringArm3D/Camera3D")
	)
	_hud.call("show_notice", "Local demonstration switched to %s." % _timeline_role.capitalize())


func _refresh_town_environment() -> void:
	if _town_environment != null and is_instance_valid(_town_environment):
		_world_root.remove_child(_town_environment)
		_town_environment.queue_free()
	_spawn_town()
	_hud.call(
		"setup_temporal_view",
		TOWN_SCENE,
		2046 if _timeline_role == "past" else 2026,
		_player.get_node("CameraPivot/SpringArm3D/Camera3D")
	)


func _update_timeline_ui() -> void:
	_hud.call("set_timeline", 2046 if _timeline_role == "future" else 2026, _timeline_role)


func _is_item_dropped(item_id: String) -> bool:
	for item in AdventureState.get_dropped_items():
		if str(item.get("id", "")) == item_id:
			return true
	return false


func _has_item(item_id: String) -> bool:
	for item in AdventureState.get_state().get("inventory", []):
		if str(item.get("id", "")) == item_id:
			return true
	return false


func _save_checkpoint() -> void:
	if not is_instance_valid(_player):
		return
	var checkpoint_position := _player.global_position if _player.is_inside_tree() else _player.position
	AdventureState.set_player_checkpoint(checkpoint_position, _player.get_node("CameraPivot").rotation.y)
	AdventureState.state["temporal_energy"] = TemporalEnergy.energy
	AdventureState.save_state()


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	return material
