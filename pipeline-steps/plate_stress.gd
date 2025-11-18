@tool
extends SimulationStep
class_name PlateStress

func simulate(cells : Array[CellData]) -> Array[CellData]:
	var plate_rotations : Array[Vector3] = []
	
	for cell in cells:
		if cell.plate_id >= plate_rotations.size():
			plate_rotations.resize(cell.plate_id + 1)
		
		if not plate_rotations[cell.plate_id]:
			plate_rotations[cell.plate_id] = random_unit_vector()
		
		cell.stress_rotation_direction = plate_rotations[cell.plate_id].cross(cell.unit_pos)
	
	for cell in cells:
		var stresses : Array[float] = []
		for neighbour_id in cell.neighbours:
			if cells[neighbour_id].plate_id != cell.plate_id:
				stresses.append(cell.stress_rotation_direction.dot(cells[neighbour_id].stress_rotation_direction))
		for s in stresses: cell.debug_neighbour_stress += s
		cell.debug_neighbour_stress /= max(1, stresses.size())
	
	return cells

static func random_unit_vector() -> Vector3:
	var z = randf_range(-1.0, 1.0)
	var a = randf() * TAU
	var r = sqrt(1.0 - z * z)
	return Vector3(r * cos(a), r * sin(a), z)
