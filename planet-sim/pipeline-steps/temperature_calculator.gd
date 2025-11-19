@tool
extends SimulationStep
class_name TemperatureCalculator

@export var polar_temp : float = -40
@export var equator_temp : float = 40
@export var height_effect : float = 20.0


func simulate(cells : Array[CellData]) -> Array[CellData]:
	for cell in cells:
		cell.temperature = lerp(equator_temp, polar_temp, abs(cell.unit_pos.y))
		if cell.height > 0: cell.temperature -= cell.height * height_effect
	return cells
