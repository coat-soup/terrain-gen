shader_type spatial;

uniform sampler2D height_gradient;
uniform sampler2D steep_gradient;
uniform float slope_cutoff;
uniform sampler2D water_gradient;
uniform float planet_radius;
uniform float terrain_height;
uniform vec3 world_center;

uniform sampler2D depth_tex : hint_depth_texture;

void vertex() {
	float height = length((MODEL_MATRIX * vec4(VERTEX.rgb, 1.0)).rgb - world_center) - planet_radius;
	if (height <= 0.0) COLOR = texture(water_gradient, vec2(1.0 - height/terrain_height, 0));
	else{
		if(abs(dot(NORMAL, vec3(0.0,1.0,0.0))) > slope_cutoff) COLOR = texture(height_gradient, vec2(min(0.999, height/terrain_height), 0));
		else COLOR = texture(steep_gradient, vec2(min(0.999, height/terrain_height), 0));
	}
}

void fragment() {
	ALBEDO = vec3(COLOR.rgb);
	
	// Screen UV (0–1)
	vec2 uv = FRAGCOORD.xy / VIEWPORT_SIZE;
	
	// Read depth buffer
	float depth = texture(depth_tex, uv).r;
	
	// Reconstruct clip space position
	vec4 clip_pos = vec4(uv * 2.0 - 1.0, depth, 1.0);
	
	// View space position
	vec4 view_pos = INV_PROJECTION_MATRIX * clip_pos;
	view_pos /= view_pos.w;
	
	// World space position
	vec3 world_pos = (INV_VIEW_MATRIX * view_pos).xyz;
	
	vec3 world_normal = (INV_VIEW_MATRIX * vec4(NORMAL.xyz, 0.0)).xyz;
	
	float height = length(world_pos - world_center) - planet_radius;
	if (height <= 0.0) ALBEDO = texture(water_gradient, vec2(1.0 - height/terrain_height, 0)).rgb;
	else{
		if(abs(dot(world_normal, normalize(world_pos))) > slope_cutoff) ALBEDO = texture(height_gradient, vec2(min(0.999, height/terrain_height), 0)).rgb;
		else ALBEDO = texture(steep_gradient, vec2(min(0.999, height/terrain_height), 0)).rgb;
	}
	//ALBEDO = vec3(abs(dot(world_normal, normalize(world_pos))));
	//ALBEDO = world_normal;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
