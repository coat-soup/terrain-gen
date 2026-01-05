shader_type sky;

uniform vec3 sun_dir = vec3(1.0,0.0,0.0);
uniform vec3 day_color : source_color;
uniform vec3 night_color : source_color;
uniform vec3 sun_horizon_color : source_color;
uniform vec3 sun_color : source_color;
uniform float day_night_transition_width = 0.03;
uniform float sun_horizon_size = 1.0;
uniform float sun_horizon_time_band = 0.03;
uniform float planet_radius = 12000.0;

uniform float debug_rotate_sun; // rotates sun_dir by 2*PI*debug_rotate_sun radians


vec3 rotated_sun(){
	// debug rotate sun direction around Y axis
	float a = TAU * debug_rotate_sun;
	mat3 rot_y = mat3(
		vec3( cos(a), 0.0, -sin(a)),
		vec3( 0.0,   1.0,  0.0),
		vec3( sin(a), 0.0,  cos(a))
	);
	return normalize(rot_y * sun_dir);
}

float normalised_tod(vec3 camera_pos){
	vec3 npos = normalize(camera_pos);
	vec3 dir  = rotated_sun();
	
	// project onto equator
	vec2 p = normalize(npos.xz);
	vec2 s = normalize(dir.xz);
	
	// from -pi to pi
	float angle = atan(p.x * s.y - p.y * s.x, dot(p, s));
	
	// map 0-1
	return fract((angle / TAU) + 0.5);
}

float tod_horizon_offset(vec3 camera_pos){
	float r = length(camera_pos);
	float R = planet_radius;
	if (r <= R) return 0.0;

	// geometric dip angle
	float dip = acos(R / r);

	// convert radians → TOD
	return dip / TAU;
}


float lerp_day_night(float tod, vec3 camera_pos){
	float w = day_night_transition_width;
	
	float off = tod_horizon_offset(camera_pos);
	float sunrise_center = 0.25 - off;
	float sunset_center  = 0.75 + off;
	
	float day_on = smoothstep(sunrise_center - w, sunrise_center + w, tod);
	float day_off = smoothstep(sunset_center - w, sunset_center + w, tod);
	
	return day_on * (1.0 - day_off);
}


void sky() {
	float tod = normalised_tod(POSITION);
	COLOR = mix(night_color, day_color, lerp_day_night(tod, POSITION));
	
	float horizon_dot = dot(EYEDIR, rotated_sun());
	if(horizon_dot > 1.0 - sun_horizon_size){
		float w = sun_horizon_time_band;
		
		float off = tod_horizon_offset(POSITION);
		float sunrise_center = 0.25 - off;
		float sunset_center  = 0.75 + off;
		
		// sunrise band
		float sunrise = smoothstep(sunrise_center - w, sunrise_center, tod) * (1.0 - smoothstep(sunrise_center, sunrise_center + w, tod));
		
		// sunset band
		float sunset  = smoothstep(sunset_center - w, sunset_center, tod) * (1.0 - smoothstep(sunset_center, sunset_center + w, tod));
		
		float time_fac = max(sunrise, sunset);
		float spatial_fac = smoothstep(1.0 - sun_horizon_size, 1.0, horizon_dot);
		//COLOR = mix(COLOR, sun_horizon_color, (1.0 - ((1.0 - horizon_dot)/sun_horizon_size)) * time_fac);
		COLOR = mix(COLOR, sun_horizon_color, spatial_fac * time_fac);
	}
	if(horizon_dot > 0.999) COLOR = sun_color;
}
