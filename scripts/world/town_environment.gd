extends Node3D

const Palette = preload("res://scripts/core/town_palette.gd")
const HOUSE_SCENE: PackedScene = preload("res://scenes/structures/house.tscn")
const TREE_SCENE: PackedScene = preload("res://scenes/structures/tree.tscn")
const STREETLIGHT_SCENE: PackedScene = preload("res://scenes/structures/streetlight.tscn")
const INTERACTIVE_SCENE: PackedScene = preload("res://scenes/structures/interactive_structure.tscn")

@export var create_interactive_structures := true

var _structures: Array[Node3D] = []


func _ready() -> void:
	_build_lighting()
	_build_ground_and_river()
	_build_roads()
	_build_houses()
	_build_trees()
	_build_streetlights()
	_build_mountains()
	_build_map_bounds()
	if create_interactive_structures:
		_build_interactive_structures()


func get_structures() -> Array[Node3D]:
	return _structures.duplicate()


func _build_lighting() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#a8c8dd")
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#4c91c4")
	sky_material.sky_horizon_color = Color("#b7d3dd")
	sky_material.ground_bottom_color = Color("#53624a")
	sky_material.ground_horizon_color = Color("#9eae9d")
	sky_material.sun_angle_max = 18.0
	sky.sky_material = sky_material
	environment.sky = sky
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "2026 Sunlight"
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color("#fff1d3")
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 110.0
	add_child(sun)


func _build_ground_and_river() -> void:
	for bank_center_z in [-30.6, 30.6]:
		var ground := MeshInstance3D.new()
		ground.name = "Grassy Terrain"
		var terrain_mesh := BoxMesh.new()
		terrain_mesh.size = Vector3(100, 0.2, 38.8)
		ground.mesh = terrain_mesh
		ground.material_override = Palette.GRASS
		ground.position = Vector3(0, -0.1, bank_center_z)
		add_child(ground)

		var ground_body := StaticBody3D.new()
		ground_body.name = "TerrainCollision"
		add_child(ground_body)
		var ground_shape := CollisionShape3D.new()
		var ground_box := BoxShape3D.new()
		ground_box.size = terrain_mesh.size
		ground_shape.shape = ground_box
		ground_shape.position = ground.position
		ground_body.add_child(ground_shape)

	var river := MeshInstance3D.new()
	river.name = "Flowing Riverside"
	var river_mesh := BoxMesh.new()
	river_mesh.size = Vector3(100, 0.08, 21.8)
	river.mesh = river_mesh
	river.material_override = Palette.WATER
	river.position.y = -0.04
	add_child(river)

	var river_bed := StaticBody3D.new()
	river_bed.name = "Shallow Riverbed"
	add_child(river_bed)
	var riverbed_shape := CollisionShape3D.new()
	var riverbed_box := BoxShape3D.new()
	riverbed_box.size = river_mesh.size
	riverbed_shape.shape = riverbed_box
	riverbed_shape.position.y = -0.1
	river_bed.add_child(riverbed_shape)

	for bank_z in [-11.2, 11.2]:
		_add_river_bank_segment(-20.25, 59.5, bank_z)
		_add_river_bank_segment(34.25, 31.5, bank_z)


func _add_river_bank_segment(center_x: float, length: float, bank_z: float) -> void:
	var bank := MeshInstance3D.new()
	bank.name = "Raised River Bank"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(length, 0.7, 0.7)
	bank.mesh = mesh
	bank.material_override = Palette.FOUNDATION
	bank.position = Vector3(center_x, 0.35, bank_z)
	add_child(bank)

	var body := StaticBody3D.new()
	body.name = "River Boundary"
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collision.shape = shape
	collision.position = bank.position
	body.add_child(collision)


