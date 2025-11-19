@tool
extends Node
class_name CellDataVisualiser

enum VisualisationType {CELL_ID, PLATE_ID, CELL_POSITION, PLATE_STRESS, CELL_HEIGHT}
@export var vis_type : VisualisationType:
	set(new_vis_type):
		vis_type = new_vis_type
		colour_mesh()

@export_tool_button("ColourMesh", "SphereMesh") var colour_action = colour_mesh


func _ready() -> void:
	colour_mesh()
	$"../SimulationPipeline".finished.connect(colour_mesh)


func colour_mesh():
	var generator: MeshGenerator = $"../MeshGenerator"
	var simulator: SimulationPipeline = $"../SimulationPipeline"

	var data := PackedFloat32Array()
	
	for i in range(generator.polyhedron.faces.size()):
		match vis_type:
			0: data.append(randf())
			1: data.append(simulator.cells[i].plate_id)
			2: data.append(simulator.cells[i].unit_pos.y/2 + 0.5)
			3: data.append(simulator.cells[i].debug_neighbour_stress)
			4: data.append(simulator.cells[i].height)
	
	while data.size() % 4 != 0.0:
		data.append(0.0)
	
	var tex_size = ceil(sqrt(ceil(data.size() / 4)))
	
	var tex = create_data_texture(data, tex_size)
	$"../MeshInstance3D".material_override.set_shader_parameter("data_tex", tex)
	$"../MeshInstance3D".material_override.set_shader_parameter("data_tex_size", tex_size)
	$"../MeshInstance3D".material_override.set_shader_parameter("vis_type", vis_type)


func create_data_texture(data: PackedFloat32Array, tex_size : int) -> Texture2D:
	var img := Image.create(tex_size, tex_size, false, Image.FORMAT_RGBAF)
	
	var i = 0
	for y in range(tex_size):
		for x in range(tex_size):
			if i + 3 < data.size():
				img.set_pixel(x, y, Color(
					data[i + 0],
					data[i + 1],
					data[i + 2],
					data[i + 3]
				))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			i += 4
	
	return ImageTexture.create_from_image(img)
