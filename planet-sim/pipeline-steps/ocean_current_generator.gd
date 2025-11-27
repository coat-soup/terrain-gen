@tool
extends SimulationStep
class_name OceanCurrentGenerator


func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	var equator_cell : int = 0
	for i in range(cells.size()):
		if cells[i].unit_pos.y >= 0:
			for n_id in cells[i].neighbours:
				if cells[n_id].unit_pos.y < 0:
					equator_cell = n_id
					break
		if equator_cell != 0: break
		# it's ok if 0 is an equator cell we skip, there will be other cells on the equator
	
	print("set initial equator cell to ", equator_cell)
	
	var dir_multiplier : float = 1.0 if cells[equator_cell].height > 0 else -1.0
	
	print("dirmult: ", dir_multiplier)
	
	for i in range(500):
		var c = OceanCurrent.get_neighbour_in_direction(cells[equator_cell].unit_pos.cross(dir_multiplier * Vector3.UP), cells[equator_cell], cells)
		if dir_multiplier > 0:
			equator_cell = c
			if cells[c].height < 0: break
		else:
			if cells[c].height >= 0: break
			equator_cell = c
		
		equator_cell = c
	
	sim.ocean_currents.append(OceanCurrent.new())
	sim.ocean_currents[0].cells.append(equator_cell)
	
	sim.ocean_currents[0].flow(cells)
	
	return cells
