extends RefCounted
class_name CellData

var id : int
var neighbours : Array[int]

var plate_id : int = -1

func _init(cell_id : int) -> void:
	id = cell_id
	plate_id = -1
