shader_type spatial;
render_mode unshaded, fog_disabled, shadows_disabled, ambient_light_disabled, specular_disabled, depth_draw_never; // depth_prepass_alpha

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

void fragment() {
	float depth = texture(depth_texture, SCREEN_UV).r;
	float diff = abs(FRAGCOORD.z - depth);
	//diff = 1.0 - diff;
	//diff = pow(diff, 500.0 * (1.0 + FRAGCOORD.z));
	//diff = min(1.0, diff);
	
	//ALBEDO = vec3(diff * 1.0);
	if (diff > 0.00001) { discard; }
	ALBEDO = vec3(1.0);
	
	DEPTH = FRAGCOORD.z + 0.00001;
}
