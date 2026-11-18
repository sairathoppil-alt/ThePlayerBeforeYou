extends Area3D

signal player_entered(structure: Node3D, player: Node3D)
signal player_exited(structure: Node3D, player: Node3D)

const Palette = preload("res://scripts/core/town_palette.gd")

@export var structure_id := ""
@export var structure_name := ""
@export var action_id := ""
@export var improvement_cost := 0
@export var current_condition := ""
@export_multiline var risk_description := ""
@export_multiline var improvement_description := ""
@export var interaction_radius := 6.0

var improved := false
var _visual_root: Node3D
var _area_collision: CollisionShape3D


func configure(
	id: String,
	display_name: String,
	decision_id: String,
	cost: int,
	condition: String,
	risk: String,
	improvement: String,
	radius: float
) -> void:
	structure_id = id
	structure_name = display_name
	action_id = decision_id
	improvement_cost = cost
	current_condition = condition
	risk_description = risk
	improvement_description = improvement
	interaction_radius = radius


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_area_collision = CollisionShape3D.new()
	_area_collision.name = "InteractionRange"
	var sphere := SphereShape3D.new()
	sphere.radius = interaction_radius
	_area_collision.shape = sphere
	add_child(_area_collision)

	_visual_root = Node3D.new()
	_visual_root.name = "Visuals"
	add_child(_visual_root)
	_build_visuals()


func get_interaction_data() -> Dictionary:
	return {
		"structure_id": structure_id,
		"name": structure_name,
		"action_id": action_id,
		"cost": improvement_cost,
		"condition": current_condition,
		"risk": risk_description,
		"improvement": improvement_description,
	}


func set_improved(value: bool) -> void:
	if improved == value or _visual_root == null:
		improved = value
		return
	improved = value
	for child in _visual_root.get_children():
		_visual_root.remove_child(child)
		child.queue_free()
	_build_visuals()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_entered.emit(self, body)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_exited.emit(self, body)


func _build_visuals() -> void:
	match structure_id:
		"dam":
			_build_dam()
		"bridge":
			_build_bridge()
		"drainage":
			_build_drainage()
		"shelter":
			_build_shelter()
		"warning_tower":
			_build_warning_tower()


func _build_dam() -> void:
	_add_box("Dam wall", Vector3(2.2, 4.0, 27.0), Vector3(0, 1.9, 0), Palette.CONCRETE)
	_add_box("Upper cap", Vector3(2.8, 0.45, 28.0), Vector3(0, 4.0, 0), Palette.METAL if improved else Palette.CONCRETE)
	_add_static_box(Vector3(2.2, 4.0, 27.0), Vector3(0, 1.9, 0))
	if improved:
		for z in [-9.0, -4.5, 0.0, 4.5, 9.0]:
			_add_box("Reinforcement", Vector3(2.6, 4.4, 0.5), Vector3(0.0, 2.0, z), Palette.METAL)
	else:
		var crack := _add_box("Visible crack", Vector3(0.09, 1.8, 0.16), Vector3(1.15, 2.0, -2.0), Palette.WOOD)
		crack.rotation.x = -0.32


func _build_bridge() -> void:
	_add_box("Bridge deck", Vector3(9.0, 0.45, 27.0), Vector3(0, -0.19, 0), Palette.WOOD if improved else Palette.CONCRETE)
	_add_static_box(Vector3(9.0, 0.45, 27.0), Vector3(0, -0.19, 0))
	for z in [-10.0, -5.0, 0.0, 5.0, 10.0]:
		_add_box("Deck beam", Vector3(9.4, 0.2, 0.38), Vector3(0, -0.42, z), Palette.WOOD if improved else Palette.METAL)
	if improved:
		for x in [-4.25, 4.25]:
			_add_box("Bridge railing", Vector3(0.18, 1.15, 27.0), Vector3(x, 0.58, 0), Palette.WOOD)
		for z in [-9.0, 0.0, 9.0]:
			_add_box("Repaired deck plate", Vector3(8.7, 0.08, 1.5), Vector3(0, 0.055, z), Palette.SAND)
	else:
		_add_box("Damaged plank", Vector3(2.0, 0.06, 0.7), Vector3(0.6, 0.055, -3.0), Palette.WOOD)


