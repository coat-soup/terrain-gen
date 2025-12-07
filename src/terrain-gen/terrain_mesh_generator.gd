@tool
extends Node
class_name TerrainMeshGenerator

@export var camera : Node3D
var camera_chunk_pos : Vector3i
var cached_camera_pos : Vector3 # scene node .pos cannot be accessed from thread

@export var planet_radius : int = 10
@export var terrain_height : float = 10.0

var chunk_octree : ChunkOctreeNode
@export var chunk_size : int = 8
@export var material : Material

@export var octree_subdivide_distance_chunks : float = 0.5
@export var max_rendered_lod : int = 6

@export_tool_button("Generate", "SphereMesh") var generate_action = generate_mesh

var sim_cells : Array[CellData]
var save_data : PlanetSimSaveData

@export var debug_run_chunking_in_editor : bool = false

var chunk_threads : Array[Thread] = []

@export var run_threaded : bool = true
@export var noise : FastNoiseLite
@export var noise_strength : float = 0.2
@export var height_curve : Curve


func _ready() -> void:
	if not Engine.is_editor_hint():
		generate_mesh()


func generate_mesh():
	print("generating chunks")
	for child in get_children():
		child.queue_free()
	
	save_data = PlanetSimSaveData.load_save()
	sim_cells = save_data.parse_cells()
	
	init_chunk_octree()
	
	material.set("shader_parameter/planet_radius", planet_radius)
	material.set("shader_parameter/terrain_height", terrain_height)
	
	cached_camera_pos = camera.position
	if run_threaded: run_chunk_thread()
	else: generate_chunks_around_camera()


func _process(delta: float) -> void:
	if not debug_run_chunking_in_editor: return
	
	var c_pos = Vector3i(camera.global_position / chunk_size)
	if c_pos != camera_chunk_pos:
		camera_chunk_pos = Vector3i(camera.global_position / chunk_size)
		cached_camera_pos = camera.position
		
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
	cached_camera_pos = camera.position
	
	var new_thread = Thread.new()
	chunk_threads.append(new_thread)
	new_thread.start(generate_chunks_around_camera)
	print("sent via thread")


func generate_chunks_around_camera():
	if chunk_threads.size() > 1 and chunk_threads[0].is_started():
		print("waiting for thread")
		chunk_threads[0].wait_to_finish()
		chunk_threads.remove_at(0)
	
	var time = Time.get_unix_time_from_system()
	
	build_octree(chunk_octree)
	print("finished generating in ", Time.get_unix_time_from_system()-time, " seconds")


func build_octree(node: ChunkOctreeNode, parent = null):
	#await get_tree().process_frame
	
	var center = node.position + Vector3.ONE * node.size/2
	var distance = (cached_camera_pos - center).length()
	
	if node.should_subdivide(cached_camera_pos, chunk_size, octree_subdivide_distance_chunks):
		if node.mesh:
			node.mesh.queue_free.call_deferred()
			node.mesh = null
		
		if node.children.is_empty():
			node.children = []
			for offset in [Vector3(0,0,0), Vector3(1,0,0), Vector3(0,1,0), Vector3(1,1,0), Vector3(0,0,1), Vector3(1,0,1), Vector3(0,1,1), Vector3(1,1,1)]:
				var child = ChunkOctreeNode.new(node.position + (offset * node.size/2), node.lod - 1, chunk_size)
				node.children.append(child)
		
		for child in node.children:
			#await get_tree().process_frame
			build_octree(child, node)
	else:
		if ! node.children.is_empty(): collapse_children(node)
		
		if not node.mesh and node.lod <= max_rendered_lod: load_octree_chunk(node, parent) # sets node.mesh


func collapse_children(node : ChunkOctreeNode):
	if node.mesh: node.mesh.queue_free.call_deferred()
	if not node.children.is_empty():
		for child in node.children:
			collapse_children(child)
		node.children.clear()


func load_octree_chunk(node : ChunkOctreeNode, parent : ChunkOctreeNode = null):
	var chunk : TerrainChunk = TerrainChunk.new()
	node.mesh = chunk
	chunk.position = node.position
	chunk.chunk_pos = node.position / chunk_size
	chunk.size = Vector3i(chunk_size,chunk_size,chunk_size)
	chunk.sim_cell = sim_cells[get_planet_cell_from_normal(chunk.position, sim_cells, parent.mesh.sim_cell if parent and parent.mesh else 0)]
	chunk.terrain_mesh_generator = self
	
	chunk.material_overlay = material
	
	chunk.lod_level = node.lod
	
	chunk.generate_mesh_complete(0)
	#WorkerThreadPool.add_group_task(chunk.generate_mesh_complete, 1, 1)
	#chunk.generate_mesh()
	
	add_child.call_deferred(chunk)


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


func init_chunk_octree():
	var margin : float = terrain_height * 1.5
	var diameter :float = 2.0 * planet_radius + 2.0 * margin  # side length we must cover
	
	# start at smallest chunk
	var s := float(chunk_size)
	var lod := 0
	# increase lod until good
	while s < diameter:
		s *= 2.0
		lod += 1
	
	var root_pos := -Vector3.ONE * s / 2
	
	chunk_octree = ChunkOctreeNode.new(root_pos, lod, chunk_size)


func _exit_tree() -> void:
	for thread in chunk_threads:
		if thread.is_started():
			thread.wait_to_finish()
