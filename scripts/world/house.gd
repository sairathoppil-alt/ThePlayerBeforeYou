extends Node3D

const Palette = preload("res://scripts/core/town_palette.gd")

@export var wall_color := Color("#d6b87f")
@export var roof_color := Color("#a34f36")
@export var building_type := "cottage"
@export var shop_name := "WILLOWBROOK STORE"
@export var location_id := ""
@export var awning_color := Color("#b85d48")
@export var future_damaged := false


func _ready() -> void:
	var walls := StandardMaterial3D.new()
	walls.albedo_color = wall_color.darkened(0.38) if future_damaged else wall_color
	walls.roughness = 1.0
	walls.cull_mode = BaseMaterial3D.CULL_DISABLED
	var roof := StandardMaterial3D.new()
	roof.albedo_color = roof_color.darkened(0.36) if future_damaged else roof_color
	roof.roughness = 0.95

	_add_box("Foundation", Vector3(7.7, 0.35, 6.7), Vector3(0, 0.15, 0), Palette.CONCRETE)
	_add_box("Foundation trim", Vector3(7.45, 0.16, 6.45), Vector3(0, 0.38, 0), Palette.SAND)
	_add_box("Walls", Vector3(7.0, 3.8, 6.0), Vector3(0, 2.15, 0), walls)
	_add_gables(walls)
	_add_box("Roof left", Vector3(4.5, 0.32, 6.8), Vector3(-1.8, 4.12, 0), roof, Vector3(0, 0, -0.48))
	_add_box("Roof right", Vector3(4.5, 0.32, 6.8), Vector3(1.8, 4.12, 0), roof, Vector3(0, 0, 0.48))
	_add_box("Roof ridge", Vector3(0.34, 0.34, 7.0), Vector3(0, 5.05, 0), roof)
	_add_box("Left eave", Vector3(0.14, 0.22, 6.95), Vector3(-3.17, 3.86, 0), Palette.WOOD)
	_add_box("Right eave", Vector3(0.14, 0.22, 6.95), Vector3(3.17, 3.86, 0), Palette.WOOD)
	for z in [-3.35, 3.35]:
		_add_box("Front roof rake", Vector3(4.55, 0.16, 0.16), Vector3(-1.78, 4.23, z), Palette.WOOD, Vector3(0, 0, -0.48))
		_add_box("Back roof rake", Vector3(4.55, 0.16, 0.16), Vector3(1.78, 4.23, z), Palette.WOOD, Vector3(0, 0, 0.48))

	for window_x in [-2.25, 2.25]:
		_add_box("Front window", Vector3(1.15, 0.9, 0.12), Vector3(window_x, 2.55, -3.06), Palette.GLASS)
		_add_box("Back window", Vector3(1.15, 0.9, 0.12), Vector3(window_x, 2.55, 3.06), Palette.GLASS)
		for side_x in [-0.66, 0.66]:
			_add_box("Front window frame", Vector3(0.11, 1.1, 0.1), Vector3(window_x + side_x, 2.55, -3.15), Palette.WOOD)
			_add_box("Back window frame", Vector3(0.11, 1.1, 0.1), Vector3(window_x + side_x, 2.55, 3.15), Palette.WOOD)
			_add_box("Front shutter", Vector3(0.22, 0.92, 0.12), Vector3(window_x + side_x * 1.18, 2.55, -3.17), Palette.WOOD)
		for face_z in [-3.15, 3.15]:
			_add_box("Window crossbar", Vector3(1.25, 0.1, 0.1), Vector3(window_x, 2.55, face_z), Palette.WOOD)
		_add_box("Window sill", Vector3(1.42, 0.14, 0.28), Vector3(window_x, 2.02, -3.18), Palette.SAND)
	_add_box("Front door", Vector3(1.15, 2.25, 0.16), Vector3(0, 1.35, -3.08), Palette.WOOD)
	_add_box("Door frame left", Vector3(0.12, 2.45, 0.16), Vector3(-0.67, 1.4, -3.17), Palette.SAND)
	_add_box("Door frame right", Vector3(0.12, 2.45, 0.16), Vector3(0.67, 1.4, -3.17), Palette.SAND)
	_add_box("Door lintel", Vector3(1.46, 0.15, 0.18), Vector3(0, 2.6, -3.17), Palette.SAND)
	_add_box("Doorstep", Vector3(1.55, 0.17, 0.6), Vector3(0, 0.23, -3.35), Palette.CONCRETE)
	_add_box("Door handle", Vector3(0.08, 0.08, 0.05), Vector3(0.37, 1.3, -3.18), Palette.METAL)
	_add_box("Chimney", Vector3(0.85, 1.7, 0.9), Vector3(2.35, 4.75, 1.3), Palette.ROOF)
	_add_box("Chimney cap", Vector3(1.05, 0.18, 1.1), Vector3(2.35, 5.65, 1.3), Palette.CONCRETE)
	if building_type == "shop":
		_add_shop_front()
	if future_damaged:
		_add_box("Boarded front window", Vector3(1.3, 0.14, 0.14), Vector3(-2.25, 2.55, -3.25), Palette.WOOD)
		_add_box("Broken roof panel", Vector3(1.7, 0.14, 1.2), Vector3(2.0, 4.12, 1.2), Palette.FOUNDATION)
		_add_box("Flood debris", Vector3(1.8, 0.65, 0.75), Vector3(-4.3, 0.35, 2.0), Palette.WOOD)

	var body := StaticBody3D.new()
	body.name = "BuildingCollision"
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(7.2, 4.2, 6.2)
	shape.shape = box
	shape.position.y = 2.1
	body.add_child(shape)


