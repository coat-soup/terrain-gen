extends RefCounted
class_name ChunkOctreeNode

var position: Vector3
var size: int
var lod : int
var children: Array
var bounds : AABB
var mesh : TerrainChunk
var should_be_loaded : bool = true


func _init(pos: Vector3, lod_level : int, base_chunk_size : int) -> void:
	position = pos
	size = base_chunk_size << lod_level
	lod = lod_level
	bounds = AABB(position, Vector3.ONE * size)


func should_subdivide(camera_pos: Vector3, base_chunk_size : float, threshold : float) -> bool:
	if lod == 0:
		return false
	
	# if camera is inside node always subdivide
	if bounds.has_point(camera_pos):
		return true
	
	# otherwise use distance metric
	var distance : float = distance_to_aabb(camera_pos)
	return distance < size * threshold


func distance_to_aabb(p: Vector3) -> float:
	var dx = max(bounds.position.x - p.x, 0.0, p.x - (bounds.position.x + bounds.size.x))
	var dy = max(bounds.position.y - p.y, 0.0, p.y - (bounds.position.y + bounds.size.y))
	var dz = max(bounds.position.z - p.z, 0.0, p.z - (bounds.position.z + bounds.size.z))
	return sqrt(dx*dx + dy*dy + dz*dz)
