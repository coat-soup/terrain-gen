@tool
extends SimulationStep
class_name HeightGradientCalculator

func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	for cell in cells:
		cell.height_gradient = cell_height_gradient(cell, cells)
		
	return cells


static func cell_height_gradient(cell : CellData, cells : Array[CellData]):
	var gradient = Vector3.ZERO
	for n_id in cell.neighbours:
		var n = cells[n_id]
		var n_pos = n.unit_pos
		var nh = max(0, n.height)
		
		var dir = (n_pos - cell.unit_pos).normalized()
		var dh = nh - max(0, cell.height)     # >0 = uphill, <0 = downhill
	
		# accumulate downhill directions
		if dh < 0:
			gradient += dir * abs(dh)
	
	return gradient


static func cell_ocean_boundary_gradient(cell : CellData, cells : Array[CellData], boundary_cutoff : float = 10):
	var gradient = Vector3.ZERO
	for n_id in cell.neighbours:
		var n = cells[n_id]
		var n_pos = n.unit_pos
		var nh = n.distance_to_ocean_boundary
		
		var dir = (n_pos - cell.unit_pos).normalized()
		var dh = nh - cell.distance_to_ocean_boundary/boundary_cutoff     # >0 = uphill, <0 = downhill
	
		# accumulate downhill directions
		if dh < 0:
			gradient += dir * abs(dh)
	
	return (gradient - cell.unit_pos * gradient.dot(cell.unit_pos)) # project back onto surface


static func get_boundary_dir(cell : CellData, cells : Array[CellData]) -> Vector3:
	var highest = -1
	var lowest = -1
	
	for n_id in cell.neighbours:
		if highest == -1 or cells[n_id].distance_to_ocean_boundary > cells[highest].distance_to_ocean_boundary: highest = n_id
		if lowest == -1 or cells[n_id].distance_to_ocean_boundary < cells[lowest].distance_to_ocean_boundary: lowest = n_id
	
	
	var dir = (cells[lowest].unit_pos - cells[highest].unit_pos)
	return (dir - cell.unit_pos * dir.dot(cell.unit_pos)).normalized() # project flat
