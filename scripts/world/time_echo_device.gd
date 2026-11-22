extends Node3D

var active := false
var _rings: Array[MeshInstance3D] = []
var _core_material: StandardMaterial3D
var _core_light: OmniLight3D
var _elapsed := 0.0


func _ready() -> void:
	_build_device()


func _process(delta: float) -> void:
	if not active:
		return
	_elapsed += delta
	for index in range(_rings.size()):
		_rings[index].rotation.z += delta * (0.65 if index % 2 == 0 else -0.8)
	_core_light.light_energy = 0.6 + sin(_elapsed * 5.0) * 0.22


func set_active(value: bool) -> void:
	active = value
	_core_light.visible = value
	_core_material.albedo_color = Color("#58dff0") if value else Color("#385566")
	_core_material.emission_enabled = value


func _build_device() -> void:
	var casing := MeshInstance3D.new()
	casing.name = "Ancient wrist device"
	var base := CylinderMesh.new()
	base.top_radius = 0.24
	base.bottom_radius = 0.24
	base.height = 0.1
	base.radial_segments = 12
	casing.mesh = base
	casing.rotation.x = PI * 0.5
	casing.material_override = _make_metal(Color("#685b48"))
	add_child(casing)
	for ring_index in range(2):
		var ring := MeshInstance3D.new()
		ring.name = "Concentric temporal ring %d" % ring_index
		var torus := TorusMesh.new()
		torus.inner_radius = 0.025
		torus.outer_radius = 0.045 if ring_index == 0 else 0.032
		torus.rings = 12
		torus.ring_segments = 8
		ring.mesh = torus
		ring.rotation = Vector3(PI * 0.5, 0, float(ring_index) * 0.65)
		ring.material_override = _make_metal(Color("#b4a57f") if ring_index == 0 else Color("#7d8990"))
		add_child(ring)
		_rings.append(ring)
	var core := MeshInstance3D.new()
	core.name = "Temporal core"
	var sphere := SphereMesh.new()
	sphere.radius = 0.11
	sphere.height = 0.22
	sphere.radial_segments = 8
	sphere.rings = 4
	core.mesh = sphere
	_core_material = _make_metal(Color("#385566"))
	core.material_override = _core_material
	add_child(core)
	_core_light = OmniLight3D.new()
	_core_light.light_color = Color("#64dced")
	_core_light.light_energy = 0.6
	_core_light.omni_range = 1.8
	_core_light.visible = false
	add_child(_core_light)


func _make_metal(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.72
	material.roughness = 0.32
	return material
