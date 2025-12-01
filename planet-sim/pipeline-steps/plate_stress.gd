@tool
extends SimulationStep
class_name PlateStress

@export_range(1, 10) var neighbour_reach : int = 2
@export_range(0,10) var falloff : float = 3

func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	var plate_rotations : Array[Vector3] = []
	
	for cell in cells:
		if cell.plate_id >= plate_rotations.size():
			plate_rotations.resize(cell.plate_id + 1)
		
		if not plate_rotations[cell.plate_id]:
			plate_rotations[cell.plate_id] = random_unit_vector()
		
		cell.stress_rotation_direction = plate_rotations[cell.plate_id].cross(cell.unit_pos).normalized()
	
	for cell in cells:
		var stress := 0.0
		
		var dist_to_fault = neighbour_reach
		
		var neighbours = get_stressing_neighbours(cells, cell.id)
		# assume weight is 1/falloff^n where n is depth (eg immediate neighbours weight = 1, 1 gap neighbours = 1/2, 2 gap neighbours = 1/4, etc.)
		var total_weight := 0.0
		
		for i in range(neighbours.size()):
			for j in range(neighbours[i].size()):
				if cells[neighbours[i][j]].plate_id == cell.plate_id: continue
				stress += cell.stress_rotation_direction.dot(cells[neighbours[i][j]].stress_rotation_direction)# / pow(falloff,i)
				total_weight += 1.0#/pow(falloff,i)
				if dist_to_fault > i:
					dist_to_fault = i
					#print("setting plate dist: ", i)
		#print()
		
		cell.debug_neighbour_stress = stress / max(1, total_weight)
		#cell.debug_neighbour_stress *= 1.0 if neighbour_reach <= 2 else 2
		cell.debug_neighbour_stress *= 1.0 - (float(dist_to_fault)/float(neighbour_reach))
	
	return cells


static func random_unit_vector() -> Vector3:
	var z = randf_range(-1.0, 1.0)
	var a = randf() * TAU
	var r = sqrt(1.0 - z * z)
	return Vector3(r * cos(a), r * sin(a), z)


func get_stressing_neighbours(cells : Array[CellData], cell : int) -> Array[Array]:
	var neighbours : Array[Array] = [[cell]]
	for i in range(neighbour_reach):
		neighbours.append([])
		for neighbour_id in neighbours[i]:
			for next_neighbour_id in cells[neighbour_id].neighbours:
				if next_neighbour_id in neighbours[i]: continue
				neighbours[-1].append(next_neighbour_id)
	
	return neighbours.slice(1)
