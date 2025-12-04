@tool
extends Node
class_name TerrainMeshGenerator

@export var planet_radius : int = 10

var chunks : Array[TerrainChunk]
@export var chunk_size : int = 16
@export var n_chunks_cubed : int = 2

@export var material : Material

@export_tool_button("Generate", "SphereMesh") var generate_action = generate_mesh

var sim_cells : Array[CellData]


func _ready() -> void:
	pass
	#generate_mesh()


func generate_mesh():
	print("generating chunks")
	for child in get_children():
		child.queue_free()
	chunks.clear()
	
	sim_cells = PlanetSimSaveData.load_save()
	
	chunks.resize(n_chunks_cubed*n_chunks_cubed*n_chunks_cubed)
	
	for x in range(n_chunks_cubed):
		for y in range(n_chunks_cubed):
			for z in range(n_chunks_cubed):
				var chunk : TerrainChunk = TerrainChunk.new()
				chunks[grid_to_idx(x,y,z)] = chunk
				add_child(chunk)
				chunk.owner = get_tree().edited_scene_root
				var half = float(n_chunks_cubed - 1) / 2.0
				chunk.position = (Vector3(x, y, z) - Vector3(half, half, half)) * chunk_size
				chunk.chunk_pos = Vector3i(x,y,z)
				chunk.size = Vector3i(chunk_size+1,chunk_size+1,chunk_size+1)
				chunk.sim_cell = sim_cells[get_planet_cell_from_normal(chunk.position, sim_cells, get_chunk_sim_search_starting_cell(chunk))]
				chunk.planet_radius = planet_radius
				chunk.terrain_mesh_generator = self
				
				chunk.material_overlay = material
				
				chunk.generate_mesh()


func get_chunk_sim_search_starting_cell(chunk : TerrainChunk) -> int:
	for dx in [-1,0,1]:
		for dy in [-1,0,1]:
			for dz in [-1,0,1]:
				if dx == 0 and dy == 0 and dz == 0: continue
				var n_chunk_id = grid_to_idx(chunk.chunk_pos.x + dx, chunk.chunk_pos.y + dy, chunk.chunk_pos.z + dz)
				if n_chunk_id != -1 and chunks[n_chunk_id]:
					return chunks[n_chunk_id].sim_cell.id
	return 0


static func get_planet_cell_from_normal(normal : Vector3, cells : Array[CellData], start_cell: int = 0) -> int:
	var id : int = start_cell
	var best_dot : float = normal.dot(cells[start_cell].unit_pos)
	
	while true:
		var improved = false
		
		for n_id in cells[id].neighbours:
			var d = normal.dot(cells[n_id].unit_pos)
			if d > best_dot:
				best_dot = d
				id = n_id
				improved = true
				break
			
		if not improved:
			return id
	
	return id


func grid_to_idx(x : int, y : int, z : int) -> int:
	if x < 0 or y < 0 or z < 0: return -1
	if x >= n_chunks_cubed or y >= n_chunks_cubed or z >= n_chunks_cubed: return -1
	return x + y * n_chunks_cubed + z * n_chunks_cubed * n_chunks_cubed


func world_to_chunk(world_pos: Vector3) -> Vector3i:
	var half = float(n_chunks_cubed - 1) * 0.5
	var chunk_pos_f = world_pos / chunk_size + Vector3(half, half, half)
	return Vector3i(
		floor(chunk_pos_f.x),
		floor(chunk_pos_f.y),
		floor(chunk_pos_f.z)
	)
