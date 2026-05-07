@tool
extends SimulationStep
class_name LandformGenerator

@export var landforms : Array[Landform]


func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	for i in range(landforms.size()):
		var landform : Landform = landforms[i]
		for cell in cells:
			if cell.height < landform.upliftRange.x or cell.height > landform.upliftRange.y: continue
			if cell.precipitation < landform.precipitationRange.x or cell.precipitation > landform.precipitationRange.y: continue
			if cell.temperature < landform.temperatureRange.x or cell.temperature > landform.temperatureRange.y: continue
			if cell.wind_dir.length() < landform.windRange.x or cell.wind_dir.length() > landform.windRange.y: continue
			if cell.magma < landform.magmaRange.x or cell.magma > landform.magmaRange.y: continue
			if landform.riverDistance >= 0 and not river_in_range(cells, cell, landform.riverDistance): continue
			cell.landform_id = i
	
	return cells


func latitude(cell : CellData) -> float:
	var lat_rad = asin(cell.unit_pos.y)
	return rad_to_deg(lat_rad)


func river_in_range(cells : Array[CellData], cell : CellData, dist : int) -> bool:
	if cell.water_content > 0: return true
	
	if dist > 0:
		for n in cell.neighbours:
			if river_in_range(cells, cells[n], dist-1): return true
	
	return false
