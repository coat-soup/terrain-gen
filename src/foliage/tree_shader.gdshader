shader_type spatial;

uniform vec3 leaf_color : source_color;
uniform vec3 trunk_color : source_color;


void vertex() {
	if(COLOR.b > 0.0) COLOR = vec4(trunk_color, 1.0);
	else COLOR = vec4(leaf_color, 1.0);
}

void fragment() {
	ALBEDO = COLOR.rgb;
}