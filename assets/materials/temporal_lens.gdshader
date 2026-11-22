shader_type canvas_item;

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float radius = length(centered);
	float mask = 1.0 - smoothstep(0.47, 0.5, radius);
	vec2 lens_uv = vec2(0.5) + centered * (1.0 + radius * 0.05);
	vec4 view_color = texture(TEXTURE, lens_uv);
	COLOR = vec4(view_color.rgb, view_color.a * mask);
}
