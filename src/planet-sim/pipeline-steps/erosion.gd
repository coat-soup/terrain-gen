@tool
extends SimulationStep
class_name Erosion

@export_range(1, 60) var iterations : int = 1
@export var strength : float = 0.3


func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	var new_heights : Array[float]
	new_heights.resize(cells.size())
	for i in range(cells.size()):
		new_heights[i] = cells[i].height
	
	for d in range(iterations):
		for i in range(cells.size()):
			var lowest_neighbour = -1
			for n in cells[i].neighbours:
				if lowest_neighbour == -1 or cells[lowest_neighbour].height < cells[n].height: lowest_neighbour = n
			if cells[i].height > cells[lowest_neighbour].height: continue
			var slope = cells[i].height - cells[lowest_neighbour].height
			var movement = strength * slope
			new_heights[i] -= movement
			new_heights[lowest_neighbour] += movement
	
		for i in range(cells.size()):
			cells[i].height = new_heights[i]
	
	return cells
