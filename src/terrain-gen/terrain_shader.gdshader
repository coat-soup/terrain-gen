shader_type spatial;

uniform sampler2D height_gradient;
uniform sampler2D steep_gradient;
uniform float slope_cutoff;
uniform sampler2D water_gradient;
uniform float planet_radius;
uniform float terrain_height;
uniform vec3 world_center;

uniform sampler2D depth_tex : hint_depth_texture;

uniform vec3[15] climate_zone_ground_colours : source_color;


void fragment() {
	//ALBEDO = vec3(COLOR.rgb);

	vec2 uv = FRAGCOORD.xy / VIEWPORT_SIZE;

	float depth = texture(depth_tex, uv).r;
	vec4 clip_pos = vec4(uv * 2.0 - 1.0, depth, 1.0);
	vec4 view_pos = INV_PROJECTION_MATRIX * clip_pos;
	view_pos /= view_pos.w;

	vec3 world_pos = (INV_VIEW_MATRIX * view_pos).xyz;
	vec3 world_normal = (INV_VIEW_MATRIX * vec4(NORMAL.xyz, 0.0)).xyz;

	float height = length(world_pos - world_center) - planet_radius;
	if (height <= 0.0) ALBEDO = texture(water_gradient, vec2(1.0 - height/terrain_height, 0)).rgb;
	else{
		if(abs(dot(world_normal, normalize(world_pos))) > slope_cutoff) ALBEDO = climate_zone_ground_colours[int(COLOR.r * 14.0 + 0.5)];//ALBEDO = texture(height_gradient, vec2(min(0.999, height/terrain_height), 0)).rgb;
		else ALBEDO = texture(steep_gradient, vec2(min(0.999, height/terrain_height), 0)).rgb;
	}

	//ALBEDO = climate_zone_ground_colours[int(floor(COLOR.r * 14.0 + 0.5))];
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
