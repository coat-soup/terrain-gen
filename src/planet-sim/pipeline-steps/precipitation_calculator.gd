@tool
extends SimulationStep
class_name PrecipitationCalculator

@export var ocean_boundary_cutoff : int = 10


func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	var cutoff : float = 10
	for step in sim.pipeline:
		var boundary_calculator = step as OceanBoundaryCalculator
		if boundary_calculator: cutoff = boundary_calculator.distance_cutoff
	
	cutoff = min(cutoff, ocean_boundary_cutoff)
	
	for cell in cells:
		var ocean_dir = HeightGradientCalculator.get_boundary_dir(cell, cells).normalized()
		cell.precipitation = (
			(cell.wind_dir.length()
			* max(0, (1.0 - float(cell.distance_to_ocean_boundary)/cutoff)))
			#* cell.height_gradient.length()
			* max(0.0001, ocean_dir.dot(-cell.wind_dir.normalized()))
			#* 4
		)
		
		#cell.precipitation = max(0, (1.0 - float(cell.distance_to_ocean_boundary)/cutoff))
		
		#cell.precipitation = cell.height_gradient.length()
		
		#cell.precipitation = max(0.0, ocean_dir.dot(-cell.wind_dir.normalized()))
		
		#cell.precipitation = cell.wind_dir.length()
		
	#fill(cells)
	blur(cells)
		
	return cells



func fill(cells : Array[CellData]) -> Array[CellData]:
	var new_precips : Array[float] = []
	new_precips.resize(cells.size())
	for i in range(cells.size()):
		new_precips[i] = cells[i].precipitation
		for n_id in cells[i].neighbours:
			if cells[n_id].precipitation > 0:
				new_precips[i] = cells[n_id].precipitation
				break
		#cells[i].precipitation = new_precips[i] # debug override mid-change for more blur blur
	
	
	for i in range(cells.size()):
		cells[i].precipitation = new_precips[i]
	return cells



func blur(cells : Array[CellData]) -> Array[CellData]:
	# blur
	var new_precips : Array[float] = []
	new_precips.resize(cells.size())
	for i in range(cells.size()):
		new_precips[i] = cells[i].precipitation
		for n_id in cells[i].neighbours:
			new_precips[i] += cells[n_id].precipitation
		new_precips[i] /= cells[i].neighbours.size() + 1
		#cells[i].precipitation = new_precips[i] # debug override mid-change for more blur blur
	
	
	for i in range(cells.size()):
		cells[i].precipitation = new_precips[i]
	return cells
