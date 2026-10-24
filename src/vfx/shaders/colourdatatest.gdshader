shader_type spatial;

#include "triplanar.gdshaderinc"

uniform vec3[16] colour_array : source_color;
uniform sampler2D[16] material_texture_array : source_color;

varying flat uint[4] material_ids;
varying float[4] material_weights;


void vertex() {
	for(int i = 0; i < 4; i++){
		uint bits = floatBitsToUint(CUSTOM0[i]);
		material_ids[i] = bits >> 16u;
		material_weights[i] = unpackHalf2x16(bits).x;
	}
}

float height_lerp(float height, float transition_phase){
	return pow(clamp((height - 1.0) + (transition_phase * 2.0), 0.0, 1.0), 5);
}

void fragment() {
	ALBEDO = vec3(0.0);
	for(int i = 0; i < 4; i++){
		if(material_weights[i] <= 0.0 || material_ids[i]==0u) continue;
		vec3 mat = triplanar(material_texture_array[material_ids[i]], 0.25, INV_VIEW_MATRIX, VERTEX, NORMAL);
		ALBEDO += mat * material_weights[i];
	}
}
