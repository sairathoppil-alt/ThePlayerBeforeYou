extends Node3D

const Palette = preload("res://scripts/core/town_palette.gd")


func _ready() -> void:
	_add_cylinder("Pole", 0.12, 5.2, Vector3(0, 2.6, 0), Palette.METAL)
	_add_box("Arm", Vector3(1.25, 0.12, 0.12), Vector3(0.55, 5.05, 0), Palette.METAL)
	_add_cylinder("Lantern collar", 0.36, 0.14, Vector3(1.1, 5.22, 0), Palette.METAL)

	var lamp := MeshInstance3D.new()
	lamp.name = "Lamp"
	var sphere := SphereMesh.new()
	sphere.radius = 0.32
	sphere.height = 0.55
	sphere.radial_segments = 6
	sphere.rings = 3
	lamp.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#ffd58b")
	material.emission_enabled = true
	material.emission = Color("#ffb85c")
	material.emission_energy_multiplier = 1.4
	lamp.material_override = material
	lamp.position = Vector3(1.1, 4.95, 0)
	add_child(lamp)
	_add_cylinder("Lantern roof", 0.48, 0.16, Vector3(1.1, 5.36, 0), Palette.METAL)
	_add_cylinder("Lantern base", 0.42, 0.1, Vector3(1.1, 4.62, 0), Palette.METAL)

	var body := StaticBody3D.new()
	body.name = "PoleCollision"
	add_child(body)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.22
	capsule.height = 5.2
	shape.shape = capsule
	shape.position.y = 2.6
	body.add_child(shape)


func _add_cylinder(mesh_name: String, radius: float, height: float, mesh_position: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius * 1.15
	cylinder.height = height
	cylinder.radial_segments = 7
	instance.mesh = cylinder
	instance.material_override = material
	instance.position = mesh_position
	add_child(instance)


func _add_box(mesh_name: String, box_size: Vector3, mesh_position: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var box := BoxMesh.new()
	box.size = box_size
	instance.mesh = box
	instance.material_override = material
	instance.position = mesh_position
	add_child(instance)
