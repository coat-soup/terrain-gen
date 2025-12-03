@tool
extends Node
class_name SimulationPipeline

signal finished

@export var mesh : MeshGenerator
@export var visualiser : CellDataVisualiser

@export var pipeline : Array[SimulationStep]

@export_tool_button("Simulate", "SphereMesh") var simulate_action = run_pipeline
@export var pipeline_start_stage : int = 0

var cells : Array[CellData]
var ocean_currents : Array[OceanCurrent]


func init_cells() -> Array[CellData]:
	cells = []
	cells.resize(mesh.polyhedron.faces.size())
	for i in range(cells.size()):
		cells[i] = CellData.new(i, mesh.polyhedron.centroids[mesh.polyhedron.faces[i][0]].normalized())
		for j in mesh.polyhedron.adjacency[i].size():
			cells[i].neighbours.append(mesh.polyhedron.adjacency[i][j])
	
	ocean_currents.clear()
	
	return cells


func run_pipeline():
	if pipeline_start_stage == 0: init_cells()
	
	for i in range(pipeline_start_stage, pipeline.size()):
		pipeline[i].simulate(cells, self)
	
	finished.emit()


func get_face_center_pos():
	pass
