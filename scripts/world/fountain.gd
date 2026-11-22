extends Node3D

const Palette = preload("res://scripts/core/town_palette.gd")


func _ready() -> void:
	set_meta("location_id", "town.fountain")
	_add_cylinder("Foundation", 3.25, 0.3, Vector3(0.0, 0.15, 0.0), Palette.FOUNDATION, 12)
	for index in range(12):
		var angle := TAU * float(index) / 12.0
		var segment_position := Vector3(cos(angle) * 2.82, 0.58, sin(angle) * 2.82)
		var rim_position := Vector3(cos(angle) * 2.96, 0.92, sin(angle) * 2.96)
		var segment := _add_box("Basin stone", Vector3(1.48, 0.62, 0.48), segment_position, Palette.CONCRETE)
		segment.rotation.y = angle + PI * 0.5
		var rim := _add_box("Basin rim stone", Vector3(1.56, 0.18, 0.32), rim_position, Palette.SAND)
		rim.rotation.y = angle + PI * 0.5
	_add_cylinder("Basin water", 2.55, 0.06, Vector3(0.0, 0.84, 0.0), Palette.WATER, 24)
	_add_cylinder("Pedestal", 0.62, 1.55, Vector3(0.0, 1.72, 0.0), Palette.FOUNDATION, 10)
	for index in range(10):
		var angle := TAU * float(index) / 10.0
		var bowl_position := Vector3(cos(angle) * 1.18, 2.62, sin(angle) * 1.18)
		var bowl_segment := _add_box("Upper bowl stone", Vector3(0.8, 0.42, 0.32), bowl_position, Palette.CONCRETE)
		bowl_segment.rotation.y = angle + PI * 0.5
	_add_cylinder("Upper water", 0.92, 0.05, Vector3(0.0, 2.85, 0.0), Palette.WATER, 16)
	_add_cylinder("Water column", 0.13, 0.62, Vector3(0.0, 3.13, 0.0), Palette.WATER, 8)
	_add_sphere("Finial", 0.25, Vector3(0.0, 3.5, 0.0), Palette.METAL)

	var collision := StaticBody3D.new()
	collision.name = "FountainCollision"
	add_child(collision)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 3.1
	cylinder.height = 1.05
	shape.shape = cylinder
	shape.position.y = 0.52
	collision.add_child(shape)


func _add_cylinder(
	mesh_name: String,
	radius: float,
	height: float,
	mesh_position: Vector3,
	material: Material,
	segments: int
) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	instance.mesh = mesh
	instance.material_override = material
	instance.position = mesh_position
	add_child(instance)


func _add_sphere(mesh_name: String, radius: float, mesh_position: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	instance.mesh = mesh
	instance.material_override = material
	instance.position = mesh_position
	add_child(instance)


func _add_box(mesh_name: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	add_child(instance)
	return instance
