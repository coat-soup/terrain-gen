@tool
extends SimulationStep
class_name WindCalculator

@export var n_cyclones : int = 6
@export var cyclone_latitude : float = 30.0
@export var cyclone_size : float = 0.2
@export var cyclone_falloff_distance : float = 0.3
@export_range(0.0, 0.5) var polar_cyclone_size : float = 0.2
@export var cyclone_lat_amplitude : float = 4.0
@export var slope_effect : float = 0.5

func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	var cyclones : Array[Vector3]
	
	for i in range(n_cyclones):
		var lon = i * (360.0 / n_cyclones)
		
		var lat_offset = sin(deg_to_rad(lon * 1.5)) * cyclone_lat_amplitude
		
		cyclones.append(lat_lon_to_vec(cyclone_latitude + lat_offset, lon))
		cyclones.append(lat_lon_to_vec(-cyclone_latitude + lat_offset, lon))
		
	cyclones.append(Vector3.UP * polar_cyclone_size)
	cyclones.append(-Vector3.UP * polar_cyclone_size)
	
	for cell in cells:
		var closest_cyclone = 0
		var b_dist = -1
		
		for i in range(cyclones.size()):
			var dist = cell.unit_pos.distance_to(cyclones[i]) / cyclones[closest_cyclone].length()
			if b_dist == -1 or dist < b_dist:
				closest_cyclone = i
				b_dist = dist
		
		var cyclone_dir = cell.unit_pos.cross(cyclones[closest_cyclone] * (1.0 if cyclones[closest_cyclone].y > 0 else -1.0)).normalized()
		
		var real_size
		
		if b_dist <= cyclone_size:
			cell.wind_dir = cyclone_dir
		else:
			var equator_mult = 1.0 if cell.unit_pos.y > 0 else -1.0
			var equator_lerp = clamp((b_dist - cyclone_size) / cyclone_falloff_distance, 0.0, 1.0)
			if abs(cell.unit_pos.y) > abs(cyclones[closest_cyclone].y): equator_lerp *= 0
			cell.wind_dir = lerp(cyclone_dir, cell.unit_pos.cross(cell.unit_pos.cross(Vector3.UP * equator_mult)), equator_lerp).normalized()
		cell.wind_dir = (cell.wind_dir + cell_height_gradient(cell, cells) * slope_effect).normalized() # add height gradient
		cell.wind_dir = (cell.wind_dir - cell.unit_pos * cell.wind_dir.dot(cell.unit_pos)).normalized() # project back onto surface
		
		# speed calcs
		var pressure = sin(PI * (b_dist / cyclone_falloff_distance)) ** 2.0
		var latitude = sin(PI * abs(cell.unit_pos.y))
		var coriolis = abs(cell.unit_pos.y)
		cell.wind_dir *= (pressure + latitude + coriolis + max(0, cell.height)) / 4.0
		
	return cells


static func lat_lon_to_vec(lat_deg: float, lon_deg: float) -> Vector3:
	var lat = deg_to_rad(lat_deg)
	var lon = deg_to_rad(lon_deg)
	var x = cos(lat) * cos(lon)
	var y = sin(lat)
	var z = cos(lat) * sin(lon)
	return Vector3(x, y, z).normalized()


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