func _add_gables(walls: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_normal(Vector3.FORWARD)
	surface.add_vertex(Vector3(-3.5, 3.98, -3.04))
	surface.add_vertex(Vector3(0.0, 5.18, -3.04))
	surface.add_vertex(Vector3(3.5, 3.98, -3.04))
	surface.set_normal(Vector3.BACK)
	surface.add_vertex(Vector3(-3.5, 3.98, 3.04))
	surface.add_vertex(Vector3(3.5, 3.98, 3.04))
	surface.add_vertex(Vector3(0.0, 5.18, 3.04))
	var gable := MeshInstance3D.new()
	gable.name = "Plaster gables"
	gable.mesh = surface.commit()
	gable.material_override = walls
	add_child(gable)


func _add_shop_front() -> void:
	var awning := StandardMaterial3D.new()
	awning.albedo_color = awning_color
	awning.roughness = 0.9
	_add_box("Shop awning", Vector3(3.4, 0.2, 0.85), Vector3(0, 3.28, -3.5), awning)
	for x in [-1.6, 1.6]:
		_add_box("Awning support", Vector3(0.12, 0.8, 0.12), Vector3(x, 2.9, -3.47), Palette.WOOD)
	_add_box("Store signboard", Vector3(3.5, 0.72, 0.18), Vector3(0, 4.05, -3.18), Palette.WOOD)
	var sign := Label3D.new()
	sign.name = "Shop sign"
	sign.text = shop_name
	sign.font_size = 34
	sign.pixel_size = 0.008
	sign.position = Vector3(0, 4.02, -3.29)
	sign.modulate = Color("#f4dfb2")
	sign.outline_size = 5
	sign.outline_modulate = Color("#402c24")
	add_child(sign)
	_add_box("Shop display window", Vector3(2.3, 1.0, 0.12), Vector3(0, 2.52, -3.13), Palette.GLASS)
	_add_box("Display window sill", Vector3(2.5, 0.16, 0.22), Vector3(0, 1.96, -3.2), Palette.SAND)


func _add_box(
	mesh_name: String,
	box_size: Vector3,
	mesh_position: Vector3,
	material: Material,
	mesh_rotation: Vector3 = Vector3.ZERO
) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var box := BoxMesh.new()
	box.size = box_size
	instance.mesh = box
	instance.material_override = material
	instance.position = mesh_position
	instance.rotation = mesh_rotation
	add_child(instance)
