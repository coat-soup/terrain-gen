extends Node
class_name TimeManager

@export var cycle_length : float = 24
@export var sun_light : DirectionalLight3D

@export var player_camera : Node3D

@export var day_light_color : Color
@export var night_light_color : Color
@export var horizon_light_color : Color

var sun_dir : Vector3 = Vector3(0.0, 0.0, 1.0)

var update_interval : int = 5
var ticks_to_update : int


func _physics_process(delta: float) -> void:
	ticks_to_update -= 1
	if ticks_to_update > 0: return
	ticks_to_update = update_interval
	
	var debug_speed_modifier : float = 100.0 if Input.is_key_pressed(KEY_BRACKETLEFT) else -100.0 if Input.is_key_pressed(KEY_BRACKETRIGHT) else 1.0
	
	sun_dir = sun_dir.rotated(Vector3.UP, debug_speed_modifier * update_interval * 2 * PI * delta / (60 * cycle_length))
	RenderingServer.global_shader_parameter_set("sun_dir", sun_dir)
	sun_light.look_at(-sun_dir)
	
	update_sun_light_color()


func frac(x):
	return x - floor(x)


func normalised_tod() -> float:
	var npos : Vector3 = player_camera.global_position.normalized()
	
	var p : Vector2 = Vector2(npos.x, npos.z).normalized()
	var s : Vector2 = Vector2(sun_dir.x, sun_dir.z).normalized()
	
	var angle : = atan2(p.x * s.y - p.y * s.x, p.dot(s))
	
	return frac((angle / TAU) + 0.5)


func update_sun_light_color() -> void:
	var transition_width := 0.03
	var horizon_band := 0.03
	
	var tod = normalised_tod()
	
	var sunrise : float = 0.25
	var sunset : float = 0.75
	
	var day_on : float = smoothstep(sunrise - transition_width, sunrise + transition_width, tod)
	var day_off : float = smoothstep(sunset - transition_width, sunset + transition_width, tod)
	var day_factor : float = day_on * (1.0 - day_off)
	
	var sunrise_band : float = smoothstep(sunrise - horizon_band, sunrise, tod) * (1.0 - smoothstep(sunrise, sunrise + horizon_band, tod))
	var sunset_band : float = smoothstep(sunset - horizon_band, sunset, tod) * (1.0 - smoothstep(sunset, sunset + horizon_band, tod))
	var horizon_factor : float = max(sunrise_band, sunset_band)
	
	var color := night_light_color.lerp(day_light_color, 1.0)
	color = color.lerp(horizon_light_color, horizon_factor)
	
	sun_light.light_color = color
	sun_light.light_energy = day_factor;
