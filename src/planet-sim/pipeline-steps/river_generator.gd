@tool
extends SimulationStep
class_name RiverGenerator

@export_range(0, 300) var river_mouths : int = 100
@export_range(0, 1000) var river_starts : int = 500

func simulate(cells : Array[CellData], sim : SimulationPipeline) -> Array[CellData]:
	for cell in cells: cell.water_content = 0
	
	
	var p_mouths : Array[CellData] = []
	var p_starts : Array[CellData] = []
	for cell in cells:
		if cell.height <= 0.0 and cell.distance_to_ocean_boundary == 0:
			p_mouths.append(cell)
			#cell.water_content = 1.0 # DEBUG
		
		if abs(cell.height - 0.4) < 0.05 or abs(cell.height - 0.2) < 0.05:
			p_starts.append(cell)
			#cell.water_content = 1.0 # DEBUG
		
	
	#return cells
	
	# pick random mouths
	var mouths : Array[CellData] = []
	for i in range(river_mouths):
		var mouth : CellData = null
		while mouth == null:
			mouth = p_mouths.pick_random()
			for m in mouths:
				if m.unit_pos.distance_to(mouth.unit_pos) < 0.05:
					mouth = null
					break
		mouths.append(mouth)
		
		#mouth.water_content = 1.0 # DEBUG
	
	var starts : Array[CellData] = []
	for i in range(river_starts):
		var start : CellData = null
		while start == null:
			start = p_starts.pick_random()
			#for m in starts:
				#if m.unit_pos.distance_to(start.unit_pos) < 0.05:
					#start = null
					#break
		starts.append(start)
		
		start.water_content = 1.0 # DEBUG
	
	# do rivers
	for start in starts:
		var cur_cell : CellData = start
		var prev_cell : CellData = null
		
		var merged : bool = false
		for n in cur_cell.neighbours:
			if cells[n].water_content > 0.0 and cells[n] != prev_cell:
				merged = true
		if merged: continue
		
		var best_mouth : CellData = null
		var best_dist : float = INF
		for mouth in mouths:
			if mouth.plate_id != cur_cell.plate_id: continue
			var dist = start.unit_pos.distance_to(mouth.unit_pos)
			if best_mouth == null or (dist < best_dist):
				best_mouth = mouth
				best_dist = dist
		
		if best_mouth == null: continue
		
		while cur_cell.height > 0:
			cur_cell.water_content = 1
			
			var slope_weights : Array[float] = []
			var mouth_weights : Array[float] = []
			
			for n in cur_cell.neighbours:
				var prev_mul : float = 0.0 if cells[n] == prev_cell else 1.0
				slope_weights.append(1.0/cells[n].height * prev_mul)
				mouth_weights.append(1.0/cells[n].unit_pos.distance_to(best_mouth.unit_pos) * prev_mul)
			slope_weights = normalise_weights(slope_weights)
			mouth_weights = normalise_weights(mouth_weights)
			
			var best_i : float = -1
			var best_w : float = 0
			for i in range(len(slope_weights)):
				if cells[cur_cell.neighbours[i]] != prev_cell: mouth_weights[i] += randf_range(0,0.01)
				var weight = 0.3 * slope_weights[i] + mouth_weights[i] * 1.0
				if weight > best_w:
					best_i = i
					best_w = weight
			
			prev_cell = cur_cell
			cur_cell = cells[cur_cell.neighbours[best_i]]
			
			if cur_cell.water_content > 0: break
	
	return cells


func normalise_weights(weights : Array[float]) -> Array[float]:
	var total : float = 0.0
	
	for w in weights:
		total += w
		
	for i in range(len(weights)):
		weights[i] /= total
	
	return weights
