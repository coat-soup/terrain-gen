@tool
extends Node
class_name TerrainMeshGenerator

@export var camera : Node3D
var camera_chunk_pos : Vector3i

@export var planet_radius : int = 10
@export var terrain_height : float = 10.0

var chunks : Dictionary = {}
@export var chunk_size : int = 8
@export var render_distance : int = 2
@export var lod_band_sizes : Array[int] = [2]
@export var material : Material

@export_tool_button("Generate", "SphereMesh") var generate_action = generate_mesh

var sim_cells : Array[CellData]

@export var debug_run_chunking_in_editor : bool = false

var chunk_threads : Array[Thread] = []

@export var run_threaded : bool = true


func _ready() -> void:
	pass
	#generate_mesh()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() and not debug_run_chunking_in_editor: return
	
	var c_pos = Vector3i(camera.global_position / chunk_size)
	if c_pos != camera_chunk_pos:
		camera_chunk_pos = Vector3i(camera.global_position / chunk_size)
		
		var wait_iters : int = 0
		while chunk_threads.size() > 1:
			wait_iters += 1
			if wait_iters > 5000:
				for thread in chunk_threads:
					thread.wait_to_finish()
				chunk_threads.clear()
			else:
				await get_tree().process_frame
			print("waiting for chunk overthread")
		
		
		if run_threaded: run_chunk_thread()
		else: generate_chunks_around_camera()
		#chunk_load_task_id = WorkerThreadPool.add_task(generate_chunks_around_camera)
		#WorkerThreadPool.wait_for_task_completion.call_deferred(task_id)


func run_chunk_thread():
	var new_thread = Thread.new()
	chunk_threads.append(new_thread)
	new_thread.start(generate_chunks_around_camera)


func generate_mesh():
	print("generating chunks")
	for child in get_children():
		child.queue_free()
	chunks.clear()
	
	sim_cells = PlanetSimSaveData.load_save()
	
	material.set("shader_parameter/planet_radius", planet_radius)
	material.set("shader_parameter/terrain_height", terrain_height)
	
	if run_threaded: run_chunk_thread()
	else: generate_chunks_around_camera()


func load_chunk(position : Vector3i, lod : int):
	var chunk : TerrainChunk = TerrainChunk.new()
	chunks[position] = chunk
	chunk.position = position * chunk_size
	chunk.chunk_pos = position
	chunk.size = Vector3i(chunk_size,chunk_size,chunk_size)
	chunk.sim_cell = sim_cells[get_planet_cell_from_normal(chunk.position, sim_cells, get_chunk_sim_search_starting_cell(chunk))]
	chunk.terrain_mesh_generator = self
	
	chunk.material_overlay = material
	
	chunk.lod_level = lod
	
	chunk.generate_mesh_complete(0)
	#WorkerThreadPool.add_group_task(chunk.generate_mesh_complete, 1, 1)
	#chunk.generate_mesh()
	
	add_child.call_deferred(chunk)


func unload_chunk(position : Vector3i):
	chunks[position].queue_free.call_deferred()
	chunks.erase(position)


func generate_chunks_around_camera():
	if chunk_threads.size() > 1 and chunk_threads[0].is_started():
		chunk_threads[0].wait_to_finish()
		chunk_threads.remove_at(0)
	
	var total_view_distance = 0
	for i in range(lod_band_sizes.size()): total_view_distance += lod_band_sizes[i] * pow(2,i) # in each consecutive band, chunks are twice as big 
	
	for chunk_pos in chunks.keys():
		if (abs(chunk_pos.x - camera_chunk_pos.x) > total_view_distance or
			abs(chunk_pos.y - camera_chunk_pos.y) > total_view_distance or
			abs(chunk_pos.z - camera_chunk_pos.z) > total_view_distance):
				unload_chunk(chunk_pos)
	
	var band_end : int = 0
	var band_start : int = 0
	for i in range(lod_band_sizes.size()):
		#var cur_band_size = lod_band_sizes[i]
		#for j in range(i): cur_band_size += lod_band_sizes[j] / pow(2,i-j)
		# cur_band_size is total number of lod(i) sized chunks from center at this ring level
		
		band_end += lod_band_sizes[i] << i #* pow(2,i)
		
		var step = 1 << i # 2^i
		for dx in range(-band_end, band_end, step):
			for dy in range(-band_end, band_end, step):
				for dz in range(-band_end, band_end, step):
					if abs(dx) < band_start and abs(dy) < band_start and abs(dz) < band_start: continue # skip middle bit for all lods (is already filled by lower lods)
					if not chunks.has(camera_chunk_pos + Vector3i(dx,dy,dz)):
						load_chunk(camera_chunk_pos + Vector3i(dx,dy,dz), i)
					else:
						# TODO: update chunk lods if already there
						continue
						chunks[camera_chunk_pos + Vector3i(dx,dy,dz)].lod_level = i
						chunks[camera_chunk_pos + Vector3i(dx,dy,dz)].generate_mesh_complete(0)
		band_start = band_end


func get_chunk_sim_search_starting_cell(chunk : TerrainChunk) -> int:
	for dx in [-1,0,1]:
		for dy in [-1,0,1]:
			for dz in [-1,0,1]:
				if dx == 0 and dy == 0 and dz == 0: continue
				var d = Vector3i(chunk.chunk_pos.x + dx, chunk.chunk_pos.y + dy, chunk.chunk_pos.z + dz)
				if chunks.has(d):
					return chunks[d].sim_cell.id
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


func _exit_tree() -> void:
	for thread in chunk_threads:
		if thread.is_started():
			thread.wait_to_finish()
