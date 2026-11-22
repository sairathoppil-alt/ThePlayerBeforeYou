shader_type spatial;
render_mode cull_disabled;

uniform vec3 deep_water_color : source_color = vec3(0.035, 0.17, 0.23);
uniform vec3 shallow_water_color : source_color = vec3(0.12, 0.34, 0.39);

void fragment() {
	float flow = sin(UV.x * 34.0 + TIME * 0.42 + sin(UV.y * 6.0)) * 0.5 + 0.5;
	float ripple = sin(UV.y * 17.0 - TIME * 0.28 + UV.x * 4.0) * 0.5 + 0.5;
	float highlight = smoothstep(0.76, 0.98, flow * ripple);
	float sheen = smoothstep(0.45, 0.85, flow) * 0.12;
	ALBEDO = mix(deep_water_color, shallow_water_color, clamp(highlight + sheen, 0.0, 1.0));
	ROUGHNESS = 0.4;
	METALLIC = 0.01;
}
