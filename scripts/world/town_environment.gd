extends Node3D

const Palette = preload("res://scripts/core/town_palette.gd")
const TownLocations = preload("res://scripts/core/town_locations.gd")
const HOUSE_SCENE: PackedScene = preload("res://scenes/structures/house.tscn")
const TREE_SCENE: PackedScene = preload("res://scenes/structures/tree.tscn")
const STREETLIGHT_SCENE: PackedScene = preload("res://scenes/structures/streetlight.tscn")
const INTERACTIVE_SCENE: PackedScene = preload("res://scenes/structures/interactive_structure.tscn")
const CLOCK_TOWER_SCENE: PackedScene = preload("res://scenes/structures/clock_tower.tscn")
const FOUNTAIN_SCENE: PackedScene = preload("res://scenes/structures/fountain.tscn")
const FLOWER_BED_SCENE: PackedScene = preload("res://scenes/structures/flower_bed.tscn")
const TOWN_FACILITY_SCENE: PackedScene = preload("res://scenes/structures/town_facility.tscn")

@export var create_interactive_structures := true
@export_enum("2026 — The Past:2026", "2046 — The Future:2046") var timeline_year := 2026
@export var visual_only := false
@export var photograph_baseline := false

var _structures: Array[Node3D] = []
var _electrical_pattern_lights: Array[OmniLight3D] = []
var _electrical_pattern_clock := 0.0


func _ready() -> void:
	_build_lighting()
	_build_ground_and_river()
	_build_roads()
	_build_houses()
	_build_town_square()
	_build_trees()
	_build_streetlights()
	_build_environment_details()
	_build_essential_locations()
	_build_persistent_mission_geometry()
	_build_shopkeeper()
	_build_mountains()
	_build_map_bounds()
	if create_interactive_structures:
		_build_interactive_structures()
	else:
		_build_geographic_structures()
	if timeline_year == 2046:
		_build_future_flood_effects()
	if visual_only:
		_strip_collision_objects()


func _process(delta: float) -> void:
	if _electrical_pattern_lights.is_empty():
		return
	_electrical_pattern_clock = fposmod(_electrical_pattern_clock + delta, 3.6)
	for index in range(_electrical_pattern_lights.size()):
		var pulse_time := 0.35 + float(index) * 0.9
		var distance := absf(_electrical_pattern_clock - pulse_time)
		if distance > 1.8:
			distance = 3.6 - distance
		_electrical_pattern_lights[index].light_energy = 1.5 if distance < 0.18 else 0.03


func get_structures() -> Array[Node3D]:
	return _structures.duplicate()


func _build_lighting() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#aab39c") if timeline_year == 2026 else Color("#667b8a")
	environment.ambient_light_energy = 0.24 if timeline_year == 2026 else 0.42
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color("#b7c6bb") if timeline_year == 2026 else Color("#75848b")
	environment.fog_density = 0.0012 if timeline_year == 2026 else 0.004
	environment.fog_sky_affect = 0.45 if timeline_year == 2026 else 0.8
	environment.fog_depth_begin = 58.0 if timeline_year == 2026 else 24.0
	environment.fog_depth_end = 175.0 if timeline_year == 2026 else 105.0

	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#548cb2") if timeline_year == 2026 else Color("#344857")
	sky_material.sky_horizon_color = Color("#d3c9ad") if timeline_year == 2026 else Color("#849094")
	sky_material.ground_bottom_color = Color("#465648") if timeline_year == 2026 else Color("#343d40")
	sky_material.ground_horizon_color = Color("#a8b19d") if timeline_year == 2026 else Color("#68777b")
	sky_material.sun_angle_max = 22.0
	sky.sky_material = sky_material
	environment.sky = sky
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "2026 Sunlight"
	sun.rotation_degrees = Vector3(-42, -34, 0) if timeline_year == 2026 else Vector3(-24, -120, 0)
	sun.light_color = Color("#ffe4b2") if timeline_year == 2026 else Color("#93a8b9")
	sun.light_energy = 0.68 if timeline_year == 2026 else 0.34
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 125.0
	add_child(sun)


func _build_ground_and_river() -> void:
	var grass_material := Palette.GRASS.duplicate() as StandardMaterial3D
	if timeline_year == 2046:
		grass_material.albedo_color = grass_material.albedo_color.lerp(Color("#596358"), 0.62)
	for bank_center_z in [-30.6, 30.6]:
		var ground := MeshInstance3D.new()
		ground.name = "Grassy Terrain"
		ground.mesh = _create_terrain_mesh(Vector2(100, 38.8), 20, bank_center_z)
		ground.material_override = grass_material
		ground.position = Vector3(0, 0, bank_center_z)
		add_child(ground)

		var ground_body := StaticBody3D.new()
		ground_body.name = "TerrainCollision"
		add_child(ground_body)
		var ground_shape := CollisionShape3D.new()
		var ground_box := BoxShape3D.new()
		ground_box.size = Vector3(100, 0.2, 38.8)
		ground_shape.shape = ground_box
		ground_shape.position = Vector3(0, -0.1, bank_center_z)
		ground_body.add_child(ground_shape)

	var river := MeshInstance3D.new()
	river.name = "Flowing Riverside"
	river.set_meta("location_id", "river.main")
	var river_mesh := BoxMesh.new()
	river_mesh.size = Vector3(100, 0.08, 21.8)
	river.mesh = river_mesh
	var water_material := Palette.WATER.duplicate() as ShaderMaterial
	if timeline_year == 2046:
		water_material.set_shader_parameter("deep_water_color", Color("#182b38"))
		water_material.set_shader_parameter("shallow_water_color", Color("#416978"))
	river.material_override = water_material
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
	var bank_side := signf(bank_z)
	var gravel := MeshInstance3D.new()
	gravel.name = "Pebbled river shore"
	var gravel_mesh := BoxMesh.new()
	gravel_mesh.size = Vector3(length, 0.08, 1.15)
	gravel.mesh = gravel_mesh
	gravel.material_override = Palette.SAND
	gravel.position = Vector3(center_x, 0.02, bank_z - bank_side * 0.38)
	add_child(gravel)

	var bank := MeshInstance3D.new()
	bank.name = "Stone river retaining edge"
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
	_add_cobble_overlay(Vector3(0, 0.11, -22), 6.0, 76.0, true)
	_add_cobble_overlay(Vector3(0, 0.11, 22), 6.0, 76.0, true)
	_add_cobble_overlay(Vector3(14, 0.11, -33.5), 6.0, 25.0, false)
	_add_cobble_overlay(Vector3(14, 0.11, 33.5), 6.0, 25.0, false)
	_add_cobble_overlay(Vector3(0, 0.11, -37), 5.0, 68.0, true)
	_add_cobble_overlay(Vector3(0, 0.11, 39), 5.0, 68.0, true)
	_add_path("Shelter Footpath", Vector3(2.2, 0.08, 10), Vector3(26, 0.02, -29))
	_add_path("Warning Tower Footpath", Vector3(10, 0.08, 2.2), Vector3(-28, 0.02, -34))
	_add_path("Town Square Road Link", Vector3(3.2, 0.08, 4.2), Vector3(0, 0.02, 23.8))

	for road_edge_z in [-25.0, -19.0, 19.0, 25.0]:
		_add_box_mesh(
			"Roadside stone edging",
			Vector3(76, 0.12, 0.22),
			Vector3(0, 0.045, road_edge_z),
			Palette.CONCRETE
		)



