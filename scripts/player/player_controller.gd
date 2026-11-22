extends CharacterBody3D

signal interact_requested
signal pause_requested
signal cursor_toggle_requested
signal ability_requested(ability_id: String)
signal utility_requested(utility_id: String)
signal drop_requested
signal slot_selected(slot: int)

const WALK_SPEED := 6.2
const SPRINT_SPEED := 9.0
const GRAVITY := 22.0
const DEFAULT_MOUSE_SENSITIVITY := 0.0026
const AVATAR_MATERIAL := Color("#b55d43")
const TROUSER_MATERIAL := Color("#3d4b52")
const SKIN_MATERIAL := Color("#e0ad83")
const SHOE_MATERIAL := Color("#443a34")
const TIME_ECHO_DEVICE_SCENE: PackedScene = preload("res://scenes/items/time_echo_device.tscn")

@onready var camera_pivot: Node3D = $CameraPivot
@onready var visuals: Node3D = $Visuals

var _gameplay_input_enabled := true
var _camera_pitch := -0.3
var _walk_clock := 0.0
var _mouse_sensitivity := DEFAULT_MOUSE_SENSITIVITY
var _is_remote_proxy := false
var _remote_moving := false
var _remote_target_transform := Transform3D.IDENTITY
var _remote_selected_item := ""
var _network_update_time := 0.0
var _leg_pivots: Array[Node3D] = []
var _arm_pivots: Array[Node3D] = []
var _outfit_color := AVATAR_MATERIAL
var _equipped_item_id := ""
var _time_echo_device: Node3D
var _tool_visual: Node3D


func _ready() -> void:
	add_to_group("player")
	_register_movement_actions()
	if has_meta("timeline_role"):
		_outfit_color = Color("#405f84") if str(get_meta("timeline_role")) == "future" else AVATAR_MATERIAL
	var settings: Dictionary = AdventureState.get_state().get("settings", {})
	_mouse_sensitivity = float(settings.get("mouse_sensitivity", DEFAULT_MOUSE_SENSITIVITY))
	_build_avatar()
	camera_pivot.rotation.x = _camera_pitch
	if bool(get_meta("network_remote", false)):
		set_remote_proxy(str(get_meta("timeline_role", "future")))
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if _is_remote_proxy:
		return
	var current_speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	if _gameplay_input_enabled:
		var movement := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var forward := -camera_pivot.global_basis.z
		forward.y = 0.0
		forward = forward.normalized()
		var right := camera_pivot.global_basis.x
		right.y = 0.0
		right = right.normalized()
		var direction := right * movement.x + forward * -movement.y
		if direction.length_squared() > 0.001:
			direction = direction.normalized()
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
			visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(-direction.x, -direction.z), delta * 11.0)
		else:
			velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 8.0 * delta)
		if is_on_floor() and Input.is_action_just_pressed("jump"):
			velocity.y = 7.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 10.0 * delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	move_and_slide()
	_animate_walking(delta)
	_publish_network_state(delta)


func _unhandled_input(event: InputEvent) -> void:
	if _is_remote_proxy:
		return
	if event.is_action_pressed("ui_cancel"):
		pause_requested.emit()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if not _gameplay_input_enabled:
			return
		match event.physical_keycode:
			KEY_E:
				interact_requested.emit()
			KEY_TAB:
				utility_requested.emit("inventory")
			KEY_M:
				utility_requested.emit("map")
			KEY_J:
				utility_requested.emit("journal")
			KEY_C:
				utility_requested.emit("echo_link")
			KEY_T:
				ability_requested.emit("time_echo")
			KEY_V:
				ability_requested.emit("temporal_vision")
			KEY_F:
				utility_requested.emit("temporal_flashlight")
			KEY_R:
				utility_requested.emit("rewind")
			KEY_Q:
				drop_requested.emit()
			KEY_F4:
				utility_requested.emit("switch_timeline")
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
				slot_selected.emit(event.physical_keycode - KEY_1)
			_:
				return
		get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and _gameplay_input_enabled:
		_rotate_camera(event.relative)


func set_gameplay_input_enabled(enabled: bool) -> void:
	_gameplay_input_enabled = enabled


