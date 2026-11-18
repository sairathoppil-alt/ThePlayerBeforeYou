extends Node3D

const Palette = preload("res://scripts/core/town_palette.gd")

@export var wall_color := Color("#d6b87f")
@export var roof_color := Color("#a34f36")


func _ready() -> void:
	var walls := StandardMaterial3D.new()
	walls.albedo_color = wall_color
	walls.roughness = 1.0
	var roof := StandardMaterial3D.new()
	roof.albedo_color = roof_color
	roof.roughness = 0.95

	_add_box("Foundation", Vector3(7.7, 0.35, 6.7), Vector3(0, 0.15, 0), Palette.CONCRETE)
	_add_box("Walls", Vector3(7.0, 3.8, 6.0), Vector3(0, 2.15, 0), walls)
	_add_box("Roof left", Vector3(4.5, 0.32, 6.8), Vector3(-1.8, 4.12, 0), roof, Vector3(0, 0, -0.48))
	_add_box("Roof right", Vector3(4.5, 0.32, 6.8), Vector3(1.8, 4.12, 0), roof, Vector3(0, 0, 0.48))

	for window_x in [-2.25, 2.25]:
		_add_box("Front window", Vector3(1.15, 0.9, 0.12), Vector3(window_x, 2.55, -3.06), Palette.GLASS)
		_add_box("Back window", Vector3(1.15, 0.9, 0.12), Vector3(window_x, 2.55, 3.06), Palette.GLASS)
	_add_box("Front door", Vector3(1.15, 2.25, 0.16), Vector3(0, 1.35, -3.08), Palette.WOOD)
	_add_box("Door handle", Vector3(0.08, 0.08, 0.05), Vector3(0.37, 1.3, -3.18), Palette.METAL)

	var body := StaticBody3D.new()
	body.name = "BuildingCollision"
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(7.2, 4.2, 6.2)
	shape.shape = box
	shape.position.y = 2.1
	body.add_child(shape)


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
