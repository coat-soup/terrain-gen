@tool
extends SimulationStep
class_name PlateGenerator

@export var n_plates : int = 25
@export var ocean_ratio := 0.6
@export var spread_chance : float = 0.2
var plates : Array[int] # array of int where 0 = continental, 1 = oceanic


func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	assert(n_plates <= cells.size())
	
	var assigned_cells : int = 0
	
	plates.resize(n_plates)
	
	# randomly select initial cells
	for i in range(plates.size()):
		if randf() < ocean_ratio: plates[i] = 1
		else: plates[i] = 0
		
		var selected_cell : CellData = null
		while not selected_cell or selected_cell.plate_id != -1:
			selected_cell = cells.pick_random()
		selected_cell.plate_id = i
		selected_cell.is_oceanic = plates[i] == 1
		assigned_cells += 1
		
	
	print("plates: ", plates)
	
	while assigned_cells < cells.size():
		for i in range(cells.size()):
			if cells[i].plate_id != -1: continue
			for neighbour_id in cells[i].neighbours:
				if cells[neighbour_id].plate_id != -1 and randf() < spread_chance:
					cells[i].plate_id = cells[neighbour_id].plate_id
					cells[i].is_oceanic = plates[cells[i].plate_id] == 1
					assigned_cells += 1
					break
	
	return cells
