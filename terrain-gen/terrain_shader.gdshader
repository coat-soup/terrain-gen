shader_type spatial;

uniform sampler2D height_gradient;
uniform sampler2D water_gradient;
uniform float base_height;
uniform vec3 world_center;

void vertex() {
	float height = length((MODEL_MATRIX * vec4(VERTEX.rgb, 1.0)).rgb - world_center) - base_height;
	if (height <= 0.0) COLOR = texture(water_gradient, vec2(1.0 - height, 0));
	else COLOR = texture(height_gradient, vec2(min(0.999, height), 0));
}

void fragment() {
	ALBEDO = vec3(COLOR.rgb);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
