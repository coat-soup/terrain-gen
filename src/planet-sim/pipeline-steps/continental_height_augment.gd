@tool
extends SimulationStep
class_name ContinentalHeightAugment

@export var noise_min : float = 0.0
@export var noise_max : float = 0.4
@export var noise_frequency : float = 1.0

@export var noise : FastNoiseLite

func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	noise.seed = randi()
	
	for cell in cells:                                                              # noise from (-1,1) -> (noise_max, noise_min)
		cell.height += noise_min + (noise.get_noise_3dv(cell.unit_pos * noise_frequency) / 2.0 + 0.5) * (noise_max - noise_min)
	
	return cells
