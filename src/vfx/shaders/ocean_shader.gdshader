shader_type spatial;

uniform sampler2D Depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler3D Noise : repeat_enable;
uniform vec3 Color : source_color = vec3(1.0, 0.5, 0.0);
uniform vec3 shallow_color : source_color = vec3(1.0, 0.5, 0.0);

uniform float depth_threshold = 200.0;
uniform float depth_color_threshold = 10.0;

uniform float alpha_dist = 200.0;
varying float cam_dist;


void vertex(){
	cam_dist = length(CAMERA_POSITION_WORLD - (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);
}

vec3 waves(float time, vec3 vertex) {

	vec3 sample_pos = time * 0.1 + vec3(vertex.x, 0, vertex.z) * 0.05;

	float sample = texture(Noise, sample_pos).r;

	vertex.y += sample;

	float sample_px = texture(Noise, sample_pos + vec3( 0.05, 0, 0)).r;
	float sample_nx = texture(Noise, sample_pos + vec3(-0.05, 0, 0)).r;
	float sample_pz = texture(Noise, sample_pos + vec3(0, 0,  0.05)).r;
	float sample_nz = texture(Noise, sample_pos + vec3(0, 0, -0.05)).r;

	return vec3((sample_nx - sample_px) / 2.0, 1.0, (sample_nz - sample_pz) / 2.0);
}

void fragment() {
	ALBEDO = Color;

	METALLIC = 0.0;
	SPECULAR = 1.0;
	ROUGHNESS = 0.2;

	NORMAL = waves(TIME, (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).rgb);

	// use depth texture to make shallow areas more translucent
	float depth = texture(Depth, SCREEN_UV).x;
	//vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;

	float object_depth = FRAGCOORD.z;
	//vec3 object_ndc = vec3(SCREEN_UV, object_depth) * 2.0 - 1.0;
	vec3 object_ndc = vec3(SCREEN_UV * 2.0 - 1.0, object_depth);
	vec4 object_view = INV_PROJECTION_MATRIX * vec4(object_ndc, 1.0);
	object_view.xyz /= object_view.w;
	float linear_object_depth = -object_view.z;

	ALPHA = (smoothstep(0.0, depth_threshold, linear_depth - linear_object_depth) + 1.0) / 2.0;
	ALPHA = mix(ALPHA, 1.0, clamp(cam_dist / alpha_dist, 0.0,1.0));

	ALBEDO = mix(shallow_color, Color, (smoothstep(0.0, depth_color_threshold, linear_depth - linear_object_depth) + 1.0) / 2.0);
}
