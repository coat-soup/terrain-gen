@tool
extends Node
class_name SimulationPipeline

signal finished

@export var mesh : MeshGenerator
@export var visualiser : CellDataVisualiser

@export var pipeline : Array[SimulationStep]

@export_tool_button("Simulate", "SphereMesh") var simulate_action = run_pipeline

var cells : Array[CellData]


func init_cells() -> Array[CellData]:
	cells = []
	cells.resize(mesh.polyhedron.faces.size())
	for i in range(cells.size()):
		cells[i] = CellData.new(i, mesh.polyhedron.centroids[mesh.polyhedron.faces[i][0]].normalized())
		for j in mesh.polyhedron.adjacency[i].size():
			cells[i].neighbours.append(mesh.polyhedron.adjacency[i][j])
	
	return cells


func run_pipeline():
	init_cells()
	
	for step in pipeline:
		step.simulate(cells)
	
	finished.emit()


func get_face_center_pos():
	pass