func _add_cobble_overlay(center: Vector3, width: float, length: float, horizontal: bool) -> void:
	var tile_length := 0.52
	var tile_width := 0.38
	var longitudinal_count := int(floor(length / tile_length))
	var lateral_count := int(ceil(width / tile_width))
	if longitudinal_count <= 0 or lateral_count <= 0:
		return

	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.use_colors = true
	var tile_mesh := BoxMesh.new()
	tile_mesh.size = Vector3(0.47, 0.022, 0.32)
	multi_mesh.mesh = tile_mesh
	multi_mesh.instance_count = longitudinal_count * lateral_count

	var colors: Array[Color] = [
		Color("#555750"), Color("#626158"), Color("#5c6058"), Color("#68665d")
	]
	var instance_index := 0
	for longitudinal_index in range(longitudinal_count):
		for lateral_index in range(lateral_count):
			var along := (float(longitudinal_index) - float(longitudinal_count - 1) * 0.5) * tile_length
			var across := (float(lateral_index) - float(lateral_count - 1) * 0.5) * tile_width
			along += tile_length * 0.5 if lateral_index % 2 == 1 else 0.0
			var jitter := float((instance_index * 17) % 7 - 3) * 0.018
			along += jitter
			across -= jitter * 0.7
			var tile_position := Vector3(center.x + along, center.y, center.z + across)
			if not horizontal:
				tile_position = Vector3(center.x + across, center.y, center.z + along)
			var yaw := 0.0 if horizontal else PI * 0.5
			yaw += float((instance_index * 7) % 5 - 2) * 0.035
			multi_mesh.set_instance_transform(
				instance_index,
				Transform3D(Basis(Vector3.UP, yaw), tile_position)
			)
			multi_mesh.set_instance_color(instance_index, colors[instance_index % colors.size()])
			instance_index += 1

	var pavers := MultiMeshInstance3D.new()
	pavers.name = "Hand-set cobblestone roadway"
	pavers.multimesh = multi_mesh
	var paver_material := Palette.PAVER.duplicate() as StandardMaterial3D
	if timeline_year == 2046:
		paver_material.albedo_color = paver_material.albedo_color.darkened(0.35)
	pavers.material_override = paver_material
	pavers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pavers)


func _add_road(road_name: String, size: Vector3, road_position: Vector3) -> void:
	var road_material := Palette.ROAD.duplicate() as StandardMaterial3D
	if timeline_year == 2046:
		road_material.albedo_color = road_material.albedo_color.darkened(0.42)
	_add_box_mesh(road_name, size, road_position, road_material)


func _add_path(path_name: String, size: Vector3, path_position: Vector3) -> void:
	var path_material := Palette.SAND.duplicate() as StandardMaterial3D
	if timeline_year == 2046:
		path_material.albedo_color = path_material.albedo_color.darkened(0.3)
	_add_box_mesh(path_name, size, path_position, path_material)


func _build_houses() -> void:
	var houses: Array[Dictionary] = [
		{"id": "house.northwest", "wall": Color("#d6b87f"), "roof": Color("#a34f36"), "rotation": PI},
		{"id": "house.northwest_2", "wall": Color("#d9c6a0"), "roof": Color("#526c72"), "rotation": PI},
		{"id": "town.general_store", "wall": Color("#c58e66"), "roof": Color("#9b4935"), "rotation": PI, "type": "shop"},
		{"id": "house.north_east", "wall": Color("#c6d0b1"), "roof": Color("#4c6860"), "rotation": PI},
		{"id": "house.southwest", "wall": Color("#d9c6a0"), "roof": Color("#a34f36"), "rotation": PI},
		{"id": "house.southwest_2", "wall": Color("#d6b87f"), "roof": Color("#526c72"), "rotation": PI},
		{"id": "house.southeast", "wall": Color("#c58e66"), "roof": Color("#8d4737"), "rotation": PI},
	]
	for house_data in houses:
		var house := HOUSE_SCENE.instantiate() as Node3D
		house.set("wall_color", house_data["wall"])
		house.set("roof_color", house_data["roof"])
		house.set("future_damaged", timeline_year == 2046)
		var location_id := str(house_data["id"])
		house.set("location_id", location_id)
		house.set_meta("location_id", location_id)
		if house_data.get("type", "cottage") == "shop":
			house.set("building_type", "shop")
			house.set("shop_name", "WILLOWBROOK MARKET")
			house.set("awning_color", Color("#b85d48"))
		house.position = TownLocations.LOCATIONS[location_id]
		house.rotation.y = float(house_data["rotation"])
		add_child(house)


