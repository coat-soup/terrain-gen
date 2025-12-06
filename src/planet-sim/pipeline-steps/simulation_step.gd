@tool
extends Resource
class_name SimulationStep


func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	## ABSTRACT FUNCTION
	# extended classes will use this to manipulate the cell data
	return cells
