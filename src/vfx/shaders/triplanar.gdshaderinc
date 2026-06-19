vec3 triplanar(sampler2D sampler, float scale, mat4 _INV_VIEW_MATRIX, vec3 _VERTEX, vec3 _NORMAL) {
	vec4 vertex = _INV_VIEW_MATRIX * vec4(_VERTEX, 1.0);
	vec3 normal = normalize((_INV_VIEW_MATRIX * vec4(_NORMAL, 0.0)).xyz);
	vec3 adjusted_normal = pow(abs(normal), vec3(8.0));
	vec3 weights = adjusted_normal / (adjusted_normal.x + adjusted_normal.y + adjusted_normal.z) * 3.0;
	
	vec2 uv_x = vertex.zy * scale;
	vec2 uv_y = vertex.xz * scale;
	vec2 uv_z = vertex.xy * scale;
	
	
	vec3 color_x = texture(sampler, uv_x).rgb * weights.x;
	vec3 color_y = texture(sampler, uv_y).rgb * weights.y;
	vec3 color_z = texture(sampler, uv_z).rgb * weights.z;
	
	return(color_x + color_y + color_z) / 3.0;
}


float hash12(vec2 p) {
	p = fract(p * vec2(443.897, 441.423));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

vec2 hash22(vec2 p) {
	float n = hash12(p);
	return vec2(
		hash12(p + n),
		hash12(p + n + 17.0)
	);
}


vec3 stochastic_texture(sampler2D sampler, vec2 uv) {
	vec2 cell = floor(uv);
	
	vec2 offset1 = hash22(cell) - 0.5;
	vec2 offset2 = hash22(cell + 13.0) - 0.5;
	vec2 offset3 = hash22(cell + 37.0) - 0.5;
	
	vec3 s1 = texture(sampler, uv + offset1).rgb;
	vec3 s2 = texture(sampler, uv + offset2).rgb;
	vec3 s3 = texture(sampler, uv + offset3).rgb;
	
	return (s1 + s2 + s3) / 3.0;
}

vec3 triplanar_stochastic(sampler2D sampler, float scale, mat4 _INV_VIEW_MATRIX, vec3 _VERTEX, vec3 _NORMAL) {
	vec4 vertex = _INV_VIEW_MATRIX * vec4(_VERTEX, 1.0);
	vec3 normal = normalize(
		(_INV_VIEW_MATRIX * vec4(_NORMAL, 0.0)).xyz
	);
	
	vec3 adjusted_normal = pow(abs(normal), vec3(8.0));
	vec3 weights =
		adjusted_normal /
		(adjusted_normal.x + adjusted_normal.y + adjusted_normal.z) *
		3.0;
	
	vec2 uv_x = vertex.zy * scale;
	vec2 uv_y = vertex.xz * scale;
	vec2 uv_z = vertex.xy * scale;
	
	vec3 color_x = stochastic_texture(sampler, uv_x) * weights.x;
	vec3 color_y = stochastic_texture(sampler, uv_y) * weights.y;
	vec3 color_z = stochastic_texture(sampler, uv_z) * weights.z;

	return (color_x + color_y + color_z) / 3.0;
}