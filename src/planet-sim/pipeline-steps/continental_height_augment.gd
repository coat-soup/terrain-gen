@tool
extends SimulationStep
class_name ContinentalHeightAugment

@export var noise_scale : float = 1.0
@export var noise_frequency : float = 1.0

@export var noise : FastNoiseLite

func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	noise.seed = randi()
	
	for cell in cells:
		cell.height += noise.get_noise_3dv(cell.unit_pos * noise_frequency) * noise_scale
	
	return cells
