extends Node3D

const Palette = preload("res://scripts/core/town_palette.gd")
const InteractableScript = preload("res://scripts/world/adventure_interactable.gd")

@export var location_id := ""
@export var facility_name := "Town Facility"
@export_multiline var description := "A Willowbrook landmark."
@export var facility_type := "building"
@export var future_damaged := false
@export var interaction_enabled := true
@export var wall_color := Color("#c9b991")
@export var roof_color := Color("#6a5550")

var _historic_overlay: Node3D


func _ready() -> void:
	set_meta("location_id", location_id)
	if interaction_enabled:
		add_to_group("temporal_inspectable")
	_build_facility()
	if interaction_enabled:
		_add_collision()
		_add_interaction_zone()
	if future_damaged:
		_build_historic_overlay()


func set_historic_reveal(enabled: bool) -> void:
	if _historic_overlay != null:
		_historic_overlay.visible = enabled


func _build_facility() -> void:
	if facility_type == "tunnel":
		_build_tunnel_entrance()
		return
	if facility_type == "construction":
		_build_construction_site()
		return
	var walls := StandardMaterial3D.new()
	walls.albedo_color = wall_color.darkened(0.35) if future_damaged else wall_color
	walls.roughness = 1.0
	var roof := StandardMaterial3D.new()
	roof.albedo_color = roof_color.darkened(0.42) if future_damaged else roof_color
	roof.roughness = 0.95
	_add_box("Foundation", Vector3(8.0, 0.45, 7.0), Vector3(0, 0.2, 0), Palette.CONCRETE)
	_add_box("Walls", Vector3(7.4, 3.7, 6.4), Vector3(0, 2.25, 0), walls)
	_add_box("Roof", Vector3(8.5, 0.55, 7.5), Vector3(0, 4.35, 0), roof)
	_add_box("Roof ridge", Vector3(0.3, 0.28, 7.7), Vector3(0, 4.75, 0), Palette.WOOD)
	_add_box("Front door", Vector3(1.2, 2.3, 0.16), Vector3(0, 1.35, -3.27), Palette.WOOD)
	for x in [-2.4, 2.4]:
		_add_box("Window", Vector3(1.3, 1.0, 0.12), Vector3(x, 2.55, -3.28), Palette.GLASS)
		_add_box("Window lintel", Vector3(1.55, 0.14, 0.18), Vector3(x, 3.12, -3.32), Palette.WOOD)
	if facility_type == "workshop" or facility_type == "maintenance":
		_add_box("Workshop side annex", Vector3(2.2, 2.3, 3.0), Vector3(3.9, 1.35, 0.3), walls)
		_add_box("Large workshop door", Vector3(2.0, 2.6, 0.18), Vector3(0, 1.4, -3.4), Palette.METAL)
	elif facility_type == "electrical":
		_add_box("Transformer housing", Vector3(2.2, 1.5, 1.4), Vector3(-3.1, 0.95, 1.8), Palette.METAL)
		_add_box("Insulator", Vector3(0.5, 1.1, 0.5), Vector3(-3.1, 2.2, 1.8), Palette.GLASS)
	elif facility_type == "archives":
		_add_box("Archive sign", Vector3(3.0, 0.55, 0.15), Vector3(0, 3.85, -3.3), Palette.WOOD)
	if future_damaged:
		_add_box("Boarded window", Vector3(1.55, 0.14, 0.18), Vector3(-2.4, 2.55, -3.38), Palette.WOOD)
		_add_box("Broken roof section", Vector3(1.8, 0.12, 1.4), Vector3(2.1, 4.05, 0.5), Palette.FOUNDATION)
		_add_box("Flood debris", Vector3(2.0, 0.7, 0.8), Vector3(-4.4, 0.4, 2.0), Palette.WOOD)
	_add_label(facility_name.to_upper())
	_add_sign_trim()


func _build_tunnel_entrance() -> void:
	var concrete := Palette.CONCRETE
	var dark_material := StandardMaterial3D.new()
	dark_material.albedo_color = Color("#171d21") if future_damaged else Color("#303b3c")
	_add_box("Tunnel arch left", Vector3(0.8, 2.8, 2.1), Vector3(-1.9, 1.35, 0), concrete)
	_add_box("Tunnel arch right", Vector3(0.8, 2.8, 2.1), Vector3(1.9, 1.35, 0), concrete)
	_add_box("Tunnel lintel", Vector3(4.6, 0.75, 2.1), Vector3(0, 2.75, 0), concrete)
	_add_box("Tunnel dark opening", Vector3(3.2, 2.25, 0.08), Vector3(0, 1.22, -1.08), dark_material)
	_add_box("Tunnel path", Vector3(3.1, 0.16, 5.0), Vector3(0, 0.04, -3.0), Palette.FOUNDATION)
	_add_label("DRAINAGE TUNNEL")
	if future_damaged:
		_add_box("Collapsed tunnel rubble", Vector3(1.3, 0.7, 1.1), Vector3(0.8, 0.36, -0.75), Palette.ROOF)