func _build_town_square() -> void:
	var square_position: Vector3 = TownLocations.LOCATIONS["town.square"]
	var plaza := MeshInstance3D.new()
	plaza.name = "Willowbrook Town Square"
	plaza.set_meta("location_id", "town.square")
	var plaza_mesh := BoxMesh.new()
	plaza_mesh.size = Vector3(20.0, 0.08, 14.0)
	plaza.mesh = plaza_mesh
	plaza.material_override = Palette.FOUNDATION
	plaza.position = square_position + Vector3(0.0, 0.02, 0.0)
	add_child(plaza)
	_add_cobble_overlay(square_position + Vector3(0.0, 0.08, 0.0), 14.0, 20.0, true)

	var fountain := FOUNTAIN_SCENE.instantiate() as Node3D
	fountain.position = TownLocations.LOCATIONS["town.fountain"]
	add_child(fountain)
	var clock_tower := CLOCK_TOWER_SCENE.instantiate() as Node3D
	clock_tower.position = TownLocations.LOCATIONS["town.clock_tower"]
	add_child(clock_tower)

	var flower_positions: Array[Vector3] = [
		Vector3(-7.4, 0.0, 27.1), Vector3(7.4, 0.0, 27.1),
		Vector3(-7.4, 0.0, 37.0), Vector3(7.4, 0.0, 37.0),
	]
	for index in range(flower_positions.size()):
		var flower_bed := FLOWER_BED_SCENE.instantiate() as Node3D
		flower_bed.position = flower_positions[index]
		flower_bed.set("flower_tint", Color("#d98975") if index % 2 == 0 else Color("#e6bc62"))
		add_child(flower_bed)


func _build_trees() -> void:
	var positions: Array[Vector3] = [
		Vector3(-46, 0, -41), Vector3(-43, 0, -25), Vector3(-27, 0, -43),
		Vector3(-8, 0, -45), Vector3(8, 0, -43), Vector3(43, 0, -42),
		Vector3(45, 0, -26), Vector3(-46, 0, 28), Vector3(-41, 0, 43),
		Vector3(-24, 0, 31), Vector3(-8, 0, 44), Vector3(10, 0, 45),
		Vector3(27, 0, 30), Vector3(44, 0, 31), Vector3(43, 0, 44),
		Vector3(31, 0, -44), Vector3(-45, 0, 5), Vector3(46, 0, 7),
	]
	for index in range(positions.size()):
		var tree := TREE_SCENE.instantiate() as Node3D
		tree.position = positions[index]
		tree.scale = Vector3.ONE * (0.78 + float(index % 4) * 0.12)
		tree.set(
			"crown_color",
			Color("#435847") if timeline_year == 2046 else (Color("#3d6b3a") if index % 2 == 0 else Color("#487544"))
		)
		add_child(tree)


func _build_streetlights() -> void:
	for position in [
		Vector3(-28, 0, -22), Vector3(-8, 0, -22), Vector3(31, 0, -22),
		Vector3(-28, 0, 22), Vector3(-8, 0, 22), Vector3(31, 0, 22),
	]:
		var light := STREETLIGHT_SCENE.instantiate() as Node3D
		light.position = position
		add_child(light)


func _build_environment_details() -> void:
	_build_bushes()
	_build_river_rocks()
	_build_river_reeds()
	_build_benches()
	_build_signs()
	_build_fences()


func _build_essential_locations() -> void:
	_spawn_facility(
		"town.archives", "Town Archives",
		"Town records and construction plans are stored here.", "archives",
		Color("#c7b28d"), Color("#5d6465")
	)
	_spawn_facility(
		"town.workshop", "Maintenance Workshop",
		"Tools, spare parts and equipment for Willowbrook's public works.", "workshop",
		Color("#b88f6d"), Color("#5c534c")
	)
	if not create_interactive_structures:
		_spawn_facility(
			"town.construction_site", "Construction Site",
			"An unfinished community construction site.", "construction",
			Color("#c6ae7f"), Color("#72553f")
		)
	_spawn_facility(
		"town.electrical_station", "Electrical Station",
		"Willowbrook's electrical distribution and control facility.", "electrical",
		Color("#afb5ae"), Color("#4f5d65")
	)
	_spawn_facility(
		"town.maintenance_facility", "River Maintenance Facility",
		"Equipment and access for maintaining river infrastructure.", "maintenance",
		Color("#b4a58c"), Color("#596166")
	)
	_spawn_facility(
		"drainage.tunnel_entrance", "Drainage Tunnel Entrance",
		"A maintenance entrance to Willowbrook's storm-water drainage tunnels.", "tunnel",
		Color("#919993"), Color("#414a4d")
	)


func _spawn_facility(
	location_id: String,
	facility_name: String,
	description: String,
	facility_type: String,
	wall_color: Color,
	roof_color: Color
) -> void:
	var facility := TOWN_FACILITY_SCENE.instantiate() as Node3D
	facility.set("location_id", location_id)
	facility.set("facility_name", facility_name)
	facility.set("description", description)
	facility.set("facility_type", facility_type)
	facility.set("wall_color", wall_color)
	facility.set("roof_color", roof_color)
	facility.set("future_damaged", timeline_year == 2046)
	facility.set("interaction_enabled", not visual_only)
	facility.position = TownLocations.LOCATIONS[location_id]
	add_child(facility)


func _strip_collision_objects() -> void:
	for node in find_children("*", "CollisionObject3D", true, false):
		var collision_object := node as CollisionObject3D
		collision_object.remove_from_group("adventure_interactable")
		collision_object.queue_free()


func _build_geographic_structures() -> void:
	var dam_position: Vector3 = TownLocations.LOCATIONS["river.dam"]
	_add_box_mesh(
		"Willowbrook Dam",
		Vector3(2.4, 4.5, 27.0),
		dam_position + Vector3(0, 2.0, 0),
		Palette.CONCRETE
	)
	var dam_collision := StaticBody3D.new()
	dam_collision.name = "DamCollision"
	dam_collision.position = dam_position + Vector3(0, 2.0, 0)
	add_child(dam_collision)
	var dam_shape := CollisionShape3D.new()
	var dam_box := BoxShape3D.new()
	dam_box.size = Vector3(2.4, 4.5, 27.0)
	dam_shape.shape = dam_box
	dam_collision.add_child(dam_shape)
	for z in [-10.0, -5.0, 0.0, 5.0, 10.0]:
		_add_box_mesh(
			"Dam crest buttress",
			Vector3(2.8, 0.24, 0.52),
			dam_position + Vector3(0, 4.32, z),
			Palette.FOUNDATION
		)
	var bridge_position: Vector3 = TownLocations.LOCATIONS["river.bridge"]
	_add_box_mesh(
		"Walkable Bridge Deck",
		Vector3(9.0, 0.48, 27.0),
		bridge_position + Vector3(0, 0.0, 0),
		Palette.WOOD if timeline_year == 2026 else Palette.CONCRETE
	)
	var bridge_collision := StaticBody3D.new()
	bridge_collision.name = "BridgeCollision"
	bridge_collision.position = bridge_position
	add_child(bridge_collision)
	var bridge_shape := CollisionShape3D.new()
	var bridge_box := BoxShape3D.new()
	bridge_box.size = Vector3(9.0, 0.48, 27.0)
	bridge_shape.shape = bridge_box
	bridge_shape.position.y = -0.02
	bridge_collision.add_child(bridge_shape)
	for x in [-4.25, 4.25]:
		_add_box_mesh(
			"Bridge railing",
			Vector3(0.2, 1.05, 27.0),
			bridge_position + Vector3(x, 0.7, 0),
			Palette.WOOD if timeline_year == 2026 else Palette.METAL
		)
	if timeline_year == 2046:
		_add_box_mesh(
			"Bridge damaged deck plate",
			Vector3(2.3, 0.08, 1.3),
			bridge_position + Vector3(3.0, 0.29, -4.0),
			Palette.ROOF
		)


