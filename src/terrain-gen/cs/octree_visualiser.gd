extends Node
class_name OctreeVisualiser

@export var generator : Node

var positions : Array[Vector3]
var sizes : Array[float]
var depths : Array[int]

@export var start_depth : int = 4
@export var enabled : bool = false


func parse_tree():
	positions = []
	sizes = []
	depths = []
	
	add_node_to_list(generator.tree)


func add_node_to_list(node):
	positions.append(node.position)
	sizes.append(node.sideLength)
	depths.append(node.depth)
	for c in node.children:
		add_node_to_list(c)


func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_V): enabled = !enabled


func _process(delta: float) -> void:
	if not enabled: return
	const depth_colours : Array[Color] = [Color.WEB_MAROON, Color.MAROON, Color.BROWN, Color.SADDLE_BROWN, Color.SANDY_BROWN, Color.BURLYWOOD, Color.KHAKI, Color.YELLOW_GREEN, Color.DARK_OLIVE_GREEN, Color.DARK_CYAN, Color.BLUE]
	
	DebugDraw3D.draw_box(Vector3.ZERO, Quaternion.IDENTITY, Vector3.ONE, Color.BROWN, false)
	for i in range(positions.size()):
		if depths[i] < start_depth: continue
		DebugDraw3D.scoped_config().set_thickness(50.0 / pow(1.3, depths[i]))
		DebugDraw3D.draw_box(positions[i], Quaternion.IDENTITY, Vector3.ONE * sizes[i], depth_colours[depths[i]] if depths[i] < depth_colours.size() else Color.RED, false)
