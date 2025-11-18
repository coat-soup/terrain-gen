@tool
extends Node
class_name ColourVisualiser

@export_tool_button("ColourMesh", "SphereMesh") var colour_action = colour_mesh


func _ready() -> void:
	colour_mesh()


func colour_mesh():
	var generator: MeshGenerator = $"../MeshGenerator"
	var colours : Array[float] = []
	colours.resize(8000)
	for i in range(len(generator.polyhedron.faces)):
		colours[i] = (randf_range(0,1))
	(generator.mesh_instance.get_active_material(0) as ShaderMaterial).set_shader_parameter("cell_data", colours)
	print(colours)
