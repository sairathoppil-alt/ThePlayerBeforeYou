extends Node

const REPOSITORY_SCRIPT = preload("res://scripts/core/local_json_repository.gd")
const TOWN_SCENE: PackedScene = preload("res://scenes/world/town_environment.tscn")
const ADVENTURE_SCENE: PackedScene = preload("res://scenes/world/adventure_world.tscn")
const TEST_SAVE_PATH := "user://mission_system_smoke.json"

var _saved_state: Dictionary
var _saved_repository: RefCounted
var _saved_event_serial := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_saved_state = AdventureState.state.duplicate(true)
	_saved_repository = AdventureState._repository
	_saved_event_serial = AdventureState._event_serial
	AdventureState._repository = REPOSITORY_SCRIPT.new(TEST_SAVE_PATH)
	AdventureState.state = AdventureState._default_state()
	if not await _test_progression():
		_restore_and_quit(1)
		return
	if not _test_schema_migration():
		_restore_and_quit(1)
		return
	if not await _test_historical_photo_view():
		_restore_and_quit(1)
		return
	if not await _test_musical_playback():
		_restore_and_quit(1)
		return
	if not _test_shared_world_flags():
		_restore_and_quit(1)
		return
	_restore_and_quit(0)


func _test_progression() -> bool:
	if not MissionSystem.is_objective_active("echo.past.arrival", "past"):
		return _fail_test("Past tutorial objective should be initially active.")
	if MissionSystem.complete_objective("echo.future.vision", "future"):
		return _fail_test("A role-specific objective must not bypass its prerequisites.")
	for objective in [
		["echo.past.arrival", "past"],
		["echo.past.vision", "past"],
		["echo.future.arrival", "future"],
		["echo.future.vision", "future"],
		["photo.future.discover", "future"],
		["photo.past.crate", "past"],
		["photo.past.barrier", "past"],
		["photo.future.access", "future"],
		["room.future.discover", "future"],
	]:
		if not MissionSystem.complete_objective(objective[0], objective[1]):
			return _fail_test("Could not complete objective %s: %s" % [objective[0], MissionSystem.last_error])
	if not await _test_lost_room_geometry():
		return false
	if not AdventureState.has_world_flag("photo.crate_moved") or not AdventureState.has_world_flag("room.wall_moved"):
		return _fail_test("Persistent mission world flags were not recorded.")
	if not MissionSystem.complete_objective("room.future.document", "future"):
		return _fail_test("The hidden room document objective failed.")
	if not _inventory_has("item.room_document"):
		return _fail_test("The hidden room reward item was not granted.")
	for objective in [
		["machine.future.inspect", "future"],
		["machine.past.identify", "past"],
	]:
		if not MissionSystem.complete_objective(objective[0], objective[1]):
			return _fail_test("Could not complete objective %s." % objective[0])
	if not AdventureState.add_inventory_item({
		"id": "item.pump_capacitor",
		"name": "Pump Capacitor",
		"category": "component",
		"source": "smoke_test"
	}):
		return _fail_test("Could not prepare the capsule test item.")
	if not AdventureState.bury_item_in_capsule(
		"capsule.pump", "item.pump_capacitor", Vector3(31.0, 0.0, -38.0)
	):
		return _fail_test("The pump capacitor was not physically stored in the capsule.")
	if _inventory_has("item.pump_capacitor"):
		return _fail_test("Burying the capacitor left a duplicate in inventory.")
	if not MissionSystem.complete_objective("machine.past.capsule", "past"):
		return _fail_test("The capsule transfer objective failed.")
	var recovered_item: Dictionary = AdventureState.retrieve_time_capsule("capsule.pump")
	if str(recovered_item.get("id", "")) != "item.pump_capacitor":
		return _fail_test("Capsule retrieval did not preserve the original unique item ID.")
	if not MissionSystem.complete_objective("machine.future.retrieve", "future"):
		return _fail_test("The physical capsule retrieval objective failed.")
	if not MissionSystem.complete_objective("machine.future.repair", "future"):
		return _fail_test("The pump repair objective failed.")
	if not AdventureState.has_world_flag("machine.repaired"):
		return _fail_test("The repaired machine flag was not saved.")
	if not MissionSystem.complete_objective_with_flag(
		"town.past.preserve_supplies", "past", "npc.supplies_relocated"
	):
		return _fail_test("The shopkeeper choice objective failed.")
	if not MissionSystem.complete_objective("town.future.retrieve_supplies", "future"):
		return _fail_test("The preserved supplies objective failed.")
	if not await _test_blueprint_assembly():
		return false
	if not MissionSystem.complete_objective("power.future.pattern", "future"):
		return _fail_test("The future emergency-light pattern objective failed.")
	if not await _test_electrical_sequence():
		return false
	for objective in [
		["power.future.restore", "future"],
		["drainage.future.survey", "future"],
	]:
		if not MissionSystem.complete_objective(objective[0], objective[1]):
			return _fail_test("Could not complete objective %s: %s" % [objective[0], MissionSystem.last_error])
	if not await _test_water_level_sequence():
		return false
	for objective in [
		["drainage.future.control", "future"],
		["flood.future.inspect", "future"],
	]:
		if not MissionSystem.complete_objective(objective[0], objective[1]):
			return _fail_test("Could not complete objective %s: %s" % [objective[0], MissionSystem.last_error])
	if not AdventureState.add_inventory_item({
		"id": "item.maintenance_key",
		"name": "Maintenance Key",
		"category": "key",
		"source": "smoke_test"
	}):
		return _fail_test("Could not prepare the floodgate test item.")
	if not MissionSystem.complete_objective("flood.past.configure", "past"):
		return _fail_test("The floodgate configuration objective failed.")
	if not MissionSystem.complete_objective("flood.future.confirm", "future"):
		return _fail_test("The final objective failed.")
	var progress: Dictionary = MissionSystem.get_progress()
	if not str(progress.get("active_mission", "")).is_empty():
		return _fail_test("The final mission did not close the chapter.")
	if str(progress.get("final_outcome", "")) != "prevented":
		return _fail_test("The completed chapter did not record its outcome.")
	if not AdventureState.save_cement_message([[[0.1, 0.2], [0.7, 0.8]]]):
		return _fail_test("A normalized freehand cement message was not saved.")
	var stored_messages: Array = AdventureState.state.get("cement_messages", [])
	if stored_messages.size() != 1 or stored_messages[0].get("strokes", []).size() != 1:
		return _fail_test("The saved freehand cement strokes were not preserved.")
	for note in [0, 3, 1]:
		if not AdventureState.append_musical_note(note):
			return _fail_test("A valid musical note could not be recorded.")
	if AdventureState.get_musical_sequence() != [0, 3, 1]:
		return _fail_test("The persistent musical sequence changed its note order.")
	return true


