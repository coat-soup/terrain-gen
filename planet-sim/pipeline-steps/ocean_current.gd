extends RefCounted
class_name OceanCurrent

enum CurrentType {NEUTRAL, WARM, COLD}
var type : CurrentType = CurrentType.NEUTRAL

var cells : Array[int]

func _to_string() -> String:
	var s = ""
	for c in cells: s += "%d," % c
	
	return "[" + s + "]"


func flow(sim_cells : Array[CellData], vector_axis : Vector3):
	var dir : Vector3 = sim_cells[cells[0]].unit_pos.cross(vector_axis)
	var error : Vector3 = Vector3.ZERO
	var head_path_dir := Vector3.ZERO
	var lagging_path_dir := Vector3.ZERO
	var path_dir_size := 5
	
	while(cells.size() < 500 and (cells.size() < 10 or sim_cells[cells[0]].unit_pos.distance_to(sim_cells[cells[-1]].unit_pos) > 0.1)):
		var path_iter = get_neighbour_bresenham(dir, sim_cells[cells[-1]], sim_cells, error, true)
		error = path_iter.get("error")
		var next : int# = get_neighbour_in_direction(dir, sim_cells[cells[-1]], sim_cells)
		next = path_iter.get("next")
		if sim_cells[next].height > 0: break
		dir = sim_cells[next].unit_pos.cross(vector_axis)
		
		if cells.size() > path_dir_size * 2:
			head_path_dir = (sim_cells[cells[-1]].unit_pos - sim_cells[cells[-path_dir_size - 1]].unit_pos).normalized()
			lagging_path_dir = (sim_cells[cells[-path_dir_size - 1]].unit_pos - sim_cells[cells[-path_dir_size * 2 - 1]].unit_pos).normalized()
		
		if type != CurrentType.COLD and head_path_dir.dot(lagging_path_dir) < 0.0:
			backtrack(path_dir_size)
			break
		
		if cells.size() > 2 and type == CurrentType.COLD and sim_cells[next].current_type == 0: break # hit other current
		
		if type == CurrentType.WARM: vector_axis = vector_axis.move_toward(Vector3.UP, 0.035)
		if type == CurrentType.COLD:
			var dir_mult = -1.0 if sim_cells[cells[-1]].unit_pos.y > 0 else 1.0
			vector_axis = vector_axis.move_toward(sim_cells[cells[-1]].unit_pos.cross(dir_mult * Vector3.UP), 0.035)
		
		cells.append(next)
		sim_cells[next].current_type = type


func backtrack(steps : int):
	for i in range(steps):
		cells.remove_at(cells.size()-1)


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


static func get_neighbour_bresenham(global_dir: Vector3, cell: CellData, cells: Array[CellData], path_error: Vector3, force_oceanic : bool = false) -> Dictionary:
	# project global_dir onto tangent plane at current cell
	var tangent_dir = -(global_dir - cell.unit_pos * global_dir.dot(cell.unit_pos)).normalized()

	# add the accumulated error
	var effective_dir = (tangent_dir + path_error).normalized()

	# pick the neighbor whose direction best matches effective_dir
	var best_id : int = -1
	var best_dot : float = -9999.0  # higher dot = better alignment

	for n_id in cell.neighbours:
		if force_oceanic and cells[n_id].height > 0: continue
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
