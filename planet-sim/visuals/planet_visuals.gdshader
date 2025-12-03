shader_type spatial;

uniform sampler2D height_gradient;
uniform sampler2D water_gradient;
uniform sampler2D stress_gradient;
uniform sampler2D temperature_gradient;
uniform sampler2D wind_gradient;
uniform sampler2D precipitation_gradient;

uniform vec4 climate_zone_colours[16] : source_color;

uniform sampler2D data_tex;
uniform int data_tex_size;
uniform int vis_type;

render_mode unshaded;

const vec3 PALETTE[30] = vec3[](
    vec3(0.96, 0.17, 0.25),
    vec3(0.93, 0.49, 0.19),
    vec3(0.99, 0.79, 0.16),
    vec3(0.58, 0.87, 0.21),
    vec3(0.15, 0.73, 0.27),
    vec3(0.18, 0.84, 0.62),
    vec3(0.12, 0.68, 0.83),
    vec3(0.21, 0.46, 0.96),
    vec3(0.54, 0.27, 0.91),
    vec3(0.90, 0.19, 0.73),

    vec3(0.96, 0.27, 0.14),
    vec3(0.78, 0.63, 0.14),
    vec3(0.40, 0.79, 0.09),
    vec3(0.12, 0.88, 0.51),
    vec3(0.09, 0.77, 0.84),
    vec3(0.16, 0.56, 0.98),
    vec3(0.58, 0.34, 0.98),
    vec3(0.91, 0.30, 0.82),
    vec3(0.98, 0.33, 0.46),
    vec3(0.98, 0.63, 0.21),

    vec3(0.97, 0.89, 0.15),
    vec3(0.47, 0.88, 0.20),
    vec3(0.14, 0.92, 0.67),
    vec3(0.15, 0.76, 0.98),
    vec3(0.30, 0.47, 0.98),
    vec3(0.66, 0.25, 0.95),
    vec3(0.93, 0.23, 0.64),
    vec3(0.93, 0.43, 0.28),
    vec3(0.91, 0.79, 0.26),
    vec3(0.33, 0.88, 0.28));


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


vec4 color_from_plate_data(float plate_id) {
	if (plate_id == -1.0) return vec4(0.0);
	else return vec4(PALETTE[int(plate_id) % 30].rgb, 1.0);
}

vec4 color_from_height_data(float height) {
	//if (height <= 0.0) return vec4(0.107, 0.211, 0.255, 0.0);
	if (height <= 0.0) return texture(water_gradient, vec2(max(0.0, 1.0 - height), 0.0));
	return texture(height_gradient, vec2(min(0.999, height), 0.0));
}

vec4 color_from_ocean_current_data(float data){
	if(data == -2.0) return vec4(0.0,0.5,1.0,0.0); // base ocean
	if(data == -1.0) return vec4(0.0,1.0,0.0,0.0); //base land
	if(data == 0.0) return vec4(0.0,0.0,0.0,0.0); // neutral current
	if(data == 1.0) return vec4(1.0,0.0,0.0,0.0); // warm current
	if(data == 2.0) return vec4(0.0,0.0,1.0,0.0); // cold current
}

vec4 color_from_temperature_data(float temperature) {
	if (temperature == -999.0) return vec4(0.0);
	return texture(temperature_gradient, vec2(clamp((temperature / 50.0)/2.0 + 0.5, 0.01, 0.99)));
}

vec4 color_from_wind_data(float wind){
	vec4 c = texture(wind_gradient, vec2(max(0.01, abs(wind)), 0.0));
	if (wind < 0.0) c *= 0.8;
	return c;
}

vec4 color_from_precipitation_data(float precipitation) {
	if (precipitation < 0.0) return vec4(0.0); // black out water
	return texture(wind_gradient, vec2(clamp(precipitation, 0.002, 0.999), 0.0));
}

// DO NOT DECODE ID IN FRAGMENT
// IT REALLY DOESNT LIKE IT
void fragment() {
	ALBEDO = vec3(COLOR.rgb);
}


// do all colour calculation in vertex function and then pass it to vertex color in fragment
void vertex() {
	uint face_id = decode_id(COLOR);
	float data = get_data(int(face_id));

	if (vis_type == 0) COLOR = vec4(COLOR.a); // cell id
	if (vis_type == 1) COLOR = color_from_plate_data(data); // plate id
	if (vis_type == 2) COLOR = vec4(data); // cell position
	if (vis_type == 3) COLOR = texture(stress_gradient, vec2(min(1.0, data / 2.0 + 0.5), 0.0)); // plate stress
	if (vis_type == 4){ COLOR = color_from_height_data(data);}//VERTEX += NORMAL * data / 20.0;}
	if (vis_type == 5) COLOR = color_from_temperature_data(data); // temp
	if (vis_type == 6) COLOR = color_from_ocean_current_data(data); // currents
	if (vis_type == 7) COLOR = color_from_wind_data(data); // wind
	if (vis_type == 8) COLOR = texture(wind_gradient, vec2(clamp(data, 0.001, 0.999), 0.0)); // ocean boundary
	if (vis_type == 9) COLOR = color_from_precipitation_data(data); // precipitation
	if (vis_type == 10) COLOR = texture(wind_gradient, vec2(clamp(data, 0.001, 0.999), 0.0)); // slope
	if (vis_type == 11) COLOR = data != -1.0? climate_zone_colours[int(data)] : vec4(0.0);
}