func _build_future_flood_effects() -> void:
	var water_material := Palette.WATER.duplicate() as ShaderMaterial
	water_material.set_shader_parameter("deep_water_color", Color("#203743"))
	water_material.set_shader_parameter("shallow_water_color", Color("#557982"))
	var floodgate_configured := AdventureState.has_world_flag("floodgate.configured")
	var drainage_open := AdventureState.has_world_flag("drainage.valve_open") or floodgate_configured
	var water_level_stage := 0
	for flag_id in ["water.level.lower", "water.level.bypass", "water.level.release"]:
		if not AdventureState.has_world_flag(flag_id):
			break
		water_level_stage += 1
	var flood_sections: Array[Dictionary] = []
	if not drainage_open:
		var water_height := 0.09 - 0.02 * float(water_level_stage)
		flood_sections.append_array([
			{"size": Vector3(76.0, 0.035, 2.6), "position": Vector3(0.0, water_height, 22.0)},
			{"size": Vector3(76.0, 0.035, 2.2), "position": Vector3(0.0, water_height, -22.0)},
		])
		if water_level_stage == 0:
			flood_sections.append_array([
				{"size": Vector3(3.4, 0.035, 8.0), "position": Vector3(23.0, water_height, -33.0)},
				{"size": Vector3(4.0, 0.035, 7.0), "position": Vector3(-24.0, water_height, 34.0)},
			])
		elif water_level_stage == 1:
			flood_sections.append({
				"size": Vector3(3.4, 0.035, 8.0),
				"position": Vector3(23.0, water_height, -33.0),
			})
	for section in flood_sections:
		var flood_pool := MeshInstance3D.new()
		flood_pool.name = "Shallow floodwater across street"
		var pool_mesh := BoxMesh.new()
		pool_mesh.size = section["size"]
		flood_pool.mesh = pool_mesh
		flood_pool.position = section["position"]
		flood_pool.material_override = water_material
		flood_pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(flood_pool)
	for debris_position in [
		Vector3(-10.0, 0.0, -18.0), Vector3(27.0, 0.0, 20.0),
		Vector3(-30.0, 0.0, 19.0), Vector3(31.0, 0.0, 42.0),
	]:
		_add_box_mesh(
			"Flood debris",
			Vector3(1.7, 0.55, 0.85),
			debris_position + Vector3(0, 0.28, 0),
			Palette.WOOD
		)
	if visual_only:
		return
	var rain := GPUParticles3D.new()
	rain.name = "Willowbrook Rain"
	rain.amount = 420
	rain.lifetime = 1.5
	rain.position.y = 22.0
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(42.0, 0.0, 42.0)
	process_material.direction = Vector3(0.02, -1.0, 0.0)
	process_material.spread = 4.0
	process_material.initial_velocity_min = 18.0
	process_material.initial_velocity_max = 26.0
	process_material.gravity = Vector3(0.0, -8.0, 0.0)
	rain.process_material = process_material
	var rain_mesh := QuadMesh.new()
	rain_mesh.size = Vector2(0.035, 0.7)
	var rain_material := StandardMaterial3D.new()
	rain_material.albedo_color = Color("#a9c5d0", 0.5)
	rain_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain_mesh.material = rain_material
	rain.draw_pass_1 = rain_mesh
	add_child(rain)
	if drainage_open:
		_add_box_mesh(
			"Drained tunnel approach",
			Vector3(3.2, 0.04, 5.0),
			TownLocations.LOCATIONS["drainage.tunnel_entrance"] + Vector3(0, 0.06, 3.0),
			Palette.FOUNDATION
		)
	if floodgate_configured:
		_add_box_mesh(
			"Restored floodgate spillway",
			Vector3(1.0, 1.8, 8.0),
			TownLocations.LOCATIONS["river.dam"] + Vector3(1.8, 1.5, 0),
			Palette.CONCRETE
		)


