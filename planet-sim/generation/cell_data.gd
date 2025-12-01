extends RefCounted
class_name CellData

var id : int
var neighbours : Array[int]

var unit_pos : Vector3

var height : float = 0.0

var plate_id : int = -1
var is_oceanic : bool = false
var stress_rotation_direction : Vector3
var debug_neighbour_stress : float = 0.0
var temperature : float = 0
var current_type : int = -100

func _init(cell_id : int, pos : Vector3) -> void:
	id = cell_id
	unit_pos = pos
