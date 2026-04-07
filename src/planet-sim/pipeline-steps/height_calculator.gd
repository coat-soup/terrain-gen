@tool
extends SimulationStep
class_name HeightCalculator

@export var oceanic_height = -0.5;
@export var continental_height = 0.01;
@export var continent_blur_steps : int = 2
@export var stress_height : float = 4.0
@export var volcano_threshold : float = 0.7

func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	for cell in cells:
		cell.height = oceanic_height if cell.is_oceanic else continental_height
	
	for i in range(continent_blur_steps):
		blur(cells)
	
	for i in range(cells.size()):
		# plate stress
		if !cells[i].is_oceanic:
			cells[i].height += cells[i].debug_neighbour_stress * stress_height
		else:
			cells[i].height += abs(cells[i].debug_neighbour_stress) * stress_height * cells[i].magma * 5
		
		if cells[i].magma > volcano_threshold: cells[i].height += cells[i].magma - volcano_threshold
	
	return cells


func blur(cells : Array[CellData]) -> Array[CellData]:
	# blur
	var new_heights : Array[float] = []
	new_heights.resize(cells.size())
	for i in range(cells.size()):
		new_heights[i] = cells[i].height
		for n_id in cells[i].neighbours:
			new_heights[i] += cells[n_id].height
		new_heights[i] /= cells[i].neighbours.size() + 1
		#cells[i].height = new_heights[i] # debug override mid-change for more blur blur
	
	
	for i in range(cells.size()):
		cells[i].height = new_heights[i]
	return cells