func _build_persistent_mission_geometry() -> void:
	var dam_position: Vector3 = TownLocations.LOCATIONS["river.dam"]
	var crate_position := dam_position + Vector3(5.0, 0.45, -4.0)
	if not photograph_baseline and AdventureState.has_world_flag("photo.crate_moved"):
		crate_position += Vector3(3.0, 0.0, 0.0)
	_add_mission_static_box(
		"Photograph clue crate",
		Vector3(1.1, 0.9, 0.9),
		crate_position,
		Palette.WOOD
	)
	var barrier_position := dam_position + Vector3(5.0, 0.5, 4.0)
	if not photograph_baseline and AdventureState.has_world_flag("photo.barrier_moved"):
		barrier_position += Vector3(0.0, 0.0, 4.0)
	_add_mission_static_box(
		"Photograph clue service barrier",
		Vector3(2.6, 1.0, 0.28),
		barrier_position,
		Palette.FOUNDATION
	)
	if (
		not photograph_baseline
		and AdventureState.has_world_flag("photo.crate_moved")
		and AdventureState.has_world_flag("photo.barrier_moved")
	):
		_add_box_mesh(
			"Revealed maintenance access marker",
			Vector3(0.32, 1.3, 0.32),
			dam_position + Vector3(5.0, 0.65, 0.0),
			Palette.METAL
		)
	_build_hidden_room()
	_build_pump_and_time_capsule()
	_build_preserved_supplies()
	if timeline_year == 2046:
		if AdventureState.has_world_flag("electrical.power_routed"):
			for light_offset in [Vector3(-1.5, 2.2, -5.8), Vector3(1.5, 2.2, -5.8)]:
				var station_light := OmniLight3D.new()
				station_light.name = "Restored Emergency Light"
				station_light.position = TownLocations.LOCATIONS["town.electrical_station"] + light_offset
				station_light.light_color = Color("#d3edc1")
				station_light.light_energy = 0.7
				station_light.omni_range = 6.0
				station_light.shadow_enabled = false
				add_child(station_light)
		else:
			var pattern_colors: Array[Color] = [
				Color("#5fcde0"), Color("#e7b369"), Color("#f0eee3")
			]
			for index in range(pattern_colors.size()):
				var station_light := OmniLight3D.new()
				station_light.name = "Emergency Pattern Light %d" % (index + 1)
				station_light.position = TownLocations.LOCATIONS["town.electrical_station"] + Vector3(
					(float(index) - 1.0) * 1.6, 2.2, -5.8
				)
				station_light.light_color = pattern_colors[index]
				station_light.light_energy = 0.03
				station_light.omni_range = 6.0
				station_light.shadow_enabled = false
				add_child(station_light)
				_electrical_pattern_lights.append(station_light)

	var shelter_position: Vector3 = TownLocations.LOCATIONS["town.shelter_site"]
	var walkway_segments: Array[Dictionary] = [
		{"flag": "blueprint.left", "position": shelter_position + Vector3(-2.0, 0.16, 2.0)},
		{"flag": "blueprint.right", "position": shelter_position + Vector3(0.0, 0.16, 0.0)},
		{"flag": "blueprint.deck", "position": shelter_position + Vector3(2.0, 0.16, -2.0)}
	]
	for segment in walkway_segments:
		if not AdventureState.has_world_flag(str(segment["flag"])):
			continue
		_add_box_mesh("Assembled shelter footbridge", Vector3(2.6, 0.28, 2.6), segment["position"], Palette.WOOD)
		if not visual_only:
			var body := StaticBody3D.new()
			body.name = "AssembledFootbridgeCollision_%s" % str(segment["flag"]).get_slice(".", 1)
			body.position = segment["position"]
			add_child(body)
			var collision := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(2.6, 0.34, 2.6)
			collision.shape = box
			body.add_child(collision)
	_build_cement_writing_surface()


func _build_cement_writing_surface() -> void:
	var surface_center: Vector3 = TownLocations.LOCATIONS["town.construction_site"] + Vector3(-5.0, 0.0, 2.0)
	var cement_material := StandardMaterial3D.new()
	cement_material.albedo_color = Color("#77766d") if timeline_year == 2046 else Color("#4c5550")
	cement_material.roughness = 0.96
	_add_mission_static_box(
		"Wet Cement Message Slab",
		Vector3(4.6, 0.16, 3.0),
		surface_center + Vector3(0, 0.08, 0),
		cement_material
	)
	for message in AdventureState.get_state().get("cement_messages", []):
		var strokes: Array = message.get("strokes", [])
		for stroke in strokes:
			if stroke.size() < 2:
				continue
			for point_index in range(stroke.size() - 1):
				var start: Array = stroke[point_index]
				var finish: Array = stroke[point_index + 1]
				var start_point := surface_center + Vector3(
					(float(start[0]) - 0.5) * 4.2,
					0.19,
					(float(start[1]) - 0.5) * 2.6
				)
				var end_point := surface_center + Vector3(
					(float(finish[0]) - 0.5) * 4.2,
					0.19,
					(float(finish[1]) - 0.5) * 2.6
				)
				var delta := end_point - start_point
				if delta.length_squared() < 0.0001:
					continue
				var stroke_mesh := MeshInstance3D.new()
				stroke_mesh.name = "Preserved cement stroke"
				var segment_mesh := BoxMesh.new()
				segment_mesh.size = Vector3(delta.length(), 0.045, 0.075)
				stroke_mesh.mesh = segment_mesh
				stroke_mesh.position = (start_point + end_point) * 0.5
				stroke_mesh.rotation.y = atan2(-delta.z, delta.x)
				var stroke_material := StandardMaterial3D.new()
				stroke_material.albedo_color = Color("#b2ad91") if timeline_year == 2046 else Color("#262f2b")
				stroke_material.roughness = 1.0
				stroke_mesh.material_override = stroke_material
				add_child(stroke_mesh)


func _build_hidden_room() -> void:
	var center: Vector3 = TownLocations.LOCATIONS["town.workshop"] + Vector3(7.0, 0.0, 8.0)
	var stone_material: Material = Palette.CONCRETE if timeline_year == 2046 else Palette.FOUNDATION
	_add_mission_static_box("Hidden Room Floor", Vector3(8.0, 0.2, 7.0), center + Vector3(0, 0.0, 0), Palette.FOUNDATION)
	_add_mission_static_box("Hidden Room Left Wall", Vector3(0.3, 3.2, 7.0), center + Vector3(-4.0, 1.6, 0), stone_material)
	_add_mission_static_box("Hidden Room Right Wall", Vector3(0.3, 3.2, 7.0), center + Vector3(4.0, 1.6, 0), stone_material)
	_add_mission_static_box("Hidden Room Rear Wall", Vector3(8.0, 3.2, 0.3), center + Vector3(0, 1.6, -3.5), stone_material)
	_add_mission_static_box("Hidden Room Front Left Wall", Vector3(2.6, 3.2, 0.3), center + Vector3(-2.7, 1.6, 3.5), stone_material)
	_add_mission_static_box("Hidden Room Front Right Wall", Vector3(2.6, 3.2, 0.3), center + Vector3(2.7, 1.6, 3.5), stone_material)
	if not AdventureState.has_world_flag("room.wall_moved"):
		_add_mission_static_box("Blocking Wall Module", Vector3(2.6, 3.0, 0.4), center + Vector3(0, 1.5, 3.5), Palette.CONCRETE)
	else:
		_add_box_mesh("Revealed Room Door Frame", Vector3(2.8, 0.2, 0.5), center + Vector3(0, 2.9, 3.5), Palette.WOOD)
		var paper_material := StandardMaterial3D.new()
		paper_material.albedo_color = Color("#d9c99f")
		_add_box_mesh("Recovered Room Interior Record", Vector3(0.7, 0.12, 0.45), center + Vector3(1.5, 0.35, -1.0), paper_material)


