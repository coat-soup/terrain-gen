extends RefCounted
class_name OceanCurrent

enum CurrentType {NEUTRAL, WARM, COLD}
var type : CurrentType = CurrentType.NEUTRAL

var cells : Array[int]

func _to_string() -> String:
	var s = ""
	for c in cells: s += "%d," % c
	
	return "[" + s + "]"
