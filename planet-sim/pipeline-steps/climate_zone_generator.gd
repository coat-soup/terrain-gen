@tool
extends SimulationStep
class_name ClimateZoneGenerator

@export var climate_zones : Array[ClimateZone]


func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	for i in range(climate_zones.size()):
		var climate : ClimateZone = climate_zones[i]
		for cell in cells:
			var lat = latitude(cell)
			if abs(lat) > climate.latitude_range: continue
			if cell.temperature < climate.temperature_range.x or cell.temperature > climate.temperature_range.y: continue
			if cell.precipitation < climate.precipitation_range.x or cell.precipitation > climate.precipitation_range.y: continue
			cell.climate_zone_id = i
	
	return cells

func latitude(cell : CellData) -> float:
	var lat_rad = asin(cell.unit_pos.y)
	return rad_to_deg(lat_rad)
