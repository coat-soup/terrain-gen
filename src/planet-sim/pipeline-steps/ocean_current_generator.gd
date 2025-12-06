@tool
extends SimulationStep
class_name OceanCurrentGenerator

@export var equatorial_counter_current_distance : float = 0.3
@export var min_current_length : int = 10
@export_range(0.0,1.0) var polwards_current_momentum : float = 0.5

func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	var equator_mid : int = 0
	var equator_north : int = 0
	var equator_south : int = 0
	
	# find a cell on the equator
	for i in range(cells.size()):
		for n_id in cells[i].neighbours:
			if equator_north == 0 and cells[n_id].unit_pos.y < equatorial_counter_current_distance: equator_north = n_id
			if equator_mid == 0 and cells[n_id].unit_pos.y < 0: equator_mid = n_id
			if equator_south == 0 and cells[n_id].unit_pos.y < -equatorial_counter_current_distance : equator_south = n_id
		if equator_north != 0 and equator_mid != 0 and equator_south != 0: break
		# it's ok if 0 is an equator cell we skip, there will be other cells on the equator
	
	
	#make_equatorial_band(find_ocean_start_from_equator(equator_mid, cells), 1.0, cells, sim)
	make_equatorial_band(find_ocean_start_from_equator(equator_north, cells), -1.0, cells, sim)
	#make_equatorial_band(find_ocean_start_from_equator(equator_south, cells), -1.0, cells, sim)
	
	# remove small currents
	for i in range(sim.ocean_currents.size() - 1, -1, -1):
		if sim.ocean_currents[i].cells.size() < min_current_length:
			sim.ocean_currents.remove_at(i)
	
	
	# make polward currents
	var n_equatorial = sim.ocean_currents.size()
	for i in range(n_equatorial):
		for start_cell in [sim.ocean_currents[i].cells[min_current_length/2], sim.ocean_currents[i].cells[-min_current_length/2]]:
			for dir_mult in [1.0, -1.0]:
				var current_n : OceanCurrent = OceanCurrent.new()
				sim.ocean_currents.append(current_n)
				current_n.type = OceanCurrent.CurrentType.WARM
				current_n.cells.append(start_cell)
				current_n.flow(cells, lerp(cells[start_cell].unit_pos.cross(dir_mult * Vector3.UP), -Vector3.UP, polwards_current_momentum))
	
	
	# make returning currents
	for i in range(n_equatorial, sim.ocean_currents.size()):
		var current : OceanCurrent = OceanCurrent.new()
		sim.ocean_currents.append(current)
		current.type = OceanCurrent.CurrentType.COLD
		current.cells.append(sim.ocean_currents[i].cells[-1])
		var dir_mult = -1.0 if cells[current.cells[0]].unit_pos.y > 0 else 1.0
		current.flow(cells, lerp(cells[current.cells[0]].unit_pos.cross(dir_mult * Vector3.UP), Vector3.UP, polwards_current_momentum / 2))
	
	return cells


func find_ocean_start_from_equator(pointer_cell : int, cells) -> int:
	var dir_multiplier : float = 1.0 if cells[pointer_cell].height > 0 else -1.0
	var path_error : Vector3 = Vector3.ZERO
	for i in range(500):
		var c = OceanCurrent.get_neighbour_in_direction(cells[pointer_cell].unit_pos.cross(dir_multiplier * Vector3.UP), cells[pointer_cell], cells)
		if dir_multiplier > 0:
			pointer_cell = c
			if cells[c].height <= 0: break
		else:
			if cells[c].height > 0: break
			pointer_cell = c
		
		var path_iter = OceanCurrent.get_neighbour_bresenham(cells[pointer_cell].unit_pos.cross(dir_multiplier * Vector3.UP), cells[pointer_cell], cells, path_error)
		pointer_cell = path_iter.get("next")
		path_error = path_iter.get("error")
	return pointer_cell


func make_equatorial_band(starting_cell : int, direction: float, cells : Array[CellData], sim):
	var pointer_cell : int = starting_cell
	var i := 0
	var path_error : Vector3 = Vector3.ZERO
	while(i < 2000): # hard limit to avoid spiraling
		i += 1
		# check finished global circumference
		var angle_to_finish = rad_to_deg(cells[starting_cell].unit_pos.signed_angle_to(cells[pointer_cell].unit_pos, Vector3.UP))
		if angle_to_finish < 0 and angle_to_finish > -30.0 and i > 40: break
		
		# if at ocean make a current
		if cells[pointer_cell].height < 0:
			# propagate current
			var current = OceanCurrent.new()
			sim.ocean_currents.append(current)
			current.cells.append(pointer_cell)
			current.flow(cells, Vector3.UP * direction)
			
			# update pointer
			i += sim.ocean_currents[-1].cells.size()
			pointer_cell = current.cells[-1]
			path_error = Vector3.ZERO
		
		#step towards next ocean
		var path_iter = OceanCurrent.get_neighbour_bresenham(cells[pointer_cell].unit_pos.cross(direction * Vector3.UP), cells[pointer_cell], cells, path_error)
		pointer_cell = path_iter.get("next")
		path_error = path_iter.get("error")
