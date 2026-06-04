@tool
extends Node3D

@export var active : bool = false

@export var spin_length : float = 10.0
@export var vis_length : float = 5.0

@export var vis_layers : Array[CellDataVisualiser.VisualisationType]

@onready var cell_data_visualiser: CellDataVisualiser = $"../CellDataVisualiser"

var percent : float = 0.0

func _process(delta: float) -> void:
	if Engine.is_editor_hint() and active:
		rotate_y(2 * PI * 1.0/spin_length * delta)
		
		percent += 1/vis_length * delta
		if percent > 1: percent -= 1
		
		cell_data_visualiser.vis_type = vis_layers[int(percent * len(vis_layers))]
		#cell_data_visualiser.colour_mesh()
	else:
		percent = 0
