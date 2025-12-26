extends Node
class_name OctreeVisualiser

@export var generator : Node
@export var foliage_generator : Node

var positions : Array[Vector3]
var world_sizes : Array[float]
var node_sizes : Array[int]

@export var size_limit : int = 0
@export var enabled : bool = false
var toggle_foliage : bool = false


func parse_tree():
	positions = []
	world_sizes = []
	node_sizes = []
	
	add_node_to_list(generator.tree if not toggle_foliage else foliage_generator.tree)


func add_node_to_list(node):
	positions.append(node.position)
	world_sizes.append(node.sideLength)
	node_sizes.append(node.size)
	if node.children: for c in node.children:
		add_node_to_list(c)


func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_V): enabled = !enabled
	if Input.is_key_pressed(KEY_B):
		toggle_foliage = !toggle_foliage
		parse_tree()


func _process(delta: float) -> void:
	if not enabled: return
	const depth_colours : Array[Color] = [Color.WEB_MAROON, Color.MAROON, Color.BROWN, Color.SADDLE_BROWN, Color.SANDY_BROWN, Color.BURLYWOOD, Color.KHAKI, Color.YELLOW_GREEN, Color.DARK_OLIVE_GREEN, Color.DARK_CYAN, Color.BLUE]
	
	DebugDraw3D.draw_box(Vector3.ZERO, Quaternion.IDENTITY, Vector3.ONE, Color.BROWN, false)
	for i in range(positions.size()):
		if node_sizes[i] > size_limit: continue
		DebugDraw3D.scoped_config().set_thickness(0.5 * pow(2, node_sizes[i]))
		DebugDraw3D.draw_box(positions[i], Quaternion.IDENTITY, Vector3.ONE * world_sizes[i], depth_colours[node_sizes[i]] if node_sizes[i] < depth_colours.size() else Color.RED, false)
