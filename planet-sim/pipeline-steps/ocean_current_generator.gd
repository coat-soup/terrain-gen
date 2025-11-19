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
	
	sim.ocean_currents.append(OceanCurrent.new())
	sim.ocean_currents[0].cells.append(equator_cell)
	return cells
