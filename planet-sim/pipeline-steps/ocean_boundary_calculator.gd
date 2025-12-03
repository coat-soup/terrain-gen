@tool
extends SimulationStep
class_name OceanBoundaryCalculator

@export_range(0,30) var distance_cutoff : int = 8

func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	for cell in cells:
		for n_id in cell.neighbours:
			if max(cells[n_id].height, cell.height) > 0 and min(cells[n_id].height, cell.height) < 0:
				cell.distance_to_ocean_boundary = 0
				break
	
	for i in range(distance_cutoff):
		for cell in cells:
			if cell.distance_to_ocean_boundary != -1: continue
			for n_id in cell.neighbours:
				if cells[n_id].distance_to_ocean_boundary == i:
					cell.distance_to_ocean_boundary = i + 1
					break
			if i == distance_cutoff - 1 and cell.distance_to_ocean_boundary == -1:
				cell.distance_to_ocean_boundary = distance_cutoff
	
	return cells
