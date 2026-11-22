extends Node3D

const Palette = preload("res://scripts/core/town_palette.gd")

var _trim_material: StandardMaterial3D
var _face_material: StandardMaterial3D


func _ready() -> void:
	set_meta("location_id", "town.clock_tower")
	_trim_material = StandardMaterial3D.new()
	_trim_material.albedo_color = Color("#d9b766")
	_trim_material.metallic = 0.3
	_trim_material.roughness = 0.6
	_face_material = StandardMaterial3D.new()
	_face_material.albedo_color = Color("#f0e2bd")
	_face_material.roughness = 0.9

	_add_box("Stone plinth", Vector3(5.2, 0.55, 5.2), Vector3(0.0, 0.28, 0.0), Palette.FOUNDATION)
	_add_box("Plinth trim", Vector3(4.7, 0.18, 4.7), Vector3(0.0, 0.65, 0.0), Palette.SAND)
	_add_box("Tower shaft", Vector3(3.35, 8.0, 3.35), Vector3(0.0, 4.65, 0.0), Palette.SAND)
	for x in [-1.52, 1.52]:
		for z in [-1.52, 1.52]:
			_add_box("Corner pilaster", Vector3(0.2, 8.1, 0.2), Vector3(x, 4.65, z), Palette.FOUNDATION)
	_add_box("Clock chamber", Vector3(4.25, 3.0, 4.25), Vector3(0.0, 10.1, 0.0), Palette.FOUNDATION)
	_add_box("Clock chamber cornice", Vector3(4.65, 0.25, 4.65), Vector3(0.0, 11.65, 0.0), Palette.SAND)
	_add_clock_face()
	_add_roof()
	_add_cylinder("Flagpole", 0.05, 1.8, Vector3(0.0, 15.7, 0.0), _trim_material, 8)
	var flag_material := StandardMaterial3D.new()
	flag_material.albedo_color = Color("#a64c3c")
	flag_material.roughness = 0.9
	_add_box("Willowbrook flag", Vector3(0.9, 0.48, 0.07), Vector3(0.38, 15.98, 0.0), flag_material)

	var body := StaticBody3D.new()
	body.name = "ClockTowerCollision"
	add_child(body)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.5, 14.2, 4.5)
	collision.shape = box
	collision.position.y = 7.1
	body.add_child(collision)


func _add_clock_face() -> void:
	var face := MeshInstance3D.new()
	face.name = "Clock Dial"
	var dial := CylinderMesh.new()
	dial.top_radius = 1.05
	dial.bottom_radius = 1.05
	dial.height = 0.16
	dial.radial_segments = 24
	face.mesh = dial
	face.material_override = _face_material
	face.position = Vector3(0.0, 10.25, -2.2)
	face.rotation.x = PI * 0.5
	add_child(face)

	for marker_position in [
		Vector3(0.0, 11.03, -2.34), Vector3(0.78, 10.25, -2.34),
		Vector3(0.0, 9.47, -2.34), Vector3(-0.78, 10.25, -2.34),
	]:
		_add_sphere("Clock hour marker", 0.07, marker_position, _trim_material)

	_add_box("Clock hand", Vector3(0.08, 0.62, 0.07), Vector3(-0.15, 10.42, -2.38), _trim_material)
	_add_box("Clock minute hand", Vector3(0.06, 0.84, 0.07), Vector3(0.21, 10.54, -2.39), _trim_material)
	_add_sphere("Clock pin", 0.11, Vector3(0.0, 10.25, -2.43), _trim_material)


func _add_roof() -> void:
	var roof := CylinderMesh.new()
	roof.top_radius = 0.0
	roof.bottom_radius = 2.65
	roof.height = 2.8
	roof.radial_segments = 4
	var roof_instance := MeshInstance3D.new()
	roof_instance.name = "Copper spire roof"
	roof_instance.mesh = roof
	roof_instance.material_override = Palette.ROOF
	roof_instance.position.y = 13.45
	roof_instance.rotation.y = PI * 0.25
	add_child(roof_instance)
	_add_cylinder("Spire finial", 0.12, 1.05, Vector3(0.0, 15.28, 0.0), _trim_material, 8)


func _add_box(mesh_name: String, size: Vector3, at: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	add_child(instance)


func _add_cylinder(mesh_name: String, radius: float, height: float, at: Vector3, material: Material, segments: int) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	add_child(instance)


func _add_sphere(mesh_name: String, radius: float, at: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	instance.mesh = mesh
	instance.material_override = material
	instance.position = at
	add_child(instance)
