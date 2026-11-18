shader_type spatial;
render_mode cull_disabled;

void fragment() {
	float flow = sin(UV.x * 32.0 + TIME * 0.7) * 0.035;
	float ripple = sin(UV.y * 19.0 - TIME * 0.45) * 0.025;
	ALBEDO = vec3(0.035 + flow, 0.34 + ripple, 0.56 + flow);
	ROUGHNESS = 0.28;
	METALLIC = 0.08;
}