func _test_electrical_sequence() -> bool:
	var adventure := ADVENTURE_SCENE.instantiate()
	add_child(adventure)
	await get_tree().process_frame
	adventure.call("_operate_electrical_connection", "electrical.route.amber")
	if AdventureState.has_world_flag("electrical.route.amber"):
		adventure.queue_free()
		return _fail_test("The electrical panel accepted an out-of-order connection.")
	for connection_id in [
		"electrical.route.cyan",
		"electrical.route.amber",
		"electrical.route.white"
	]:
		adventure.call("_operate_electrical_connection", connection_id)
		if not AdventureState.has_world_flag(connection_id):
			adventure.queue_free()
			return _fail_test("The electrical connection %s did not persist." % connection_id)
	if not AdventureState.has_world_flag("electrical.power_routed"):
		adventure.queue_free()
		return _fail_test("The completed electrical sequence did not restore station power.")
	adventure.queue_free()
	await get_tree().process_frame
	return true


func _test_blueprint_assembly() -> bool:
	if not MissionSystem.complete_objective("blueprint.future.request", "future"):
		return _fail_test("The future blueprint request could not be recorded.")
	for item_data in [
		{"id": "item.plank_left", "name": "Support Timber A", "category": "component"},
		{"id": "item.plank_right", "name": "Support Timber B", "category": "component"},
		{"id": "item.support_beam", "name": "Deck Beam", "category": "component"},
	]:
		if not AdventureState.add_inventory_item(item_data):
			return _fail_test("Could not collect all physical blueprint materials.")
	var adventure := ADVENTURE_SCENE.instantiate()
	add_child(adventure)
	await get_tree().process_frame
	for objective_id in ["blueprint.past.left", "blueprint.past.right", "blueprint.past.deck"]:
		var target: Area3D
		for node in get_tree().get_nodes_in_group("mission_point"):
			if str(node.get("mission_objective_id")) == objective_id:
				target = node as Area3D
				break
		if target == null:
			adventure.queue_free()
			return _fail_test("The physical snap location for %s was not spawned." % objective_id)
		adventure.call("_complete_mission_interaction", target)
		if not MissionSystem.get_progress().get("objectives", {}).has(objective_id):
			adventure.queue_free()
			return _fail_test("Placing the material at %s did not persist." % objective_id)
	if not AdventureState.rewind_last_timeline_action():
		adventure.queue_free()
		return _fail_test("The last blueprint placement could not be safely rewound.")
	if AdventureState.has_world_flag("blueprint.deck") or not _inventory_has("item.support_beam"):
		adventure.queue_free()
		return _fail_test("Rewinding the deck did not restore its material and snap point.")
	var deck_target: Area3D
	for node in get_tree().get_nodes_in_group("mission_point"):
		if str(node.get("mission_objective_id")) == "blueprint.past.deck":
			deck_target = node as Area3D
			break
	if deck_target == null:
		adventure.queue_free()
		return _fail_test("The reversible deck snap point disappeared after rewind.")
	adventure.call("_complete_mission_interaction", deck_target)
	if not AdventureState.has_world_flag("blueprint.deck"):
		adventure.queue_free()
		return _fail_test("The restored deck beam could not be placed again.")
	await get_tree().process_frame
	var town := adventure.get_node_or_null("WorldRoot/Willowbrook_2026")
	if town == null:
		adventure.queue_free()
		return _fail_test("The assembled bridge's 2026 environment was not refreshed.")
	var bridge_collisions: Array = town.find_children(
		"AssembledFootbridgeCollision_*", "StaticBody3D", true, false
	)
	if bridge_collisions.size() != 3:
		adventure.queue_free()
		return _fail_test(
			"The three placed materials created %d bridge collision pieces; saved flags: %s." % [
				bridge_collisions.size(), AdventureState.state.get("world_flags", {})
			]
		)
	if not MissionSystem.complete_objective("blueprint.future.traverse", "future"):
		adventure.queue_free()
		return _fail_test("The future route objective did not follow physical bridge assembly.")
	adventure.queue_free()
	await get_tree().process_frame
	return true


