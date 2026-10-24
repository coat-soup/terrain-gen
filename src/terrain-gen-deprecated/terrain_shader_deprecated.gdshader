shader_type spatial;

#include "res://vfx/shaders/triplanar.gdshaderinc"
#include "res://vfx/shaders/FastNoiseLite.gdshaderinc"

uniform float grass_slope_cutoff;
uniform float dirt_slope_cutoff;
uniform float planet_radius;
uniform float terrain_height;
uniform vec3 world_center;

uniform sampler2D depth_tex : hint_depth_texture;

uniform vec3[15] climate_zone_ground_colours : source_color;

uniform sampler2D grass_tex;
uniform sampler2D grass_norm;
uniform sampler2D stone_tex;
uniform sampler2D stone_norm;
uniform vec3 stone_color : source_color = vec3(1.0);
uniform sampler2D dirt_tex;
uniform sampler2D dirt_norm;
uniform vec3 dirt_color : source_color = vec3(1.0);
uniform sampler2D sand_tex;
uniform sampler2D sand_norm;
uniform vec3 sand_color : source_color = vec3(1.0);

uniform float color_noise_scale;


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
	if (height <= 0.0) {
		ALBEDO = triplanar_stochastic(sand_tex, 0.2, INV_VIEW_MATRIX, VERTEX, NORMAL) * sand_color;
		NORMAL_MAP = triplanar_stochastic(sand_norm, 0.2, INV_VIEW_MATRIX, VERTEX, NORMAL);
	}
	else{
		float slope = abs(dot(world_normal, normalize(world_pos)));
		if(slope > grass_slope_cutoff) {
			ALBEDO = triplanar_stochastic(grass_tex, 0.2, INV_VIEW_MATRIX, VERTEX, NORMAL) * climate_zone_ground_colours[int(COLOR.r * 14.0 + 0.5)];//ALBEDO = texture(height_gradient, vec2(min(0.999, height/terrain_height), 0)).rgb;
			NORMAL_MAP = triplanar_stochastic(grass_norm, 0.2, INV_VIEW_MATRIX, VERTEX, NORMAL);
		}
		else if(slope > dirt_slope_cutoff){
			ALBEDO = triplanar_stochastic(dirt_tex, 0.2, INV_VIEW_MATRIX, VERTEX, NORMAL) * dirt_color;
			NORMAL_MAP = triplanar_stochastic(dirt_norm, 0.2, INV_VIEW_MATRIX, VERTEX, NORMAL);
		}
		else{
			ALBEDO = triplanar_stochastic(stone_tex, 0.05, INV_VIEW_MATRIX, VERTEX, NORMAL) * stone_color;
			NORMAL_MAP = triplanar_stochastic(stone_norm, 0.05, INV_VIEW_MATRIX, VERTEX, NORMAL);
		}
	}
	
	
	
	fnl_state state = fnlCreateState(1337);
	state.noise_type = FNL_NOISE_CELLULAR;
	state.fractal_type = FNL_FRACTAL_FBM;
	state.frequency = color_noise_scale;
	state.octaves = 4;
	state.lacunarity = 2.f;
	state.gain = .5f;
	vec3 world_vertex = (INV_VIEW_MATRIX * vec4(VERTEX, 1.f)).xyz;
	float noise = fnlGetNoise3D(state, 
								world_vertex.x,
								world_vertex.y,
								world_vertex.z) / 2.f + 0.5f;
	
	ALBEDO = mix(ALBEDO, ALBEDO * 0.9, noise);
	
	//ALBEDO = climate_zone_ground_colours[int(floor(COLOR.r * 14.0 + 0.5))];
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
