extends Node3D

const Palette = preload("res://scripts/core/town_palette.gd")

@export var bed_size := Vector2(4.5, 2.2)
@export var flower_tint := Color("#d87d77")


func _ready() -> void:
	var soil := MeshInstance3D.new()
	soil.name = "Raised garden bed"
	var soil_mesh := BoxMesh.new()
	soil_mesh.size = Vector3(bed_size.x, 0.35, bed_size.y)
	soil.mesh = soil_mesh
	soil.material_override = Palette.WOOD
	soil.position.y = 0.18
	add_child(soil)

	var soil_surface := MeshInstance3D.new()
	soil_surface.name = "Garden soil"
	var surface_mesh := BoxMesh.new()
	surface_mesh.size = Vector3(bed_size.x - 0.22, 0.08, bed_size.y - 0.22)
	soil_surface.mesh = surface_mesh
	soil_surface.material_override = Palette.TRUNK
	soil_surface.position.y = 0.38
	add_child(soil_surface)

	var flower_material := StandardMaterial3D.new()
	flower_material.albedo_color = flower_tint
	flower_material.roughness = 0.9
	var leaf_material := StandardMaterial3D.new()
	leaf_material.albedo_color = Color("#55764c")
	leaf_material.roughness = 1.0
	for index in range(7):
		var x := -bed_size.x * 0.38 + float(index) * bed_size.x * 0.125
		var z := -bed_size.y * 0.28 if index % 2 == 0 else bed_size.y * 0.25
		_add_stem(x, z, leaf_material)
		_add_flower(x, z, 0.78 + float(index % 3) * 0.12, flower_material)

	var body := StaticBody3D.new()
	body.name = "FlowerBedCollision"
	add_child(body)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(bed_size.x, 0.45, bed_size.y)
	collision.shape = box
	collision.position.y = 0.22
	body.add_child(collision)


func _add_stem(x: float, z: float, material: Material) -> void:
	var stem := MeshInstance3D.new()
	stem.name = "Flower stem"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.035
	mesh.bottom_radius = 0.05
	mesh.height = 0.52
	mesh.radial_segments = 5
	stem.mesh = mesh
	stem.material_override = material
	stem.position = Vector3(x, 0.66, z)
	add_child(stem)


func _add_flower(x: float, z: float, height: float, material: Material) -> void:
	var bloom := MeshInstance3D.new()
	bloom.name = "Low-poly flower"
	var mesh := SphereMesh.new()
	mesh.radius = 0.11
	mesh.height = 0.18
	mesh.radial_segments = 6
	mesh.rings = 3
	bloom.mesh = mesh
	bloom.material_override = material
	bloom.position = Vector3(x, height, z)
	add_child(bloom)
