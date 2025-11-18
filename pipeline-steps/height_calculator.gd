@tool
extends SimulationStep
class_name HeightCalculator

@export var blur_steps : int = 2


func simulate(cells : Array[CellData]) -> Array[CellData]:
	for cell in cells:
		cell.height = -1.0 if cell.is_oceanic else 0.5
		print("setting cell height: ", cell.height)
	
	for i in range(cells.size()):
		# plate stress
		cells[i].height += cells[i].debug_neighbour_stress * 2
	
	for i in range(blur_steps):
		blur(cells)
	
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
