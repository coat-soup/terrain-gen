extends RefCounted
class_name OceanCurrent

enum CurrentType {NEUTRAL, WARM, COLD}
var type : CurrentType = CurrentType.NEUTRAL

var cells : Array[int]

func _to_string() -> String:
	var s = ""
	for c in cells: s += "%d," % c
	
	return "[" + s + "]"


func flow(tot_cells : Array[CellData], vector_axis : Vector3):
	var dir : Vector3 = tot_cells[cells[0]].unit_pos.cross(vector_axis)
	var error : Vector3 = Vector3.ZERO
	while(cells.size() < 10 or tot_cells[cells[0]].unit_pos.distance_to(tot_cells[cells[-1]].unit_pos) > 0.1):
		var path_iter = get_neighbour_bresenham(dir, tot_cells[cells[-1]], tot_cells, error)
		error = path_iter.get("error")
		var next : int = get_neighbour_in_direction(dir, tot_cells[cells[-1]], tot_cells)
		next = path_iter.get("next")
		if tot_cells[next].height >= 0: break
		dir = tot_cells[next].unit_pos.cross(vector_axis)
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


static func get_neighbour_bresenham(global_dir: Vector3, cell: CellData, cells: Array[CellData], path_error: Vector3) -> Dictionary:
	# project global_dir onto tangent plane at current cell
	var tangent_dir = -(global_dir - cell.unit_pos * global_dir.dot(cell.unit_pos)).normalized()

	# add the accumulated error
	var effective_dir = (tangent_dir + path_error).normalized()

	# pick the neighbor whose direction best matches effective_dir
	var best_id : int = -1
	var best_dot : float = -9999.0  # higher dot = better alignment

	for n_id in cell.neighbours:
		var v = (cells[n_id].unit_pos - cell.unit_pos).normalized()
		var d = v.dot(effective_dir)
		if d > best_dot:
			best_dot = d
			best_id = n_id

	# compute actual movement direction we took
	var move_vec = (cells[best_id].unit_pos - cell.unit_pos).normalized()

	# update the error
	path_error += effective_dir - move_vec

	# clamp error to avoid runaway accumulation
	if path_error.length() > 1.0:
		path_error = path_error.normalized()

	return {"next" : best_id, "error" : path_error}
