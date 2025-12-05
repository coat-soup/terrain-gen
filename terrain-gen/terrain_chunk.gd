@tool
extends MeshInstance3D
class_name TerrainChunk

signal finished_generating

var sim_cell : CellData

var data : PackedFloat32Array
var chunk_pos : Vector3i
var size : Vector3i

var terrain_mesh_generator : TerrainMeshGenerator
var mc : Dictionary
var marching_cubes_cs  = preload("res://terrain-gen/MarchingCubes.cs")

var lod_level : int = 0

var is_chunk_empty : bool = true

func _ready() -> void:
	owner = get_tree().edited_scene_root


func generate_mesh_complete(group_work_id : int):
	
	#size /= pow(2, lod_level) # grid size will be same for all chunks. far away chunks will just take up multiple chunks instead
	size += Vector3i.ONE # chunk padding
	
	data.clear()
	data = PackedFloat32Array()
	data.resize(size.x * size.y * size.z)
	
	populate_planet_data()
	
	if is_chunk_empty:
		print("chunk is empty, skipping")
		return
	
	#var mc = MarchingCubes.marching_cubes(sample_data, size, 0.0)
	
	var mc = marching_cubes_cs.Generate(data, size, 0.0, pow(2, lod_level))
	
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	if mc["vertices"].size() < 3:
		#print("chunk has no solid datapoints")
		return
	
	arrays[Mesh.ARRAY_VERTEX] = mc["vertices"]
	arrays[Mesh.ARRAY_NORMAL] = mc["normals"]
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = arr_mesh
	
	finished_generating.emit()


func generate_mesh():
	data.clear()
	data = PackedFloat32Array()
	data.resize(size.x * size.y * size.z)
	
	populate_planet_data()
	
	#data_thread.start(run_data_thread)
	
	var task_id = WorkerThreadPool.add_task(run_data_thread)
	WorkerThreadPool.wait_for_task_completion(task_id)
	data_thread_finished()


func run_data_thread():
	var mc = MarchingCubes.marching_cubes(sample_data, size, 0.0)
	#data_thread_finished.call_deferred()
	return mc


func data_thread_finished():
	#var mc = data_thread.wait_to_finish()
	
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	
	if mc["vertices"].size() < 3:
		#print("chunk has no solid datapoints")
		return
	
	arrays[Mesh.ARRAY_VERTEX] = mc["vertices"]
	arrays[Mesh.ARRAY_NORMAL] = mc["normals"]
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = arr_mesh
	
	finished_generating.emit()


func sample_data(x : int, y : int, z : int) -> float:
	if x < 0 or y < 0 or z < 0: return 0.0
	if x >= size.x or y >= size.y or z >= size.z: return 0.0
	return data[grid_to_idx(x,y,z)]


func grid_to_idx(x : int, y : int, z : int) -> int:
	return x + y * size.x + z * size.x * size.y


func populate_planet_data():
	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.x):
				data[grid_to_idx(x,y,z)] = 1.0
				
				var world_pos = position + Vector3(x, y, z) * pow(2, lod_level)
				var offset = world_pos
				var r = offset.length()
				
				if r == 0.0:
					data[grid_to_idx(x,y,z)] = -1.0
					continue
				
				var normal = offset / r
				
				var cell = TerrainMeshGenerator.get_planet_cell_from_normal(offset, terrain_mesh_generator.sim_cells, sim_cell.id)
				
				var surface_radius = terrain_mesh_generator.planet_radius + terrain_mesh_generator.sim_cells[cell].height * terrain_mesh_generator.terrain_height
				var density = surface_radius - r
				
				data[grid_to_idx(x,y,z)] = density
				if density > 0: is_chunk_empty = false
