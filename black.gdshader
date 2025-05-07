shader_type spatial;
render_mode unshaded, depth_draw_never;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	ALBEDO = vec3(0.0);
}
