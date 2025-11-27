extends RefCounted
class_name OceanCurrent

enum CurrentType {NEUTRAL, WARM, COLD}
var type : CurrentType = CurrentType.NEUTRAL

var cells : Array[int]

func _to_string() -> String:
	var s = ""
	for c in cells: s += "%d," % c
	
	return "[" + s + "]"


func flow(tot_cells : Array[CellData]):
	var dir : Vector3 = tot_cells[cells[0]].unit_pos.cross(Vector3.UP)
	while(cells.size() < 10 or tot_cells[cells[0]].unit_pos.distance_to(tot_cells[cells[-1]].unit_pos) > 0.1):
		var next : int = get_neighbour_in_direction(dir, tot_cells[cells[-1]], tot_cells)
		if tot_cells[next].height >= 0: break
		dir = tot_cells[next].unit_pos.cross(Vector3.UP)
		cells.append(next)



	#global_dir: global direction on the sphere (not just left/right/up/down)
static func get_neighbour_in_direction(global_dir : Vector3, cell : CellData, cells : Array[CellData]) -> int:
	var neighbour : int = 0
	var smallest_dot : float = 5.0
	
	for neighbour_id in cell.neighbours:
		var dot = (cells[neighbour_id].unit_pos - cell.unit_pos).normalized().dot(global_dir.normalized())
		if dot < smallest_dot:
			smallest_dot = dot
			neighbour = neighbour_id
	return neighbour
