@tool
extends SimulationStep
class_name TemperatureCalculator

@export var polar_temp : float = -40
@export var equator_temp : float = 40
@export var height_effect : float = 20.0


func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	for cell in cells:
		cell.temperature = lerp(equator_temp, polar_temp, abs(latitude(cell)) / 90)
		if cell.height > 0: cell.temperature -= cell.height * height_effect
	return cells


func latitude(cell : CellData) -> float:
	var lat_rad = asin(cell.unit_pos.y)
	return rad_to_deg(lat_rad)
