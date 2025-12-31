shader_type spatial;

render_mode cull_disabled, depth_prepass_alpha, blend_mix;

uniform vec3 leaf_color : source_color;
uniform vec3 trunk_color : source_color;

uniform sampler3D wind_noise;
uniform vec3 wind_dir = vec3(1.0,0.0,0.0);
uniform float wind_strength = 0.5;
uniform float wind_frequency = 3.0;

uniform sampler2D leaf_texture;
uniform bool is_grass;
const float alpha_dist = 200.0;
const float vert_displace_distance = 100.0;
varying float cam_dist;

void vertex() {
	//if(COLOR.r == 0.0) COLOR = vec4(trunk_color, 1.0);
	//else COLOR = vec4(leaf_color, 1.0);
	cam_dist = length(CAMERA_POSITION_WORLD - (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);
	
	if(cam_dist < vert_displace_distance){
		VERTEX += wind_dir * wind_strength * texture(wind_noise, VERTEX + vec3(TIME) * wind_frequency).r * COLOR.r;
	}
}

void fragment() {
	if(COLOR.r == 0.0) ALBEDO = trunk_color.rgb;
	else ALBEDO = leaf_color.rgb;
	
	if (!is_grass && (COLOR.r != 0.0))
	{
		ALPHA = texture(leaf_texture, UV).a;
		// fade alpha when far away (for performance and because mipmaps makes everything transparent otherwise lol)
		ALPHA_SCISSOR_THRESHOLD = mix(0.5, 0.0, clamp(cam_dist / alpha_dist, 0.0,1.0));
	}
	
	ROUGHNESS = 1.0;
}