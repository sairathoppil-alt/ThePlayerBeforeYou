extends Node3D

const Palette = preload("res://scripts/core/town_palette.gd")

@export var crown_color := Color("#4b8745")


func _ready() -> void:
	var trunk := MeshInstance3D.new()
	trunk.name = "Trunk"
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.28
	trunk_mesh.bottom_radius = 0.42
	trunk_mesh.height = 3.0
	trunk_mesh.radial_segments = 7
	trunk.mesh = trunk_mesh
	trunk.material_override = Palette.TRUNK
	trunk.position.y = 1.5
	add_child(trunk)

	for index in range(3):
		var crown := MeshInstance3D.new()
		crown.name = "Crown%d" % index
		var sphere := SphereMesh.new()
		sphere.radius = 1.7 if index == 0 else 1.35
		sphere.height = sphere.radius * 1.7
		sphere.radial_segments = 7
		sphere.rings = 4
		crown.mesh = sphere
		var foliage := StandardMaterial3D.new()
		foliage.albedo_color = crown_color.darkened(float(index) * 0.08)
		foliage.roughness = 1.0
		crown.material_override = foliage
		crown.position = Vector3(
			float(index - 1) * 0.72,
			3.0 + float(index % 2) * 0.65,
			float((index + 1) % 2) * 0.45
		)
		add_child(crown)

	var body := StaticBody3D.new()
	body.name = "TrunkCollision"
	add_child(body)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 3.0
	collision.shape = capsule
	collision.position.y = 1.5
	body.add_child(collision)