func _test_lost_room_geometry() -> bool:
	var original_room := TOWN_SCENE.instantiate()
	add_child(original_room)
	await get_tree().process_frame
	var blocked_wall := original_room.find_child("Blocking Wall Module Collision", true, false)
	if blocked_wall == null:
		original_room.queue_free()
		return _fail_test("The 2046 hidden-room blocking wall did not have real collision.")
	original_room.queue_free()
	await get_tree().process_frame
	if not MissionSystem.complete_objective("room.past.revise", "past"):
		return _fail_test("The past construction-layout revision failed.")
	var opened_room := TOWN_SCENE.instantiate()
	add_child(opened_room)
	await get_tree().process_frame
	if opened_room.find_child("Blocking Wall Module Collision", true, false) != null:
		opened_room.queue_free()
		return _fail_test("Changing the past layout did not remove the future wall collision.")
	if opened_room.find_child("Revealed Room Door Frame", true, false) == null:
		opened_room.queue_free()
		return _fail_test("The changed future room did not reveal its doorway geometry.")
	opened_room.queue_free()
	await get_tree().process_frame
	if not MissionSystem.complete_objective("room.future.enter", "future"):
		return _fail_test("The future room entry objective did not follow the physical doorway change.")
	return true


func _test_water_level_sequence() -> bool:
	var adventure := ADVENTURE_SCENE.instantiate()
	add_child(adventure)
	await get_tree().process_frame
	adventure.call("_operate_water_level_control", "water.level.bypass")
	if AdventureState.has_world_flag("water.level.bypass"):
		adventure.queue_free()
		return _fail_test("The bypass valve must not open before the lower inlet.")
	adventure.call("_operate_water_level_control", "water.level.lower")
	adventure.call("_operate_water_level_control", "water.level.bypass")
	if not AdventureState.rewind_last_timeline_action():
		adventure.queue_free()
		return _fail_test("The most recent safe drainage action could not be rewound.")
	if not AdventureState.has_world_flag("water.level.lower") \
	or AdventureState.has_world_flag("water.level.bypass"):
		adventure.queue_free()
		return _fail_test("Rewind did not preserve the earlier valve while undoing the later one.")
	for flag_id in ["water.level.bypass", "water.level.release"]:
		adventure.call("_operate_water_level_control", flag_id)
		if not AdventureState.has_world_flag(flag_id):
			adventure.queue_free()
			return _fail_test("The ordered water-level control %s was not persisted." % flag_id)
	if not MissionSystem.get_progress().get("objectives", {}).has("drainage.past.valve"):
		adventure.queue_free()
		return _fail_test("Completing all three water-level controls did not finish the valve objective.")
	if AdventureState.rewind_last_timeline_action():
		adventure.queue_free()
		return _fail_test("Rewind must not undo the completed drainage story consequence.")
	adventure.queue_free()
	await get_tree().process_frame
	return true


