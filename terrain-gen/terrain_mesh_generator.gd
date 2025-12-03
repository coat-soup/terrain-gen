@tool
extends Node
class_name TerrainMeshGenerator

@export var mesh_instance : MeshInstance3D
@export var size : Vector3i = Vector3i.ONE * 10
@export var iso : float = 0.5

@export var debug_data : bool = false

@export var debug_noise : FastNoiseLite

@export_tool_button("Generate", "SphereMesh") var generate_action = generate_mesh

var data : PackedFloat32Array

func _ready() -> void:
	generate_mesh()


func generate_mesh():
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	init_data()
	
	#populate_random()
	populate_sphere()
	#populate_noise()
	
	var mc = MarchingCubes.marching_cubes(sample_data, size, iso)	
	
	arrays[Mesh.ARRAY_VERTEX] = mc["vertices"]
	arrays[Mesh.ARRAY_NORMAL] = mc["normals"]
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = arr_mesh


func _process(delta: float) -> void:
	if not debug_data: return
	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.x):
				if data[grid_to_idx(x,y,z)] > iso:
					var color : Color = lerp(Color.BLACK, Color.WHITE, data[grid_to_idx(x,y,z)])
					DebugDraw3D.draw_square(Vector3(x,y,z), 0.2, color)


func init_data():
	data.clear()
	data = PackedFloat32Array()
	data.resize(size.x * size.y * size.z)


func sample_data(x : int, y : int, z : int) -> float:
	if x < 0 or y < 0 or z < 0: return 0.0
	if x >= size.x or y >= size.y or z >= size.y: return 0.0
	return data[grid_to_idx(x,y,z)]


func grid_to_idx(x : int, y : int, z : int) -> int:
	return x + y * size.x + z * size.x * size.y


func populate_random():
	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.x):
				data[grid_to_idx(x,y,z)] = randf()


func populate_sphere():
	var center = Vector3(size) / 2.0
	var r2 = (min(size.x, size.y, size.z) / 3) ** 2
	
	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.x):
				var pos = Vector3(x, y, z)
				var dist2 = pos.distance_squared_to(center)
				var value = r2/dist2/5
				data[grid_to_idx(x, y, z)] = value


func populate_noise():
	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.x):
				data[grid_to_idx(x,y,z)] = debug_noise.get_noise_3dv(Vector3(x,y,z))
