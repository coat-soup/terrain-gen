shader_type spatial;

uniform vec3[16] colour_array : source_color;

varying flat uint[4] material_ids;
varying float[4] material_weights;


void vertex() {
	for(int i = 0; i < 4; i++){
		uint bits = floatBitsToUint(CUSTOM0[i]);
		material_ids[i] = bits >> 16u;
		material_weights[i] = unpackHalf2x16(bits).x;
	}
}

void fragment() {
	ALBEDO = vec3(0.0);
	for(int i = 0; i < 4; i++){
		if(material_weights[i] <= 0.0 || material_ids[i]==0u) continue;
		ALBEDO += colour_array[material_ids[i]] * material_weights[i];
	}
	
	for(int i = 0; i < 4; i++){
		//if(material_ids[i] == 0u && material_weights[i] > 0.0) ALBEDO = vec3(1.0);
		//ALBEDO += colour_array[material_ids[i]] * material_weights[i];
	}
	
	//ALBEDO = vec3(material_weights[0]);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