func _build_pump_and_time_capsule() -> void:
	var station_position: Vector3 = TownLocations.LOCATIONS["town.electrical_station"] + Vector3(-3.0, 0.0, 0.0)
	_add_box_mesh("Pump Housing", Vector3(2.0, 0.9, 1.3), station_position + Vector3(0, 0.55, 0), Palette.METAL)
	var repaired := AdventureState.has_world_flag("machine.repaired")
	var capacitor_present := (timeline_year == 2026 and not AdventureState.has_world_flag("capsule.capacitor_sent")) or (timeline_year == 2046 and repaired)
	var copper_material := StandardMaterial3D.new()
	copper_material.albedo_color = Color("#b8784e")
	copper_material.metallic = 0.62
	var socket_material := StandardMaterial3D.new()
	socket_material.albedo_color = Color("#53b8c5") if capacitor_present else Color("#bc6b52")
	socket_material.emission_enabled = true
	socket_material.emission = socket_material.albedo_color
	socket_material.emission_energy_multiplier = 0.25
	_add_box_mesh("Pump Capacitor Socket", Vector3(0.68, 0.12, 0.62), station_position + Vector3(0, 1.04, 0), socket_material)
	if capacitor_present:
		_add_box_mesh("Pump Capacitor", Vector3(0.42, 0.65, 0.42), station_position + Vector3(0, 1.4, 0), copper_material)
	for index in range(3):
		var wire_material := StandardMaterial3D.new()
		wire_material.albedo_color = [Color("#58c3d5"), Color("#e5b35f"), Color("#d6d3c4")][index]
		_add_box_mesh(
			"Pump Configuration Conductor %d" % (index + 1),
			Vector3(0.1, 0.12, 0.72),
			station_position + Vector3((float(index) - 1.0) * 0.26, 0.88, 0.7),
			wire_material
		)
	var socket_label := Label3D.new()
	socket_label.name = "Pump Capacitor Socket Label"
	socket_label.text = "CAPACITOR SLOT  %s" % ("SEALED" if repaired else ("READY" if capacitor_present else "EMPTY"))
	socket_label.font_size = 18
	socket_label.pixel_size = 0.008
	socket_label.position = station_position + Vector3(0, 1.9, 0.65)
	socket_label.modulate = Color("#8bd6d0") if capacitor_present else Color("#e49b7b")
	socket_label.outline_size = 3
	socket_label.outline_modulate = Color("#172128")
	add_child(socket_label)
	var status_material := StandardMaterial3D.new()
	status_material.albedo_color = Color("#72d8a4") if repaired else Color("#dc8963")
	status_material.emission_enabled = true
	status_material.emission = status_material.albedo_color
	status_material.emission_energy_multiplier = 0.55
	_add_box_mesh("Pump Status Lamp", Vector3(0.16, 0.16, 0.16), station_position + Vector3(0, 1.0, 0.72), status_material)

	var capsule_position: Vector3 = TownLocations.LOCATIONS["town.workshop"] + Vector3(-3.0, 0.0, 4.0)
	if AdventureState.has_world_flag("capsule.capacitor_sent"):
		var mound_material := StandardMaterial3D.new()
		mound_material.albedo_color = Color("#716755") if timeline_year == 2046 else Color("#795f42")
		var mound := MeshInstance3D.new()
		mound.name = "Buried Time Capsule Marker"
		var mound_mesh := SphereMesh.new()
		mound_mesh.radius = 0.85
		mound_mesh.height = 0.42
		mound_mesh.radial_segments = 8
		mound_mesh.rings = 4
		mound.mesh = mound_mesh
		mound.scale = Vector3(1.4, 0.45, 1.1)
		mound.position = capsule_position + Vector3(0, 0.14, 0)
		mound.material_override = mound_material
		add_child(mound)
		_add_box_mesh("Time Capsule Access Plate", Vector3(0.48, 0.09, 0.42), capsule_position + Vector3(0, 0.28, 0), Palette.METAL)
	else:
		_add_box_mesh("Waterproof Time Capsule", Vector3(1.0, 0.65, 0.75), capsule_position + Vector3(0, 0.35, 0), Palette.METAL)


func _build_preserved_supplies() -> void:
	var store_position: Vector3 = TownLocations.LOCATIONS["town.general_store"] + Vector3(5.0, 0.0, 3.0)
	if timeline_year == 2026 and not AdventureState.has_world_flag("npc.supplies_relocated"):
		_add_box_mesh("Emergency Supplies on Shop Floor", Vector3(1.3, 0.8, 0.9), store_position + Vector3(0, 0.4, 0), Palette.WOOD)
		return
	if AdventureState.has_world_flag("npc.supplies_relocated") and not AdventureState.has_world_flag("npc.supplies_retrieved"):
		_add_box_mesh("Preserved Emergency Supplies", Vector3(1.3, 0.8, 0.9), store_position + Vector3(0, 1.65, 0), Palette.WOOD)
	elif timeline_year == 2046 and AdventureState.has_world_flag("npc.supplies_declined"):
		_add_box_mesh("Flood-Damaged Emergency Supplies", Vector3(1.3, 0.32, 0.9), store_position + Vector3(0, 0.18, 0), Palette.CONCRETE)
		var consequence_label := Label3D.new()
		consequence_label.text = "LOST BELOW THE FLOOD LINE"
		consequence_label.font_size = 16
		consequence_label.pixel_size = 0.008
		consequence_label.position = store_position + Vector3(0, 1.2, 0)
		consequence_label.modulate = Color("#d5a27e")
		consequence_label.outline_size = 3
		consequence_label.outline_modulate = Color("#172128")
		add_child(consequence_label)


func _build_shopkeeper() -> void:
	if timeline_year != 2026:
		return
	var npc := Node3D.new()
	npc.name = "Willowbrook Shopkeeper"
	npc.position = TownLocations.LOCATIONS["town.general_store"] + Vector3(1.8, 0.0, 1.2)
	add_child(npc)
	var tunic := StandardMaterial3D.new()
	tunic.albedo_color = Color("#7d6250")
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("#d8ae89")
	var hair := StandardMaterial3D.new()
	hair.albedo_color = Color("#4c3d35")
	_add_box_to(npc, "Shopkeeper Tunic", Vector3(0.75, 1.05, 0.42), Vector3(0, 1.0, 0), tunic)
	_add_box_to(npc, "Shopkeeper Head", Vector3(0.42, 0.5, 0.42), Vector3(0, 1.82, 0), skin)
	_add_box_to(npc, "Shopkeeper Hair", Vector3(0.46, 0.16, 0.46), Vector3(0, 2.12, 0), hair)
	for side in [-1.0, 1.0]:
		_add_box_to(npc, "Shopkeeper Arm", Vector3(0.22, 0.8, 0.28), Vector3(side * 0.48, 1.0, 0), skin)


