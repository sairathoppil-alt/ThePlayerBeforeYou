extends CharacterBody3D

signal interact_requested
signal pause_requested
signal cursor_toggle_requested

const WALK_SPEED := 7.0
const GRAVITY := 22.0
const MOUSE_SENSITIVITY := 0.0026
const AVATAR_MATERIAL := Color("#4bb6c5")
const TROUSER_MATERIAL := Color("#27394d")
const SKIN_MATERIAL := Color("#e0ad83")

@onready var camera_pivot: Node3D = $CameraPivot
@onready var visuals: Node3D = $Visuals

var _gameplay_input_enabled := true
var _camera_pitch := -0.22
var _walk_clock := 0.0
var _leg_pivots: Array[Node3D] = []
var _arm_pivots: Array[Node3D] = []


func _ready() -> void:
	add_to_group("player")
	_register_movement_actions()
	_build_avatar()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
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
			velocity.x = direction.x * WALK_SPEED
			velocity.z = direction.z * WALK_SPEED
			visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(-direction.x, -direction.z), delta * 11.0)
		else:
			velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 8.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 10.0 * delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	move_and_slide()
	_animate_walking(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		pause_requested.emit()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_TAB:
			cursor_toggle_requested.emit()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_E and _gameplay_input_enabled:
			interact_requested.emit()
			get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and _gameplay_input_enabled:
		_rotate_camera(event.relative)


func set_gameplay_input_enabled(enabled: bool) -> void:
	_gameplay_input_enabled = enabled


func set_mouse_captured(captured: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE
	set_gameplay_input_enabled(captured)


func _rotate_camera(mouse_delta: Vector2) -> void:
	camera_pivot.rotation.y -= mouse_delta.x * MOUSE_SENSITIVITY
	_camera_pitch = clampf(_camera_pitch - mouse_delta.y * MOUSE_SENSITIVITY, -0.95, 0.18)
	camera_pivot.rotation.x = _camera_pitch


func _register_movement_actions() -> void:
	_ensure_action("move_forward", [87, 4194320])
	_ensure_action("move_back", [83, 4194322])
	_ensure_action("move_left", [65, 4194319])
	_ensure_action("move_right", [68, 4194321])


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
	_add_capsule(visuals, "Body", 0.35, 0.92, Vector3(0, 1.12, 0), AVATAR_MATERIAL)
	_add_sphere(visuals, "Head", 0.24, Vector3(0, 1.82, 0), SKIN_MATERIAL)
	_add_sphere(visuals, "Hair", 0.245, Vector3(0, 1.94, 0), Color("#40332f"))
	_add_box(visuals, "Belt", Vector3(0.58, 0.16, 0.38), Vector3(0, 0.66, 0), _palette_color("#c79553"))

	for side in [-1, 1]:
		var leg_pivot := Node3D.new()
		leg_pivot.name = "LegPivot%d" % side
		leg_pivot.position = Vector3(0.16 * float(side), 0.68, 0)
		visuals.add_child(leg_pivot)
		_add_capsule(leg_pivot, "Leg", 0.14, 0.66, Vector3(0, -0.34, 0), TROUSER_MATERIAL)
		_leg_pivots.append(leg_pivot)

		var arm_pivot := Node3D.new()
		arm_pivot.name = "ArmPivot%d" % side
		arm_pivot.position = Vector3(0.39 * float(side), 1.42, 0)
		visuals.add_child(arm_pivot)
		_add_capsule(arm_pivot, "Arm", 0.115, 0.65, Vector3(0, -0.32, 0), AVATAR_MATERIAL)
		_arm_pivots.append(arm_pivot)


func _animate_walking(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.35 and is_on_floor() and _gameplay_input_enabled:
		_walk_clock += delta * 8.0
	else:
		_walk_clock = move_toward(_walk_clock, round(_walk_clock / TAU) * TAU, delta * 4.0)

	var swing := sin(_walk_clock) * minf(horizontal_speed / WALK_SPEED, 1.0) * 0.52
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