func _test_shared_world_flags() -> bool:
	if not AdventureState.set_world_flag("water.level.lower", true):
		return _fail_test("Could not seed the local water-level state.")
	if not AdventureState.set_world_flag("water.level.release", false):
		return _fail_test("Could not seed the boolean validation case.")
	if not AdventureState.merge_shared_snapshot({
		"world_flags": {
			"water.level.bypass": true,
			"unrecognized.flag": true,
			"water.level.release": "invalid"
		},
		"mission_progress": {},
		"journal": [],
		"markers": [],
		"messages": []
	}):
		return _fail_test("A valid shared world-state snapshot was rejected.")
	if not AdventureState.has_world_flag("water.level.lower") \
	or not AdventureState.has_world_flag("water.level.bypass"):
		return _fail_test("The shared snapshot did not preserve valid local and incoming water flags.")
	if AdventureState.has_world_flag("unrecognized.flag") \
	or AdventureState.has_world_flag("water.level.release"):
		return _fail_test("The shared snapshot accepted an unrecognized or non-boolean flag.")
	return true


func _test_schema_migration() -> bool:
	var old_state: Dictionary = AdventureState._default_state()
	old_state["schema_version"] = 2
	old_state.erase("mission_progress")
	var migrated: Variant = AdventureState._migrate_state(old_state)
	if typeof(migrated) != TYPE_DICTIONARY:
		return _fail_test("Schema v2 migration did not return an object.")
	if int(migrated.get("schema_version", -1)) != AdventureState.SCHEMA_VERSION:
		return _fail_test("Schema v2 migration did not advance the version.")
	if typeof(migrated.get("mission_progress")) != TYPE_DICTIONARY:
		return _fail_test("Schema v2 migration did not initialize mission progress.")
	return true


func _test_historical_photo_view() -> bool:
	var hud_scene := load("res://scenes/ui/adventure_hud.tscn") as PackedScene
	if hud_scene == null:
		return _fail_test("Could not load the adventure HUD scene.")
	var hud := hud_scene.instantiate() as CanvasLayer
	add_child(hud)
	hud.call("show_historical_photo", TOWN_SCENE)
	await get_tree().process_frame
	hud.call("refresh_historical_photo")
	hud.call("close_current_modal")
	hud.call("show_cement_canvas")
	await get_tree().process_frame
	var canvas := hud.find_child("CementDrawingCanvas", true, false)
	if canvas == null:
		hud.queue_free()
		return _fail_test("The in-world wet-cement drawing popup did not open.")
	canvas.size = Vector2(520, 300)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(52, 60)
	canvas.call("_gui_input", press)
	var motion := InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.position = Vector2(364, 240)
	canvas.call("_gui_input", motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = motion.position
	canvas.call("_gui_input", release)
	var strokes: Array = canvas.call("get_normalized_strokes")
	if strokes.size() != 1 or strokes[0].size() < 2:
		hud.queue_free()
		return _fail_test("The cement canvas did not preserve a freehand mouse stroke.")
	canvas.call("undo_last_stroke")
	if not canvas.call("get_normalized_strokes").is_empty():
		hud.queue_free()
		return _fail_test("The cement canvas Undo control did not remove the latest stroke.")
	hud.call("close_current_modal")
	hud.queue_free()
	await get_tree().process_frame
	return true


func _test_musical_playback() -> bool:
	var adventure := ADVENTURE_SCENE.instantiate()
	add_child(adventure)
	await get_tree().process_frame
	adventure.call("_play_musical_sequence", AdventureState.get_musical_sequence())
	var player := adventure.get_node_or_null("HistoricalSequencePlayback") as AudioStreamPlayer3D
	if player == null or not player.stream is AudioStreamWAV or player.stream.data.is_empty():
		adventure.queue_free()
		return _fail_test("The recorder did not generate playable audio for the saved sequence.")
	adventure.queue_free()
	await get_tree().process_frame
	return true


func _inventory_has(item_id: String) -> bool:
	for item in AdventureState.state.get("inventory", []):
		if str(item.get("id", "")) == item_id:
			return true
	return false


func _fail_test(message: String) -> bool:
	push_error(message)
	return false


func _restore_and_quit(exit_code: int) -> void:
	AdventureState.state = _saved_state
	AdventureState._repository = _saved_repository
	AdventureState._event_serial = _saved_event_serial
	var test_path := ProjectSettings.globalize_path(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(test_path)
	get_tree().quit(exit_code)
