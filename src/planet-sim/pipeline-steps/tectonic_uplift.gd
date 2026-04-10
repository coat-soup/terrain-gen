@tool
extends SimulationStep
class_name TectonicUplift

@export_range(1, 80) var neighbour_reach : int = 16


func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	var plate_rotations : Array[Vector3] = []
	
	for cell in cells:
		if cell.plate_id >= plate_rotations.size():
			plate_rotations.resize(cell.plate_id + 1)
		
		if not plate_rotations[cell.plate_id]:
			plate_rotations[cell.plate_id] = random_unit_vector()
		
		cell.stress_rotation_direction = plate_rotations[cell.plate_id].cross(cell.unit_pos).normalized()
	
	for d in neighbour_reach:
		for cell in cells:
			if cell.debug_neighbour_stress != 0:
				continue
			
			var stress := 0.0
			var n_stressing = 0
			
			var has_stressed_neighbour = false
			for n in cell.neighbours:
				if d == 0 and cells[n].plate_id != cell.plate_id:
					stress += cell.stress_rotation_direction.dot(cells[n].stress_rotation_direction)
					n_stressing += 1
				elif d > 0 and d > cells[n].distance_to_plate_boundary and cells[n].debug_neighbour_stress != 0:
					stress += cells[n].debug_neighbour_stress
					n_stressing += 1
				
			if n_stressing != 0:
				cell.distance_to_plate_boundary = d
				
				stress /= float(n_stressing)
				stress *= (1.0 - (float(d)/float(neighbour_reach)))
				
				cell.debug_neighbour_stress = stress
	
	return cells


static func random_unit_vector() -> Vector3:
	var z = randf_range(-1.0, 1.0)
	var a = randf() * TAU
	var r = sqrt(1.0 - z * z)
	return Vector3(r * cos(a), r * sin(a), z)