func _build_roads() -> void:
	_add_road("Northbank Main Road", Vector3(76, 0.12, 6), Vector3(0, 0.02, -22))
	_add_road("Southbank Main Road", Vector3(76, 0.12, 6), Vector3(0, 0.02, 22))
	_add_road("North Town Lane", Vector3(6, 0.12, 25), Vector3(14, 0.02, -33.5))
	_add_road("South Town Lane", Vector3(6, 0.12, 25), Vector3(14, 0.02, 33.5))
	_add_road("North Cross Street", Vector3(68, 0.12, 5), Vector3(0, 0.02, -37))
	_add_road("South Cross Street", Vector3(68, 0.12, 5), Vector3(0, 0.02, 39))
	_add_path("Shelter Footpath", Vector3(2.2, 0.08, 10), Vector3(26, 0.02, -29))
	_add_path("Warning Tower Footpath", Vector3(10, 0.08, 2.2), Vector3(-28, 0.02, -34))

	for side in [-1, 1]:
		for x in [-35, -20, -5, 14, 32]:
			_add_box_mesh(
				"Road Center Mark",
				Vector3(2.2, 0.018, 0.16),
				Vector3(x, 0.09, 22.0 * float(side)),
				Palette.SAND
			)


func _add_road(road_name: String, size: Vector3, road_position: Vector3) -> void:
	_add_box_mesh(road_name, size, road_position, Palette.ROAD)


func _add_path(path_name: String, size: Vector3, path_position: Vector3) -> void:
	_add_box_mesh(path_name, size, path_position, Palette.SAND)


func _build_houses() -> void:
	var houses: Array[Dictionary] = [
		{"position": Vector3(-36, 0, -33), "wall": Color("#d6b87f"), "roof": Color("#a34f36"), "rotation": 0.0},
		{"position": Vector3(-16, 0, -34), "wall": Color("#d9c6a0"), "roof": Color("#526c72"), "rotation": 0.0},
		{"position": Vector3(3, 0, -34), "wall": Color("#c58e66"), "roof": Color("#9b4935"), "rotation": 0.0},
		{"position": Vector3(37, 0, -33), "wall": Color("#c6d0b1"), "roof": Color("#4c6860"), "rotation": 0.0},
		{"position": Vector3(-36, 0, 34), "wall": Color("#d9c6a0"), "roof": Color("#a34f36"), "rotation": PI},
		{"position": Vector3(-15, 0, 34), "wall": Color("#d6b87f"), "roof": Color("#526c72"), "rotation": PI},
		{"position": Vector3(34, 0, 39), "wall": Color("#c58e66"), "roof": Color("#8d4737"), "rotation": PI},
	]
	for house_data in houses:
		var house := HOUSE_SCENE.instantiate() as Node3D
		house.set("wall_color", house_data["wall"])
		house.set("roof_color", house_data["roof"])
		house.position = house_data["position"]
		house.rotation.y = float(house_data["rotation"])
		add_child(house)


func _build_trees() -> void:
	var positions: Array[Vector3] = [
		Vector3(-46, 0, -41), Vector3(-43, 0, -25), Vector3(-27, 0, -43),
		Vector3(-8, 0, -45), Vector3(8, 0, -43), Vector3(43, 0, -42),
		Vector3(45, 0, -26), Vector3(-46, 0, 28), Vector3(-41, 0, 43),
		Vector3(-24, 0, 31), Vector3(-8, 0, 44), Vector3(2, 0, 31),
		Vector3(27, 0, 30), Vector3(44, 0, 31), Vector3(43, 0, 44),
	]
	for index in range(positions.size()):
		var tree := TREE_SCENE.instantiate() as Node3D
		tree.position = positions[index]
		tree.scale = Vector3.ONE * (0.78 + float(index % 4) * 0.12)
		tree.set("crown_color", Color("#4b8745") if index % 2 == 0 else Color("#5b9148"))
		add_child(tree)


func _build_streetlights() -> void:
	for position in [
		Vector3(-28, 0, -22), Vector3(-8, 0, -22), Vector3(31, 0, -22),
		Vector3(-28, 0, 22), Vector3(-8, 0, 22), Vector3(31, 0, 22),
	]:
		var light := STREETLIGHT_SCENE.instantiate() as Node3D
		light.position = position
		add_child(light)


