@tool
extends Node
class_name TerrainMeshGenerator

@export var mesh_instance : MeshInstance3D
@export var size : Vector3i = Vector3i.ONE * 10
@export var iso : float = 0.5

@export var planet_radius : int = 5

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
	#populate_sphere()
	#populate_noise()
	populate_planet_data()
	
	var mc = MarchingCubes.marching_cubes(sample_data, size, iso)	
	
	arrays[Mesh.ARRAY_VERTEX] = mc["vertices"]
	arrays[Mesh.ARRAY_NORMAL] = mc["normals"]
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = arr_mesh
	
	mesh_instance.global_position = -size /2.0


func _process(delta: float) -> void:
	if not debug_data: return
	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.x):
				if data[grid_to_idx(x,y,z)] > iso:
					var color : Color = lerp(Color.BLACK, Color.WHITE, data[grid_to_idx(x,y,z)])
					DebugDraw3D.draw_square(Vector3(x,y,z) -size /2.0, 0.2, color)


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


func populate_planet_data():
	var cells : Array[CellData] = PlanetSimSaveData.load_save()
	var center : Vector3 = Vector3(size) / 2.0
	for z in range(size.z):
		for y in range(size.y):
			for x in range(size.x):
				
				var pos = Vector3(x, y, z)
				var offset = pos - center
				var r = offset.length()
				
				if r == 0.0:
					data[grid_to_idx(x,y,z)] = -1.0
					continue
				
				var normal = offset / r
				
				# Find the closest Goldbert cell for this direction
				var cell_id = get_planet_cell_from_normal(normal, cells)
				var cell = cells[cell_id]
				
				# Planet surface height at this direction
				var surface_radius = planet_radius + cell.height
				#if cell.height > 0: surface_radius += cell.height
				
				# Density for marching cubes:
				# >0 = solid
				# <0 = air
				var density = surface_radius - r
				
				data[grid_to_idx(x,y,z)] = density
				
				# TODO: can later implement chunking and start search from cell of neighbouring chunk (close chunks will have close corresponding cells)
				

func get_planet_cell_from_normal(normal : Vector3, cells : Array[CellData], start_cell: int = 0) -> int:
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
