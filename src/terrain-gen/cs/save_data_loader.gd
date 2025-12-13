extends Node
@export var generator : Node
@export var visualiser : OctreeVisualiser

func _ready() -> void:
	load_data()
	visualiser.parse_tree()


func load_data():
	print("Loading data to C# generator")
	var data = PlanetSimSaveData.load_save()
	generator.call("CreateTreeFromDataArrays", data.neighbours, data.unit_pos, data.height, data.wind_dir, data.precipitation, data.climate_zone_id)
