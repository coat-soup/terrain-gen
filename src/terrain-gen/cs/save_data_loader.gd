@tool
extends Node
@export var generator : Node
@export var visualiser : OctreeVisualiser

@export_tool_button("Delete Chunk Data", "TextFile") var delete_chunk_action = delete_chunks


func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	load_data()
	visualiser.parse_tree()


func load_data():
	print("Loading data to C# generator")
	var data = PlanetSimSaveData.load_save()
	generator.call("CreateTreeFromDataArrays", data.neighbours, data.unit_pos, data.height, data.wind_dir, data.precipitation, data.climate_zone_id)
	generator.call("LoadChunksAroundCamera")


func delete_chunks():
	print("deleting chunk data")
	const ChunkSaveData = preload("res://terrain-gen/cs/ChunkSaveData.cs")
	ChunkSaveData.ClearAllChunkData()