func _add_mission_static_box(
	mesh_name: String,
	box_size: Vector3,
	mesh_position: Vector3,
	material: Material
) -> void:
	_add_box_mesh(mesh_name, box_size, mesh_position, material)
	if visual_only:
		return
	var body := StaticBody3D.new()
	body.name = "%s Collision" % mesh_name
	body.position = mesh_position
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)


func _build_bushes() -> void:
	var bush_positions: Array[Vector3] = [
		Vector3(-43, 0.55, -29), Vector3(-31, 0.5, -39), Vector3(-20, 0.55, -29),
		Vector3(7, 0.55, -39), Vector3(42, 0.5, -29), Vector3(-41, 0.55, 37),
		Vector3(-23, 0.5, 39), Vector3(-2, 0.5, 42), Vector3(29, 0.55, 38),
		Vector3(43, 0.5, 40), Vector3(-8, 0.45, 28), Vector3(31, 0.45, -25),
	]
	for index in range(bush_positions.size()):
		var bush := MeshInstance3D.new()
		bush.name = "Low Poly Bush"
		var mesh := SphereMesh.new()
		mesh.radius = 1.0
		mesh.height = 1.2
		mesh.radial_segments = 6
		mesh.rings = 4
		bush.mesh = mesh
		bush.position = bush_positions[index]
		bush.scale = Vector3(1.0 + float(index % 3) * 0.22, 0.75, 0.85 + float(index % 2) * 0.2)
		var material := StandardMaterial3D.new()
		material.albedo_color = (
			Color("#555b4d") if timeline_year == 2046 else (Color("#596f4d") if index % 2 == 0 else Color("#667953"))
		)
		material.roughness = 1.0
		bush.material_override = material
		add_child(bush)


func _build_river_rocks() -> void:
	for side in [-1.0, 1.0]:
		for x in [-43.0, -37.0, -31.0, -12.0, -6.0, 1.0, 24.0, 30.0, 38.0, 44.0]:
			var rock_size := 0.48 + float(int(absf(x)) % 3) * 0.12
			var rock := MeshInstance3D.new()
			rock.name = "Riverside Stone"
			var stone := SphereMesh.new()
			stone.radius = 0.6
			stone.height = 0.8
			stone.radial_segments = 6
			stone.rings = 3
			rock.mesh = stone
			rock.position = Vector3(x, 0.12, 11.6 * side)
			rock.scale = Vector3(rock_size, rock_size * 0.72, rock_size * 1.15)
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("#666b5c") if int(absf(x)) % 2 == 0 else Color("#777564")
			material.roughness = 1.0
			rock.material_override = material
			add_child(rock)

			var body := StaticBody3D.new()
			body.name = "StoneCollision"
			body.position = rock.position
			add_child(body)
			var collision := CollisionShape3D.new()
			var sphere := SphereShape3D.new()
			sphere.radius = rock_size * 0.55
			collision.shape = sphere
			body.add_child(collision)


func _build_river_reeds() -> void:
	for side in [-1.0, 1.0]:
		for x in [-42.0, -36.0, -29.0, -12.0, -7.0, 25.0, 32.0, 40.0]:
			if x > 9.0 and x < 19.0:
				continue
			var clump := Node3D.new()
			clump.name = "River reed clump"
			clump.position = Vector3(x, 0.0, side * 10.45)
			add_child(clump)
			for blade_index in range(3):
				var blade := MeshInstance3D.new()
				blade.name = "Reed blade"
				var mesh := CylinderMesh.new()
				mesh.top_radius = 0.025
				mesh.bottom_radius = 0.075
				mesh.height = 0.72 + float(blade_index % 2) * 0.18
				mesh.radial_segments = 4
				blade.mesh = mesh
				blade.material_override = Palette.LEAVES
				blade.position = Vector3(
					float(blade_index - 1) * 0.16,
					mesh.height * 0.5,
					float(blade_index % 2) * 0.1
				)
				blade.rotation.z = float(blade_index - 1) * 0.14
				clump.add_child(blade)


func _build_benches() -> void:
	for bench_position in [Vector3(-4, 0, 29), Vector3(23, 0, 24)]:
		var bench := Node3D.new()
		bench.name = "Town Bench"
		bench.position = bench_position
		add_child(bench)
		_add_box_to(bench, "Seat", Vector3(2.2, 0.18, 0.62), Vector3(0, 0.62, 0), Palette.WOOD)
		_add_box_to(bench, "Backrest", Vector3(2.2, 0.72, 0.16), Vector3(0, 1.04, 0.24), Palette.WOOD)
		_add_box_to(bench, "Seat front rail", Vector3(2.0, 0.12, 0.12), Vector3(0, 0.48, -0.24), Palette.FOUNDATION)
		for x in [-0.82, 0.82]:
			_add_box_to(bench, "Bench leg", Vector3(0.16, 0.62, 0.52), Vector3(x, 0.32, 0), Palette.METAL)
			_add_box_to(bench, "Bench armrest", Vector3(0.16, 0.14, 0.75), Vector3(x, 0.92, 0.04), Palette.WOOD)
		var body := StaticBody3D.new()
		body.name = "BenchCollision"
		bench.add_child(body)
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.3, 1.15, 0.75)
		collision.shape = box
		collision.position.y = 0.58
		body.add_child(collision)


func _build_signs() -> void:
	_add_sign(Vector3(19.0, 0, -22.0), "RIVER CROSSING", "BRIDGE AHEAD")
	_add_sign(Vector3(21.0, 0, -29.0), "COMMUNITY", "SHELTER")


func _add_sign(sign_position: Vector3, top_text: String, bottom_text: String) -> void:
	var sign := Node3D.new()
	sign.name = "Town Wayfinding Sign"
	sign.position = sign_position
	add_child(sign)
	_add_cylinder_to(sign, "Sign Post", 0.1, 2.5, Vector3(0, 1.25, 0), Palette.WOOD)
	_add_box_to(sign, "Sign Board", Vector3(2.2, 1.0, 0.18), Vector3(0, 2.1, 0), Palette.FOUNDATION)
	var label := Label3D.new()
	label.name = "Sign Lettering"
	label.text = "%s\n%s" % [top_text, bottom_text]
	label.font_size = 24
	label.pixel_size = 0.008
	label.position = Vector3(0, 2.1, -0.105)
	label.modulate = Color("#e5d7b6")
	label.outline_size = 4
	sign.add_child(label)