func _add_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "FacilityCollision"
	add_child(body)
	if facility_type == "tunnel":
		for x in [-1.9, 1.9]:
			var side_shape := CollisionShape3D.new()
			var side_box := BoxShape3D.new()
			side_box.size = Vector3(0.8, 2.8, 2.1)
			side_shape.shape = side_box
			side_shape.position = Vector3(x, 1.35, 0)
			body.add_child(side_shape)
		var lintel_shape := CollisionShape3D.new()
		var lintel_box := BoxShape3D.new()
		lintel_box.size = Vector3(4.6, 0.75, 2.1)
		lintel_shape.shape = lintel_box
		lintel_shape.position = Vector3(0, 2.75, 0)
		body.add_child(lintel_shape)
		return
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(7.7, 4.4, 6.7)
	shape.shape = box
	shape.position = Vector3(0, 2.2, 0)
	body.add_child(shape)


func _build_construction_site() -> void:
	_add_box("Construction foundation", Vector3(8.5, 0.3, 7.0), Vector3(0, 0.16, 0), Palette.CONCRETE)
	for x in [-3.1, 3.1]:
		_add_box("Timber support", Vector3(0.25, 4.2, 0.25), Vector3(x, 2.3, 0), Palette.WOOD)
	for z in [-2.7, 2.7]:
		_add_box("Frame beam", Vector3(6.6, 0.24, 0.24), Vector3(0, 4.0, z), Palette.WOOD)
	_add_box("Material stack", Vector3(2.4, 0.55, 0.8), Vector3(-1.5, 0.55, 1.3), Palette.WOOD)
	if future_damaged:
		_add_box("Collapsed framing", Vector3(4.0, 0.22, 0.25), Vector3(0, 2.6, 0.3), Palette.ROOF)
	_add_label(facility_name.to_upper())


func _add_interaction_zone() -> void:
	var zone := Area3D.new()
	zone.name = "InteractionZone"
	zone.set_script(InteractableScript)
	zone.set("interaction_id", location_id)
	zone.set("display_name", facility_name)
	zone.set("interaction_description", description)
	zone.set("interaction_kind", "inspect")
	zone.set("interaction_radius", 5.5)
	zone.set_meta("location_id", location_id)
	add_child(zone)
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 5.5
	collision.shape = sphere
	zone.add_child(collision)


func _add_label(text: String) -> void:
	var label := Label3D.new()
	label.name = "FacilityName"
	label.text = text
	label.font_size = 30
	label.pixel_size = 0.009
	label.position = Vector3(0, 5.25, -3.9)
	label.modulate = Color("#f1dfb8") if not future_damaged else Color("#9facb3")
	label.outline_size = 5
	label.outline_modulate = Color("#172128")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)


func _add_sign_trim() -> void:
	for x in [-3.6, 3.6]:
		_add_box("Corner timber", Vector3(0.16, 3.8, 0.16), Vector3(x, 2.2, -3.25), Palette.WOOD)


func _build_historic_overlay() -> void:
	_historic_overlay = Node3D.new()
	_historic_overlay.name = "TemporalHistoricalAppearance"
	_historic_overlay.visible = false
	add_child(_historic_overlay)
	var outline_material := StandardMaterial3D.new()
	outline_material.albedo_color = Color("#82dce7", 0.28)
	outline_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_material.emission_enabled = true
	outline_material.emission = Color("#61b8c5")
	outline_material.emission_energy_multiplier = 0.45
	var historical_roof := MeshInstance3D.new()
	historical_roof.name = "Restored roof outline"
	var roof_mesh := BoxMesh.new()
	roof_mesh.size = Vector3(7.7, 0.18, 6.7)
	historical_roof.mesh = roof_mesh
	historical_roof.position = Vector3(0, 4.45, 0)
	historical_roof.material_override = outline_material
	_historic_overlay.add_child(historical_roof)
	var historical_door := MeshInstance3D.new()
	historical_door.name = "Original door outline"
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(1.35, 2.45, 0.08)
	historical_door.mesh = door_mesh
	historical_door.position = Vector3(0, 1.4, -3.35)
	historical_door.material_override = outline_material
	_historic_overlay.add_child(historical_door)


func _add_box(mesh_name: String, size: Vector3, local_position: Vector3, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = mesh_name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = local_position
	mesh_instance.material_override = material
	add_child(mesh_instance)