func set_mouse_captured(captured: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE
	set_gameplay_input_enabled(captured)


func set_remote_proxy(source_timeline: String) -> void:
	_is_remote_proxy = true
	_gameplay_input_enabled = false
	collision_layer = 0
	collision_mask = 0
	camera_pivot.hide()
	camera_pivot.get_node("SpringArm3D/Camera3D").current = false
	_outfit_color = Color("#405f84") if source_timeline == "future" else Color("#b55d43")
	if visuals.get_child_count() == 0:
		_build_avatar()
	_remote_target_transform = global_transform


func update_remote_state(transform: Transform3D, moving: bool, selected_item: String) -> void:
	_remote_target_transform = transform
	_remote_moving = moving
	_remote_selected_item = selected_item
	set_equipped_item(selected_item)


func set_equipped_item(item_id: String) -> void:
	_equipped_item_id = item_id
	if _tool_visual == null:
		return
	_tool_visual.visible = not item_id.is_empty() and item_id != "item.time_echo_device"


func set_time_echo_device_active(value: bool) -> void:
	if _time_echo_device != null:
		_time_echo_device.call("set_active", value)


func set_time_echo_device_owned(value: bool) -> void:
	if _time_echo_device != null:
		if not value:
			_time_echo_device.call("set_active", false)
		_time_echo_device.visible = value


func set_spectral_mode(enabled: bool, source_timeline: String = "future") -> void:
	for node in visuals.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.material_override is not StandardMaterial3D:
			continue
		var material := (mesh_instance.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		if enabled:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_color.a = 0.4
			material.emission_enabled = true
			material.emission = Color("#71dff5") if source_timeline == "future" else Color("#ffc36f")
			material.emission_energy_multiplier = 0.4
		else:
			material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			material.albedo_color.a = 1.0
			material.emission_enabled = false
		mesh_instance.material_override = material


func _process(delta: float) -> void:
	if not _is_remote_proxy:
		return
	global_position = global_position.lerp(_remote_target_transform.origin, minf(1.0, delta * 12.0))
	var target_yaw := _remote_target_transform.basis.get_euler().y
	visuals.rotation.y = lerp_angle(visuals.rotation.y, target_yaw, minf(1.0, delta * 12.0))
	var gait_speed := 5.2 if _remote_moving else 0.0
	if _remote_moving:
		_walk_clock += delta * gait_speed
	else:
		_walk_clock = move_toward(_walk_clock, round(_walk_clock / TAU) * TAU, delta * 4.0)
	var swing := sin(_walk_clock) * 0.4
	for index in range(_leg_pivots.size()):
		_leg_pivots[index].rotation.x = swing if index == 0 else -swing
	for index in range(_arm_pivots.size()):
		_arm_pivots[index].rotation.x = -swing * 0.7 if index == 0 else swing * 0.7


func _publish_network_state(delta: float) -> void:
	if not NetworkSession.is_connected_to_partner() or not _gameplay_input_enabled:
		return
	_network_update_time += delta
	if _network_update_time < 0.1:
		return
	_network_update_time = 0.0
	var is_moving := Vector2(velocity.x, velocity.z).length() > 0.35
	NetworkSession.send_movement(
		Transform3D(Basis(Vector3.UP, visuals.rotation.y), global_position),
		is_moving,
		_equipped_item_id
	)


func _rotate_camera(mouse_delta: Vector2) -> void:
	camera_pivot.rotation.y -= mouse_delta.x * _mouse_sensitivity
	_camera_pitch = clampf(_camera_pitch - mouse_delta.y * _mouse_sensitivity, -0.95, 0.18)
	camera_pivot.rotation.x = _camera_pitch


func _register_movement_actions() -> void:
	_ensure_action("move_forward", [87, 4194320])
	_ensure_action("move_back", [83, 4194322])
	_ensure_action("move_left", [65, 4194319])
	_ensure_action("move_right", [68, 4194321])
	_ensure_action("jump", [32])
	_ensure_action("sprint", [4194325])


func _ensure_action(action_name: String, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for keycode in keycodes:
		var exists := false
		for event in InputMap.action_get_events(action_name):
			if event is InputEventKey and event.physical_keycode == keycode:
				exists = true
				break
		if not exists:
			var key_event := InputEventKey.new()
			key_event.physical_keycode = keycode
			InputMap.action_add_event(action_name, key_event)


func _build_avatar() -> void:
	_add_capsule(visuals, "Body", 0.35, 0.92, Vector3(0, 1.12, 0), _outfit_color)
	_add_capsule(visuals, "Neck", 0.12, 0.22, Vector3(0, 1.62, 0), SKIN_MATERIAL)
	_add_box(visuals, "Jacket front", Vector3(0.35, 0.62, 0.035), Vector3(0, 1.18, -0.335), _outfit_color.lightened(0.18))
	_add_box(visuals, "Backpack", Vector3(0.62, 0.78, 0.32), Vector3(0, 1.3, 0.42), Color("#624a38"))
	_add_box(visuals, "Backpack flap", Vector3(0.5, 0.25, 0.08), Vector3(0, 1.68, 0.6), Color("#8e6e4d"))
	for side in [-1.0, 1.0]:
		_add_box(
			visuals, "Backpack strap", Vector3(0.09, 0.82, 0.1),
			Vector3(0.24 * side, 1.35, 0.2), _outfit_color.darkened(0.25)
		)
	_add_sphere(visuals, "Head", 0.24, Vector3(0, 1.82, 0), SKIN_MATERIAL)
	var hair := MeshInstance3D.new()
	hair.name = "Hair"
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.245
	hair_mesh.height = 0.49
	hair_mesh.radial_segments = 8
	hair_mesh.rings = 4
	hair.mesh = hair_mesh
	hair.scale = Vector3(1.02, 0.52, 1.02)
	hair.position = Vector3(0, 1.98, 0)
	hair.material_override = _make_material(Color("#40332f"))
	visuals.add_child(hair)
	_add_sphere(visuals, "Left eye", 0.035, Vector3(-0.085, 1.84, -0.205), Color("#302a27"))
	_add_sphere(visuals, "Right eye", 0.035, Vector3(0.085, 1.84, -0.205), Color("#302a27"))
	_add_sphere(visuals, "Nose", 0.045, Vector3(0, 1.77, -0.235), SKIN_MATERIAL.darkened(0.06))
	_add_box(visuals, "Belt", Vector3(0.58, 0.16, 0.38), Vector3(0, 0.66, 0), _palette_color("#c79553"))

	for side in [-1, 1]:
		var leg_pivot := Node3D.new()
		leg_pivot.name = "LegPivot%d" % side
		leg_pivot.position = Vector3(0.16 * float(side), 0.68, 0)
		visuals.add_child(leg_pivot)
		_add_capsule(leg_pivot, "Leg", 0.14, 0.66, Vector3(0, -0.34, 0), TROUSER_MATERIAL)
		_add_box(leg_pivot, "Boot", Vector3(0.31, 0.18, 0.5), Vector3(0, -0.62, -0.07), SHOE_MATERIAL)
		_leg_pivots.append(leg_pivot)

		var arm_pivot := Node3D.new()
		arm_pivot.name = "ArmPivot%d" % side
		arm_pivot.position = Vector3(0.39 * float(side), 1.42, 0)
		visuals.add_child(arm_pivot)
		_add_capsule(arm_pivot, "Arm", 0.115, 0.65, Vector3(0, -0.32, 0), _outfit_color)
		_add_capsule(arm_pivot, "Hand", 0.09, 0.18, Vector3(0, -0.68, -0.015), SKIN_MATERIAL)
		_arm_pivots.append(arm_pivot)
	_time_echo_device = TIME_ECHO_DEVICE_SCENE.instantiate() as Node3D
	_time_echo_device.name = "EquippedTimeEchoDevice"
	_time_echo_device.position = Vector3(0, -0.73, -0.08)
	_arm_pivots[0].add_child(_time_echo_device)
	_tool_visual = Node3D.new()
	_tool_visual.name = "EquippedTool"
	_tool_visual.position = Vector3(0, -0.7, -0.12)
	_arm_pivots[1].add_child(_tool_visual)
	var tool_handle := MeshInstance3D.new()
	var handle_mesh := BoxMesh.new()
	handle_mesh.size = Vector3(0.1, 0.62, 0.1)
	tool_handle.mesh = handle_mesh
	tool_handle.material_override = _make_material(Color("#997348"))
	tool_handle.rotation.z = -0.2
	_tool_visual.add_child(tool_handle)
	var tool_head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.42, 0.13, 0.15)
	tool_head.mesh = head_mesh
	tool_head.position.y = 0.22
	tool_head.material_override = _make_material(Color("#84939a"))
	_tool_visual.add_child(tool_head)
	_tool_visual.visible = false


func _animate_walking(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.35 and is_on_floor() and _gameplay_input_enabled:
		_walk_clock += delta * 8.0
	else:
		_walk_clock = move_toward(_walk_clock, round(_walk_clock / TAU) * TAU, delta * 4.0)

	var swing := sin(_walk_clock) * minf(horizontal_speed / WALK_SPEED, 1.0) * 0.52
	var gait_amount := minf(horizontal_speed / WALK_SPEED, 1.0) if _gameplay_input_enabled else 0.0
	visuals.position.y = sin(_walk_clock * 2.0) * 0.035 * gait_amount
	for index in range(_leg_pivots.size()):
		_leg_pivots[index].rotation.x = swing if index == 0 else -swing
	for index in range(_arm_pivots.size()):
		_arm_pivots[index].rotation.x = -swing * 0.75 if index == 0 else swing * 0.75


func _add_capsule(
	parent: Node3D,
	mesh_name: String,
	radius: float,
	height: float,
	mesh_position: Vector3,
	color: Color
) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	capsule.radial_segments = 8
	instance.mesh = capsule
	instance.position = mesh_position
	instance.material_override = _make_material(color)
	parent.add_child(instance)


func _add_sphere(parent: Node3D, mesh_name: String, radius: float, mesh_position: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	instance.mesh = sphere
	instance.position = mesh_position
	instance.material_override = _make_material(color)
	parent.add_child(instance)


func _add_box(parent: Node3D, mesh_name: String, size: Vector3, mesh_position: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var box := BoxMesh.new()
	box.size = size
	instance.mesh = box
	instance.position = mesh_position
	instance.material_override = _make_material(color)
	parent.add_child(instance)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material


func _palette_color(html_color: String) -> Color:
	return Color(html_color)
