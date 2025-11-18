shader_type spatial;

uniform sampler2D data_tex;
uniform int data_tex_size;


float get_data(int index) {
    int pixel = index / 4;
    int channel = index % 4;

    ivec2 uv;
    uv.x = pixel % data_tex_size;
    uv.y = pixel / data_tex_size;

    vec4 px = texelFetch(data_tex, uv, 0);

    if (channel == 0) return px.r;
    if (channel == 1) return px.g;
    if (channel == 2) return px.b;
    return px.a;
}

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
	float data = get_data(int(face_id));
	COLOR = vec4(data);
}