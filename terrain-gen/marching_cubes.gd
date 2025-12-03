class_name MarchingCubes

extends Node


static func interpolate(p1: Vector3, p2: Vector3, v1: float, v2: float, iso: float) -> Vector3:
	if abs(iso - v1) < 0.00001:
		return p1
	if abs(iso - v2) < 0.00001:
		return p2
	if abs(v1 - v2) < 0.00001:
		return p1
	var t = (iso - v1) / (v2 - v1)
	return p1 + t * (p2 - p1)


static func marching_cubes(sample_func: Callable, size: Vector3i, iso:=0.5, cell_size:=1.0) -> PackedVector3Array:
	var verts := PackedVector3Array()
	
	for x in range(size.x - 1):
		for y in range(size.y - 1):
			for z in range(size.z - 1):
				
				# Sample cube corners
				var p = [
					Vector3(x,     y,     z    ) * cell_size,
					Vector3(x+1,   y,     z    ) * cell_size,
					Vector3(x+1,   y,     z+1  ) * cell_size,
					Vector3(x,     y,     z+1  ) * cell_size,
					Vector3(x,     y+1,   z    ) * cell_size,
					Vector3(x+1,   y+1,   z    ) * cell_size,
					Vector3(x+1,   y+1,   z+1  ) * cell_size,
					Vector3(x,     y+1,   z+1  ) * cell_size
				]
				
				var val = [
					sample_func.call(x,   y,   z),
					sample_func.call(x+1, y,   z),
					sample_func.call(x+1, y,   z+1),
					sample_func.call(x,   y,   z+1),
					sample_func.call(x,   y+1, z),
					sample_func.call(x+1, y+1, z),
					sample_func.call(x+1, y+1, z+1),
					sample_func.call(x,   y+1, z+1)
				]
				
				# Determine cube index
				var cube_index = 0
				for i in range(8):
					if val[i] < iso:
						cube_index |= int(pow(2,i))
				
				# Check intersection
				var edge_mask = MarchingCubesTables.EDGE_TABLE[cube_index]
				if edge_mask == 0:
					continue
				
				
				# Find edge vertices
				var edge_vert = []
				edge_vert.resize(12)
				
				var edge_points = [
					[0,1],[1,2],[2,3],[3,0],
					[4,5],[5,6],[6,7],[7,4],
					[0,4],[1,5],[2,6],[3,7]
				]
				
				for e in range(12):
					if edge_mask & (1 << e):
						var a = edge_points[e][0]
						var b = edge_points[e][1]
						edge_vert[e] = interpolate(p[a], p[b], val[a], val[b], iso)
				
				# Add triangles
				var tri_list = MarchingCubesTables.TRI_TABLE[cube_index]
				var idx = 0
				while tri_list[idx] != -1:
					verts.append(edge_vert[tri_list[idx]])
					verts.append(edge_vert[tri_list[idx+1]])
					verts.append(edge_vert[tri_list[idx+2]])
					idx += 3
	
	return verts