func _build_drainage() -> void:
	_add_box("Drain channel", Vector3(4.8, 0.55, 1.8), Vector3(0, 0.15, 0), Palette.CONCRETE)
	_add_static_box(Vector3(4.8, 0.55, 1.8), Vector3(0, 0.15, 0))
	_add_box("Metal grate", Vector3(3.2, 0.12, 2.0), Vector3(0, 0.47, 0), Palette.METAL)
	if improved:
		for x in [-1.6, 0.0, 1.6]:
			_add_box("Open grate slot", Vector3(0.18, 0.04, 1.7), Vector3(x, 0.55, 0), Palette.ROAD)
		_add_cylinder("Outlet pipe", 0.55, 3.0, Vector3(0, -0.2, 1.5), Palette.METAL, Vector3(PI / 2.0, 0, 0))
	else:
		for index in range(4):
			_add_box(
				"Debris",
				Vector3(0.45, 0.32, 0.38),
				Vector3(-1.2 + float(index) * 0.72, 0.62, 0.0),
				Palette.WOOD
			)


func _build_shelter() -> void:
	_add_box("Construction foundation", Vector3(9.0, 0.35, 8.0), Vector3(0, 0.16, 0), Palette.FOUNDATION)
	if improved:
		_add_box("Shelter walls", Vector3(7.2, 3.6, 6.2), Vector3(0, 2.1, 0), Palette.SAND)
		_add_box("Shelter roof", Vector3(8.4, 0.45, 7.4), Vector3(0, 4.12, 0), Palette.ROOF)
		_add_box("Shelter door", Vector3(1.25, 2.4, 0.15), Vector3(0, 1.45, -3.18), Palette.WOOD)
		for x in [-2.4, 2.4]:
			_add_box("Shelter window", Vector3(1.1, 0.9, 0.12), Vector3(x, 2.55, -3.18), Palette.GLASS)
		_add_static_box(Vector3(7.2, 3.6, 6.2), Vector3(0, 2.1, 0))
	else:
		_add_box("Stacked lumber", Vector3(3.2, 0.42, 0.42), Vector3(-1.4, 0.65, 0.4), Palette.WOOD)
		_add_box("Stacked lumber", Vector3(3.2, 0.42, 0.42), Vector3(1.4, 0.65, 1.0), Palette.WOOD)
		_add_box("Site marker", Vector3(0.8, 1.1, 0.12), Vector3(0, 0.85, -3.6), Palette.METAL)


func _build_warning_tower() -> void:
	_add_cylinder("Concrete base", 1.4, 0.55, Vector3(0, 0.28, 0), Palette.CONCRETE)
	if improved:
		_add_cylinder("Tower mast", 0.22, 6.2, Vector3(0, 3.4, 0), Palette.METAL)
		for height in [1.4, 3.0, 4.6]:
			_add_box("Cross brace", Vector3(1.8, 0.1, 0.12), Vector3(0, height, 0), Palette.METAL)
			_add_box("Cross brace", Vector3(0.12, 0.1, 1.8), Vector3(0, height, 0), Palette.METAL)
		var beacon := _add_sphere("Warning beacon", 0.62, Vector3(0, 6.8, 0), Color("#ff554c"))
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color("#ff554c")
		glow.emission_enabled = true
		glow.emission = Color("#ff342b")
		glow.emission_energy_multiplier = 2.0
		beacon.material_override = glow
		_add_static_box(Vector3(0.7, 6.2, 0.7), Vector3(0, 3.2, 0))
	else:
		_add_box("Installation post", Vector3(0.7, 1.5, 0.7), Vector3(0, 1.0, 0), Palette.WOOD)
		_add_box("Equipment crate", Vector3(1.4, 0.8, 1.0), Vector3(1.2, 0.55, 0.8), Palette.SAND)


func _add_box(
	mesh_name: String,
	box_size: Vector3,
	mesh_position: Vector3,
	material: Material
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var box := BoxMesh.new()
	box.size = box_size
	instance.mesh = box
	instance.material_override = material
	instance.position = mesh_position
	_visual_root.add_child(instance)
	return instance


func _add_cylinder(
	mesh_name: String,
	radius: float,
	height: float,
	mesh_position: Vector3,
	material: Material,
	mesh_rotation: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 8
	instance.mesh = cylinder
	instance.material_override = material
	instance.position = mesh_position
	instance.rotation = mesh_rotation
	_visual_root.add_child(instance)
	return instance


func _add_sphere(mesh_name: String, radius: float, mesh_position: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	instance.mesh = sphere
	instance.position = mesh_position
	_visual_root.add_child(instance)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	instance.material_override = material
	return instance


func _add_static_box(box_size: Vector3, shape_position: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "StructureCollision"
	_visual_root.add_child(body)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = box_size
	collision.shape = box
	collision.position = shape_position
	body.add_child(collision)
