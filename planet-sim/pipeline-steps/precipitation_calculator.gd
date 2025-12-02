@tool
extends SimulationStep
class_name PrecipitationCalculator



func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	for cell in cells:
		cell.precipitation = abs(cell.unit_pos.y)
	
	return cells
