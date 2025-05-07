shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
global uniform sampler2D lidar_stencil_texture : repeat_disable;

uniform float bloom_threshold = 1.0;
uniform float bloom_intensity = 1.0;


vec3 get_bloom_pixel(sampler2D tex, vec2 uv, vec2 texPixelSize) {
	vec2 uv2 = floor(uv / texPixelSize) * texPixelSize;
	uv2 += texPixelSize * .001;
	vec3 tl = max(texture(tex, uv2).rgb - bloom_threshold, 0.0);
	vec3 tr = max(texture(tex, uv2 + vec2(texPixelSize.x, 0.0)).rgb - bloom_threshold, 0.0);
	vec3 bl = max(texture(tex, uv2 + vec2(0.0, texPixelSize.y)).rgb - bloom_threshold, 0.0);
	vec3 br = max(texture(tex, uv2 + vec2(texPixelSize.x, texPixelSize.y)).rgb - bloom_threshold, 0.0);
	vec2 f = fract( uv / texPixelSize );

	vec3 tA = mix( tl, tr, f.x );
	vec3 tB = mix( bl, br, f.x );

	return mix( tA, tB, f.y );
}

vec3 get_bloom(sampler2D tex, vec2 uv, vec2 tex_pixel_size, float bloom_radius) {
	vec3 bloom = vec3(0.0);
	vec2 off = vec2(1) * tex_pixel_size * bloom_radius;
	bloom += get_bloom_pixel(tex, uv + off * vec2(-1, -1), tex_pixel_size * bloom_radius) * 0.292893;
	bloom += get_bloom_pixel(tex, uv + off * vec2(-1, 0), tex_pixel_size * bloom_radius) * 0.5;
	bloom += get_bloom_pixel(tex, uv + off * vec2(-1, 1), tex_pixel_size * bloom_radius) * 0.292893;
	bloom += get_bloom_pixel(tex, uv + off * vec2(0, -1), tex_pixel_size * bloom_radius) * 0.5;
	bloom += get_bloom_pixel(tex, uv + off * vec2(0, 0), tex_pixel_size * bloom_radius) * 1.0;
	bloom += get_bloom_pixel(tex, uv + off * vec2(0, 1), tex_pixel_size * bloom_radius) * 0.5;
	bloom += get_bloom_pixel(tex, uv + off * vec2(1, -1), tex_pixel_size * bloom_radius) * 0.292893;
	bloom += get_bloom_pixel(tex, uv + off * vec2(1, 0), tex_pixel_size * bloom_radius) * 0.5;
	bloom += get_bloom_pixel(tex, uv + off * vec2(1, 1), tex_pixel_size * bloom_radius) * 0.292893;
	bloom /= 4.171573f;
	return bloom;
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	float lidar = texture(lidar_stencil_texture, SCREEN_UV).r;
	float lidar_bloom = 0.0;
	lidar_bloom += get_bloom(lidar_stencil_texture, SCREEN_UV, vec2(1.0) / VIEWPORT_SIZE, 2.0).r;
	lidar_bloom += get_bloom(lidar_stencil_texture, SCREEN_UV, vec2(1.0) / VIEWPORT_SIZE, 4.0).r * 0.5;
	lidar_bloom += get_bloom(lidar_stencil_texture, SCREEN_UV, vec2(1.0) / VIEWPORT_SIZE, 6.0).r * 0.25;
	lidar_bloom += get_bloom(lidar_stencil_texture, SCREEN_UV, vec2(1.0) / VIEWPORT_SIZE, 8.0).r * 0.125;
	
	lidar += lidar_bloom * bloom_intensity;
	lidar = clamp(lidar, 0.0, 1.0);
	
	float lidar_inv = 1.0 - lidar;
	ALBEDO = color * lidar + vec3(1.0, 0.66, 0.5) * lidar_inv; // vec3(1.0, 0.66, 0.5) vec3(0.0, 0.0, 0.0)
}

