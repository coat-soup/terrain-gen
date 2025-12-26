class_name TestTerrainChunk
extends GdUnitTestSuite

const TerrainChunk = preload("res://terrain-gen/cs/TerrainChunk.cs")

func test_point_inside_spherical_triangle():
	var a = Vector3(1, 0, 0).normalized()
	var b = Vector3(0, 1, 0).normalized()
	var c = Vector3(0, 0, 1).normalized()
	
	var p = Vector3(1, 1, 1).normalized()
	
	assert(TerrainChunk.IsPointInSphericalTriangle(p, a, b, c))



func test_point_outside_spherical_triangle():
	var a = Vector3(1, 0, 0).normalized()
	var b = Vector3(0, 1, 0).normalized()
	var c = Vector3(0, 0, 1).normalized()
	
	# Point on the opposite side of the sphere
	var p = Vector3(-1, -1, -1).normalized()
	
	assert(TerrainChunk.IsPointInSphericalTriangle(p, a, b, c))


func test_spherical_triangle_area_octant():
	# Right-angle spherical triangle covering 1/8th of the sphere
	var a = Vector3(1, 0, 0).normalized()
	var b = Vector3(0, 1, 0).normalized()
	var c = Vector3(0, 0, 1).normalized()
	
	var area = TerrainChunk.TriArea(a, b, c)
	
	# Expected area = π / 4 steradians
	assert(abs(area - PI / 4.0) < 0.0001)


func test_spherical_triangle_area_orientation_invariant():
	var a = Vector3(1, 0, 0).normalized()
	var b = Vector3(0, 1, 0).normalized()
	var c = Vector3(0, 0, 1).normalized()
	
	var area1 = TerrainChunk.TriArea(a, b, c)
	var area2 = TerrainChunk.TriArea(c, b, a)
	
	assert(abs(abs(area1) - abs(area2)) < 0.0001)


func test_standalone():
	assert([1, 2, 3].size() == 3)
