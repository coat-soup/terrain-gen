shader_type spatial;

uniform vec3[8] colour_array : source_color;

varying flat uint material_id_a;
varying flat uint material_id_b;
varying float blend_amount;

void vertex() {
	// Called for every vertex the material is visible on.
	//COLOR = vec4(colour_array[floatBitsToUint(CUSTOM0.r)], 1.0);
	//COLOR = CUSTOM0;
	material_id_a = floatBitsToUint(CUSTOM0.r);
	material_id_b = floatBitsToUint(CUSTOM0.g);
	blend_amount = CUSTOM0.b;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ALBEDO = mix(colour_array[material_id_a], colour_array[material_id_b], blend_amount);
	
	//if(material_id_a != material_id_b) ALBEDO = vec3(0.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
