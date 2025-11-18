shader_type spatial;

uniform float cell_data[8000];


uint decode_id(vec4 color) {
    return uint(color.r * 255.0) << 24u |
           uint(color.g * 255.0) << 16u |
           uint(color.b * 255.0) << 8u |
           uint(color.a * 255.0);
}

// DO NOT DECODE ID IN FRAGMENT
// IT REALLY DOESNT LIKE IT
void fragment() {
	ALBEDO = vec3(COLOR.rgb);
}

// do all colour calculation in vertex function and then pass it to vertex color
void vertex() {
    uint face_id = decode_id(COLOR);
	float data = cell_data[face_id];
	//fVERTEX += NORMAL * vec3(data * 5.0);
	COLOR = vec4(data);
}