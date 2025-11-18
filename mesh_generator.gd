@tool
extends Node
class_name MeshGenerator

@export var mesh_instance : MeshInstance3D
@export var n_subdivisons : int = 2
@export var mesh_radius : float = 1.0

@export_tool_button("Generate", "SphereMesh") var generate_action = generate_mesh


func _ready() -> void:
	generate_mesh()


func generate_mesh():
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var verts = icosahedron(mesh_radius)
	verts = subdivide_sphere(verts, n_subdivisons, mesh_radius)
	
	var polyhedra = MeshDual.new(verts, mesh_radius)
	
	arrays[Mesh.ARRAY_VERTEX] = polyhedra.vertices
	arrays[Mesh.ARRAY_NORMAL] = normals_from_vertices(arrays[Mesh.ARRAY_VERTEX])
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = arr_mesh


func icosahedron(radius: float = 1.0) -> PackedVector3Array:
	var t := (1.0 + sqrt(5.0)) / 2.0
	
	# base vertices of an icosahedron
	var base := [
		Vector3(-1,  t,  0), Vector3( 1,  t,  0), Vector3(-1, -t,  0), Vector3( 1, -t,  0),
		Vector3( 0, -1,  t), Vector3( 0,  1,  t), Vector3( 0, -1, -t), Vector3( 0,  1, -t),
		Vector3( t,  0, -1), Vector3( t,  0,  1), Vector3(-t,  0, -1), Vector3(-t,  0,  1)
	]
	
	# normalise and scale
	for i in range(base.size()):
		base[i] = base[i].normalized() * radius
	
	# triangle indices
	var faces = [
		0, 11, 5,  0, 5, 1,  0, 1, 7,  0, 7,10,  0,10,11,
		1, 5, 9,  5,11, 4, 11,10, 2, 10, 7, 6,  7, 1, 8,
		3, 9, 4,  3, 4, 2,  3, 2, 6,  3, 6, 8,  3, 8, 9,
		4, 9, 5,  2, 4,11,  6, 2,10,  8, 6, 7,  9, 8, 1
	]
	
	# godot uses clockwise winding order (and I'm too lazy to redo the faces table)
	faces.reverse()
	
	var vertices: PackedVector3Array = []
	vertices.resize(faces.size())
	
	for i in range(faces.size()):
		vertices[i] = base[faces[i]]
	
	return vertices


func subdivide_sphere(vertices: PackedVector3Array, subdivisions: int, radius: float = 1.0) -> PackedVector3Array:
	if subdivisions <= 0:
		return vertices
	
	var result: PackedVector3Array = vertices
	
	for _i in subdivisions:
		var new_vertices: PackedVector3Array = []
		new_vertices.clear()
		
		for t in range(0, result.size(), 3):
			var v1 = result[t]
			var v2 = result[t + 1]
			var v3 = result[t + 2]
			
			# midpoints
			var a = ((v1 + v2) * 0.5).normalized() * radius
			var b = ((v2 + v3) * 0.5).normalized() * radius
			var c = ((v3 + v1) * 0.5).normalized() * radius
			
			# replace with 4 child triangles (no shared vertices)
			new_vertices.append_array([
				v1, a, c,
				a, v2, b,
				c, b, v3,
				a, b, c
				])
		
		result = new_vertices
	
	return result


func normals_from_vertices(vertices : PackedVector3Array) -> PackedVector3Array:
	var normals : PackedVector3Array = []
	normals.resize(vertices.size())
	for i in range(vertices.size()):
		normals[i] = vertices[i].normalized()
	return normals
