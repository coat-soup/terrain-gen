shader_type spatial;

uniform vec2[6] positions;
uniform vec3[6] values : source_color;
uniform float distance_power = 2.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 val = vec3(0.0);
	float weight = 0.0;

	for(int i = 0; i < positions.length(); i++){
		float d = length(positions[i]-UV);
		float w = 1.0 / pow(d, distance_power);
		val += values[i] * w;
		weight += w;
	}

	ALBEDO = val/weight;
}