func _build_fences() -> void:
	for index in range(7):
		var x := 20.0 + float(index) * 1.8
		_add_box_mesh("Shelter fence post", Vector3(0.16, 1.0, 0.16), Vector3(x, 0.5, -42), Palette.WOOD)
	for rail_y in [0.35, 0.78]:
		_add_box_mesh("Shelter fence rail", Vector3(11.0, 0.12, 0.12), Vector3(25.4, rail_y, -42), Palette.WOOD)


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
		material.albedo_color = Color("#42594b") if index % 2 == 0 else Color("#4c6252")
		material.roughness = 1.0
		mountain.material_override = material
		mountain.position = mountain_positions[index] + Vector3(0, height * 0.5 - 1.0, 0)
		add_child(mountain)
		if index % 3 == 0:
			var snow_cap := MeshInstance3D.new()
			snow_cap.name = "Snow-capped distant peak"
			var snow_mesh := CylinderMesh.new()
			snow_mesh.top_radius = 0.0
			snow_mesh.bottom_radius = 4.2 + float(index % 2) * 0.8
			snow_mesh.height = 5.2
			snow_mesh.radial_segments = 6
			snow_cap.mesh = snow_mesh
			var snow_material := StandardMaterial3D.new()
			snow_material.albedo_color = Color("#d9ded2")
			snow_material.roughness = 1.0
			snow_cap.material_override = snow_material
			snow_cap.position = mountain.position + Vector3(0.0, height * 0.5 - 2.45, 0.0)
			add_child(snow_cap)
		var ridge := MeshInstance3D.new()
		ridge.name = "Distant Rolling Ridge"
		var hill := SphereMesh.new()
		hill.radius = 1.0
		hill.height = 2.0
		hill.radial_segments = 7
		hill.rings = 4
		ridge.mesh = hill
		ridge.scale = Vector3(19.0, 7.0 + float(index % 3) * 1.5, 13.0)
		ridge.position = mountain_positions[index] + Vector3(0, 4.0, -4.0)
		var ridge_material := StandardMaterial3D.new()
		ridge_material.albedo_color = Color("#455b4d") if index % 2 == 0 else Color("#506454")
		ridge_material.roughness = 1.0
		ridge.material_override = ridge_material
		add_child(ridge)


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
		"Seal the spillway and reinforce the wall with steel braces.", 14.5
	)
	_spawn_structure(
		"bridge", "Bridge", "strengthen_bridge", 20, "Damaged deck",
		"Loose deck sections could make the only safe river crossing unreliable.",
		"Replace damaged deck panels and add protective railings.", 9.0
	)
	_spawn_structure(
		"drainage", "Drainage System", "improve_drainage", 15, "Partly blocked",
		"Debris in the storm drain may leave the low streets under water.",
		"Clear the drain and install a reinforced outlet pipe.", 7.5
	)
	_spawn_structure(
		"shelter", "Emergency Shelter Site", "build_shelter", 20, "Construction site",
		"No safe evacuation shelter is available for residents on the north bank.",
		"Build an elevated, weather-resistant community shelter.", 8.0
	)
	_spawn_structure(
		"warning_tower", "Warning Tower Site", "install_warning_system", 15, "Not installed",
		"Without an early warning system, residents may not have time to evacuate.",
		"Install a high-mounted flood siren and warning beacon.", 8.0
	)


func _spawn_structure(
	id: String,
	display_name: String,
	decision_id: String,
	cost: int,
	condition: String,
	risk: String,
	improvement: String,
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
	var location_id := str(TownLocations.STRUCTURE_LOCATION_IDS[id])
	structure.set_meta("location_id", location_id)
	structure.position = TownLocations.LOCATIONS[location_id]
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


func _add_box_to(
	parent: Node3D,
	mesh_name: String,
	box_size: Vector3,
	mesh_position: Vector3,
	material: Material
) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var box := BoxMesh.new()
	box.size = box_size
	instance.mesh = box
	instance.material_override = material
	instance.position = mesh_position
	parent.add_child(instance)


func _add_cylinder_to(
	parent: Node3D,
	mesh_name: String,
	radius: float,
	height: float,
	mesh_position: Vector3,
	material: Material
) -> void:
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 7
	instance.mesh = cylinder
	instance.material_override = material
	instance.position = mesh_position
	parent.add_child(instance)


func _create_terrain_mesh(terrain_size: Vector2, subdivisions: int, world_offset_z: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cell_width := terrain_size.x / float(subdivisions)
	var cell_depth := terrain_size.y / float(subdivisions)
	for z in range(subdivisions):
		for x in range(subdivisions):
			var x0 := -terrain_size.x * 0.5 + float(x) * cell_width
			var x1 := x0 + cell_width
			var z0 := -terrain_size.y * 0.5 + float(z) * cell_depth
			var z1 := z0 + cell_depth
			var a := Vector3(x0, 0, z0)
			var b := Vector3(x0, 0, z1)
			var c := Vector3(x1, 0, z0)
			var d := Vector3(x1, 0, z1)
			_add_terrain_vertex(surface, a, world_offset_z)
			_add_terrain_vertex(surface, b, world_offset_z)
			_add_terrain_vertex(surface, c, world_offset_z)
			_add_terrain_vertex(surface, c, world_offset_z)
			_add_terrain_vertex(surface, b, world_offset_z)
			_add_terrain_vertex(surface, d, world_offset_z)
	surface.generate_normals()
	return surface.commit()


func _add_terrain_vertex(surface: SurfaceTool, vertex: Vector3, world_offset_z: float) -> void:
	var world_z := vertex.z + world_offset_z
	var variation_scale := 0.028 if timeline_year == 2026 else 0.018
	var variation := sin(vertex.x * 0.095 + world_z * 0.13) * cos(world_z * 0.11 - vertex.x * 0.03) * variation_scale
	var base := Color("#314633") if timeline_year == 2026 else Color("#464b43")
	surface.set_color(Color(base.r + variation, base.g + variation, base.b + variation * 0.62))
	surface.add_vertex(vertex)
