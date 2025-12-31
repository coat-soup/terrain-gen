extends Node3D
@export var player : Node3D

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_H): global_transform = player.global_transform
