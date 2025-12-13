@tool
extends Node
@export var generator : Node
@export_tool_button("Load", "Callable") var load_action = load_data


func load_data():
	print("Loading data to C# generator")
	var data = PlanetSimSaveData.load_save()
	generator.call("CreateTreeFromDataArrays", data.neighbours, data.unit_pos, data.height, data.wind_dir, data.precipitation, data.climate_zone_id)
	