func _build_mountains() -> void:
	var mountain_positions: Array[Vector3] = [
		Vector3(-60, 0, -54), Vector3(-38, 0, -65), Vector3(-8, 0, -64),
		Vector3(24, 0, -64), Vector3(58, 0, -55), Vector3(66, 0, -18),
		Vector3(64, 0, 25), Vector3(48, 0, 61), Vector3(12, 0, 65),
		Vector3(-28, 0, 64), Vector3(-62, 0, 48), Vector3(-66, 0, 12),
	]
	for index in range(mountain_positions.size()):
		var height := 18.0 + float((index * 7) % 13)
		var mountain := MeshInstance3D.new()
		mountain.name = "Distant Low Poly Hill"
		var peak := CylinderMesh.new()
		peak.top_radius = 0.0
		peak.bottom_radius = 12.0 + float(index % 3) * 3.0
		peak.height = height
		peak.radial_segments = 6 if index % 2 == 0 else 7
		mountain.mesh = peak
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("#536b5f") if index % 2 == 0 else Color("#617666")
		material.roughness = 1.0
		mountain.material_override = material
		mountain.position = mountain_positions[index] + Vector3(0, height * 0.5 - 1.0, 0)
		add_child(mountain)


func _build_map_bounds() -> void:
	_add_boundary(Vector3(0, 2.5, -49.5), Vector3(100, 5, 1))
	_add_boundary(Vector3(0, 2.5, 49.5), Vector3(100, 5, 1))
	_add_boundary(Vector3(-49.5, 2.5, 0), Vector3(1, 5, 100))
	_add_boundary(Vector3(49.5, 2.5, 0), Vector3(1, 5, 100))


func _add_boundary(boundary_position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "Playable Area Boundary"
	add_child(body)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	collision.position = boundary_position
	body.add_child(collision)


func _build_interactive_structures() -> void:
	_spawn_structure(
		"dam", "Dam", "repair_dam", 30, "Cracked and leaking",
		"Visible cracks and a weakened spillway could fail under the rising flood.",
		"Seal the spillway and reinforce the wall with steel braces.", Vector3(-22, 0, 0), 14.5
	)
	_spawn_structure(
		"bridge", "Bridge", "strengthen_bridge", 20, "Damaged deck",
		"Loose deck sections could make the only safe river crossing unreliable.",
		"Replace damaged deck panels and add protective railings.", Vector3(14, 0, 0), 9.0
	)
	_spawn_structure(
		"drainage", "Drainage System", "improve_drainage", 15, "Partly blocked",
		"Debris in the storm drain may leave the low streets under water.",
		"Clear the drain and install a reinforced outlet pipe.", Vector3(0, 0, -13.6), 7.5
	)
	_spawn_structure(
		"shelter", "Emergency Shelter Site", "build_shelter", 20, "Construction site",
		"No safe evacuation shelter is available for residents on the north bank.",
		"Build an elevated, weather-resistant community shelter.", Vector3(26, 0, -34), 8.0
	)
	_spawn_structure(
		"warning_tower", "Warning Tower Site", "install_warning_system", 15, "Not installed",
		"Without an early warning system, residents may not have time to evacuate.",
		"Install a high-mounted flood siren and warning beacon.", 		Vector3(-28, 0, -31), 8.0
	)


func _spawn_structure(
	id: String,
	display_name: String,
	decision_id: String,
	cost: int,
	condition: String,
	risk: String,
	improvement: String,
	structure_position: Vector3,
	radius: float
) -> void:
	var structure := INTERACTIVE_SCENE.instantiate() as Node3D
	structure.call(
		"configure",
		id,
		display_name,
		decision_id,
		cost,
		condition,
		risk,
		improvement,
		radius
	)
	structure.position = structure_position
	add_child(structure)
	_structures.append(structure)


func _add_box_mesh(
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
	add_child(instance)
	return instance
