extends CharacterBody3D

class_name PlayerMovement

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var ground_check: RayCast3D = $GroundCheck

@export var speed = 5.0
@export var sprint_speed = 8.0
@export var jump_velocity = 4.5
@export var sensetivity = 0.005;

#viewbob
const BOB_FREQ = 2.5
const BOB_AMP = 0.05
var t_bob : float = 0.0

signal bob_top
signal bob_bottom

var debug_mode = true



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_SEMICOLON):
		debug_mode = !debug_mode
		if debug_mode:
			collision_shape_3d.disabled = true
		else:
			collision_shape_3d.disabled = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate(global_position.normalized(), -event.relative.x * sensetivity)
		camera_pivot.rotate_x(-event.relative.y * sensetivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _process(delta: float) -> void:
	var rel_v = transform.basis.inverse() * velocity
	
	# input
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	up_direction = global_position.normalized()
	
	if ground_check.is_colliding():
		if direction:
			rel_v.x = direction.x * get_speed()
			rel_v.z = direction.z * get_speed()
		else:
			rel_v.x = lerp(rel_v.x, direction.x * get_speed(), delta * 10)
			rel_v.z = lerp(rel_v.z, direction.z * get_speed(), delta * 10)
	else:
		rel_v.x = lerp(rel_v.x, direction.x * get_speed(), delta * 2)
		rel_v.z = lerp(rel_v.z, direction.z * get_speed(), delta * 2)
	
	# viewbob
	t_bob += delta * rel_v.length() * float(ground_check.is_colliding())
	var b : float = bob_calc(t_bob)
	camera.transform.origin = Vector3(0, b, 0)
	
	# bob signals
	if b/BOB_AMP < 0.05:
		bob_bottom.emit()
	elif b/BOB_AMP > 0.95:
		bob_top.emit()
	
	
	rel_v = transform.basis.inverse() * (transform.basis * rel_v).slide(position.normalized()) # project velocity to planet
	align_to_planet()
	
	# gravity
	if not ground_check.is_colliding() and !debug_mode:
		rel_v.y = (transform.basis.inverse() * velocity).y - 9.8 * delta
	if debug_mode:
		rel_v.y = (int(Input.is_key_pressed(KEY_SPACE)) - int(Input.is_key_pressed(KEY_CTRL))) * get_speed()
	
	# jump
	if Input.is_action_just_pressed("jump") and ground_check.is_colliding():
		if input_dir.y < 0 or input_dir == Vector2.ZERO:
			rel_v.y = jump_velocity
	
	velocity = transform.basis * rel_v
	
	var dist_to_ground = ground_check.get_collision_point().distance_to(ground_check.global_position)
	if ground_check.is_colliding() and dist_to_ground < 0.2: global_position += global_position.normalized() * (0.2 - dist_to_ground)
	
	move_and_slide()


func bob_calc(time : float) -> float:
	return BOB_AMP * sin(time * BOB_FREQ)


func align_to_planet():
	var planet_up: Vector3 = position.normalized()
	
	var forward: Vector3 = -transform.basis.z
	forward = forward.slide(planet_up).normalized()
	
	if forward.length() < 0.0001:
		forward = -transform.basis.z.cross(planet_up).cross(planet_up).normalized()
	
	var right: Vector3 = forward.cross(planet_up).normalized()
	
	transform.basis = Basis(right, planet_up, -forward)


func get_speed() -> float:
	var s = speed if not Input.is_action_pressed("sprint") else sprint_speed
	
	if debug_mode:
		s *= 10
		if Input.is_action_pressed("sprint"): s *= 5
	
	return s
