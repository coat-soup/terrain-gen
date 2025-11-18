# The algorithm here follows the method proposed by Sang Yong Lee in the paper 
# "Polyhedral Mesh Generation and A Treatise on Concave Geometrical Edges",
# retrieved from https://www.sciencedirect.com/science/article/pii/S1877705815032324
# (doi: 10.1016/j.proeng.2015.10.131)

extends RefCounted
class_name MeshDual

var vertices : PackedVector3Array # triangulated list of vertices for rendering
var faces : Array[Array] # for each polygon, ordered list of centroid indices
var adjacency : Array[Array] # for each polygon, adjacent indices in faces array


func _init(input_vertices: PackedVector3Array, radius: float = 1.0):
	# check unique vertices
	if input_vertices.size() % 3 != 0:
		push_error("mesh_dual: input vertices array size must be multiple of 3")
		return
	
	var tri_count: int = int(input_vertices.size() / 3)
	
	## 1: compute centroids (new verts in middle of og faces), index is original face index
	var centroids: PackedVector3Array = PackedVector3Array()
	centroids.resize(tri_count)
	for f in range(tri_count):
		var i3: int = f * 3
		var c: Vector3 = (input_vertices[i3] + input_vertices[i3 + 1] + input_vertices[i3 + 2]) / 3.0
		centroids[f] = c.normalized() * radius
	
	## 2: build maps
	# edge_map: normalized edge key -> face index (to detect adjacency between faces)
	var edge_map: Dictionary = {} # key: "kx|ky|kz--kx2|..." -> int(face_index)
	
	# vertex_face_map: original vertex key -> { "pos": Vector3, "faces": Array[int] }
	var vertex_face_map: Dictionary = {}
	
	# store three vertex keys for each triangle (need for later)
	var tri_vertex_keys: Array = []
	tri_vertex_keys.resize(tri_count)
	
	for f in range(tri_count):
		var i3: int = f * 3
		var keys: Array = []
		for j in range(3):
			var vpos: Vector3 = input_vertices[i3 + j]
			var k: String = _vkey(vpos)
			keys.append(k)
			# map vertex -> faces
			if not vertex_face_map.has(k):
				vertex_face_map[k] = {"pos": vpos, "faces": []}
			vertex_face_map[k]["faces"].append(f)
		tri_vertex_keys[f] = keys
		
		# register edges (undirected) for adjacency & for original-vertex adjacency later
		for e in range(3):
			var a_key: String = keys[e]
			var b_key: String = keys[(e + 1) % 3]
			# make canonical undirected key (sorted)
			var edge_key: String = (a_key + "--" + b_key) if (a_key < b_key) else (b_key + "--" + a_key)
			if not edge_map.has(edge_key):
				edge_map[edge_key] = f
			else:
				# is a shared edge between faces
				# don't need to store pair - adjacency of faces uses edge_map when needed
				# NOTE: revisit if something breaks
				pass
	
	## 3: create ordered dual faces (polygons) for each original vertex
	# faces: 2D int array (centroid indices) in clockwise winding order around the original vertex
	faces = []
	# map vertex_key -> index in faces (polygon index)
	var key_to_polygon_index: Dictionary = {}
	
	var poly_idx: int = 0
	for key in vertex_face_map.keys():
		var entry: Dictionary = vertex_face_map[key]
		var face_indices: Array = entry["faces"]
		# skip invalid polygons
		if face_indices.size() < 3:
			continue
		
		# compute local tangent basis at original vertex position (for sphere: normal ~= pos.normalized())
		var vpos: Vector3 = entry["pos"].normalized()
		var basis: Dictionary = _tangent_basis_from_normal(vpos)
		var u: Vector3 = basis["u"]
		var v: Vector3 = basis["v"]
		
		# build list of [angle, face_index] for sorting
		var angle_list: Array = []
		angle_list.resize(0)
		for fi in face_indices:
			var dir_vec: Vector3 = (centroids[fi] - entry["pos"]).normalized()
			var x: float = dir_vec.dot(u)
			var y: float = dir_vec.dot(v)
			var ang: float = atan2(y, x)
			angle_list.append([ang, fi])
		
		# sort by angle ascending (CCW)
		angle_list.sort() # works because each element is [angle, fi], lexicographic sort
		
		# produce sorted face index list
		var sorted_faces: Array = []
		sorted_faces.resize(0)
		for pair in angle_list:
			sorted_faces.append(pair[1])
		
		# save
		key_to_polygon_index[key] = poly_idx
		faces.append(sorted_faces)
		poly_idx += 1
	
	## 4: build renderable triangulated dual mesh by fan-triangulating each polygon
	vertices = PackedVector3Array()
	vertices.resize(0)
	for poly in faces:
		# skip invalid polygons
		if poly.size() < 3:
			continue
		var first_idx: int = poly[0]
		for i in range(1, poly.size() - 1):
			vertices.append(centroids[first_idx])
			vertices.append(centroids[poly[i + 1]])
			vertices.append(centroids[poly[i]])
	
	## 5: compute adjacency between dual polygons
	# two dual polygons (corresponding to original vertices A and B) are adjacent if original vertices A and B share an edge
	# we can iterate the edge_map keys (which are canonical a--b pairs) and use key_to_polygon_index to map to polygon ids
	adjacency = []
	adjacency.resize(faces.size())
	for i in range(adjacency.size()):
		adjacency[i] = []

	for edge_key in edge_map.keys():
		# edge_key = "a_key--b_key"
		var parts: Array = edge_key.split("--")
		if parts.size() != 2:
			continue
		var a_k: String = parts[0]
		var b_k: String = parts[1]
		if key_to_polygon_index.has(a_k) and key_to_polygon_index.has(b_k):
			var pa: int = key_to_polygon_index[a_k]
			var pb: int = key_to_polygon_index[b_k]
			# add both ways
			if not pa in adjacency[pb]:
				adjacency[pb].append(pa)
			if not pb in adjacency[pa]:
				adjacency[pa].append(pb)


func _vkey(v: Vector3) -> String:
	# quantized string key to avoid small floating point differences
	# 6 decimal should be enough, but tweak as needed
	return ("%.6f|%.6f|%.6f" % [v.x, v.y, v.z])

func _tangent_basis_from_normal(n: Vector3) -> Dictionary:
	var up: Vector3 = Vector3(0.0, 1.0, 0.0)
	if abs(n.dot(up)) > 0.999: # if near parallel then pick a different up
		up = Vector3(1.0, 0.0, 0.0)
	var u: Vector3 = (up - n * n.dot(up)).normalized()
	var v: Vector3 = n.cross(u).normalized()
	return {"u": u, "v": v}
