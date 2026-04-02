@tool
extends Node
class_name SimulationPipeline

signal finished

@export var mesh : MeshGenerator
@export var visualiser : CellDataVisualiser

@export var pipeline : Array[SimulationStep]

@export_tool_button("Simulate", "SphereMesh") var simulate_action = run_pipeline
@export var pipeline_start_stage : int = 0

@export_group("Save and load")
@export_tool_button("Save planet data", "Save") var save_data_action = save_sim_data
@export_tool_button("Load planet data", "Load") var load_data_action = load_sim_data

var cells : Array[CellData]
var ocean_currents : Array[OceanCurrent]


func init_cells() -> Array[CellData]:
	cells = []
	cells.resize(mesh.polyhedron.faces.size())
	for i in range(cells.size()):
		cells[i] = CellData.new(i, mesh.polyhedron.centroids[mesh.polyhedron.faces[i][0]].normalized())
		#cells[i].id = i
		#cells[i].unit_pos = mesh.polyhedron.centroids[mesh.polyhedron.faces[i][0]].normalized()
		for j in mesh.polyhedron.adjacency[i].size():
			cells[i].neighbours.append(mesh.polyhedron.adjacency[i][j])
	
	ocean_currents.clear()
	return cells


func run_pipeline():
	if pipeline_start_stage == 0: init_cells()
	
	var t = Time.get_unix_time_from_system()
	
	var times : Array[float]
	times.resize(pipeline.size())
	
	for i in range(pipeline_start_stage, pipeline.size()):
		var _t = Time.get_unix_time_from_system()
		pipeline[i].simulate(cells, self)
		times[i] = Time.get_unix_time_from_system()-_t
	
	print("Finished generation with ", len(cells), " cells in ", str(Time.get_unix_time_from_system()-t), " seconds.")
	var s = ""
	for i in range(len(times)):
		s += "%2d: %.3fs \t" % [i, times[i]]
	print(s)
	
	finished.emit()


func save_sim_data():
	print("Saving simulation data to ", OS.get_data_dir())
	PlanetSimSaveData.write_save(cells)


func load_sim_data():
	print("Loading simulation data")
	var save = PlanetSimSaveData.load_save()
	cells = save.parse_cells()
	finished.emit()
