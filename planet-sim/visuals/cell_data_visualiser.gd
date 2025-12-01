@tool
extends Node
class_name CellDataVisualiser

enum VisualisationType {CELL_ID, PLATE_ID, CELL_POSITION, PLATE_STRESS, CELL_HEIGHT, CELL_TEMPERATURE, OCEAN_CURRENTS, WIND}
@export var vis_type : VisualisationType:
	set(new_vis_type):
		vis_type = new_vis_type
		colour_mesh()

@export_tool_button("ColourMesh", "SphereMesh") var colour_action = colour_mesh

var generator: MeshGenerator
var simulator: SimulationPipeline

func _ready() -> void:
	colour_mesh()
	$"../SimulationPipeline".finished.connect(colour_mesh)
	generator = $"../MeshGenerator"
	simulator = $"../SimulationPipeline"


func colour_mesh():
	generator = $"../MeshGenerator"
	simulator = $"../SimulationPipeline"

	var data := PackedFloat32Array()
	
	for i in range(generator.polyhedron.faces.size()):
		match vis_type:
			0: data.append(randf())
			1: data.append(simulator.cells[i].plate_id)
			2: data.append(simulator.cells[i].unit_pos.y/2 + 0.5)
			3: data.append(simulator.cells[i].debug_neighbour_stress)
			4: data.append(simulator.cells[i].height)
			5: data.append(simulator.cells[i].temperature if not simulator.cells[i].is_oceanic else -999.0)
			7: data.append(simulator.cells[i].wind_dir.length())
	if vis_type == 6: data = data_from_ocean_currents(simulator)
	
	while data.size() % 4 != 0.0:
		data.append(0.0)
	
	var tex_size = ceil(sqrt(ceil(data.size() / 4)))
	
	var tex = create_data_texture(data, tex_size)
	$"../MeshInstance3D".material_override.set_shader_parameter("data_tex", tex)
	$"../MeshInstance3D".material_override.set_shader_parameter("data_tex_size", tex_size)
	$"../MeshInstance3D".material_override.set_shader_parameter("vis_type", vis_type)


func _process(delta: float) -> void:
	if vis_type == 7:
		for cell in simulator.cells:
			pass
			DebugDraw3D.scoped_config().set_thickness(0.002)
			#DebugDraw3D.draw_line(cell.unit_pos, cell.unit_pos + cell.wind_dir / 100.0)
			var color : Color = Color.WHITE
			#color = Color(cell.wind_dir.x, cell.wind_dir.y, cell.wind_dir.z)
			DebugDraw3D.draw_arrow(cell.unit_pos, cell.unit_pos + cell.wind_dir.normalized() / 30.0, color, 0.003, true)


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


func data_from_ocean_currents(simulator : SimulationPipeline):
	var data := PackedFloat32Array()
	data.resize(simulator.cells.size())
	
	for i in range(simulator.cells.size()):
		data[i] = -1.0 if simulator.cells[i].height >= 0 else -2.0
	
	#return data
	
	for i in range(simulator.ocean_currents.size()):
		for c in simulator.ocean_currents[i].cells:
			data[c] =  simulator.ocean_currents[i].type
	
	return data
