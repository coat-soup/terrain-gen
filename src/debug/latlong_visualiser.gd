@tool
extends Node

@export_range(-90, 90) var latitude : float = 0.0
@export_range(-180, 180) var longitude : float = 0.0
@export var marker : Node3D

func _process(delta: float) -> void:
	if marker != null:
		marker.global_position = Util.LatLongToPosition(latitude, longitude, 1.0)
