@tool
extends SimulationStep
class_name Magma

@export var noise_min : float = 0.0
@export var noise_max : float = 0.4
@export var noise_frequency : float = 1.0
@export var mask_frequency : float = 1.0
@export var detail_frequency : float = 1.0

@export var noise : FastNoiseLite

func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	noise.seed = randi()
	
	for cell in cells:                                                              # noise from (-1,1) -> (noise_max, noise_min)
		cell.magma = noise_min + (noise.get_noise_3dv(cell.unit_pos * noise_frequency) / 2.0 + 0.5) * (noise_max - noise_min)
		cell.magma *= noise.get_noise_3dv((cell.unit_pos + Vector3(1000,1000,1000)) * mask_frequency)
		if cell.magma < 0: cell.magma = 0
		cell.magma *= noise.get_noise_3dv(cell.unit_pos * detail_frequency)
		if cell.magma <= 0: cell.magma = 0
		
		#cell.magma = (cell.magma * 3) ** 2
	
	return cells
