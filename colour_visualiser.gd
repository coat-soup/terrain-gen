@tool
extends Node
class_name ColourVisualiser

@export_tool_button("ColourMesh", "SphereMesh") var colour_action = colour_mesh

const ELEMENTS_PER_PIXEL = 4

func _ready() -> void:
	colour_mesh()


func colour_mesh():
	var generator: MeshGenerator = $"../MeshGenerator"
	
	var data := PackedFloat32Array()
	
	for i in range(generator.polyhedron.faces.size()):
		data.append(randf())
	
	var tex_size = ceil(sqrt(ceil(data.size() / 4)))
	
	var tex = create_data_texture(data, tex_size)
	$"../MeshInstance3D".material_override.set_shader_parameter("data_tex", tex)
	$"../MeshInstance3D".material_override.set_shader_parameter("data_tex_size", tex_size)


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
