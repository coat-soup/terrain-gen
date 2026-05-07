extends Control

@onready var player_speed: Label = $PlayerInfo/PlayerSpeed
@onready var player_height: Label = $PlayerInfo/PlayerHeight
@onready var player_coords: Label = $PlayerInfo/PlayerCoords

@onready var fps: Label = $RenderInfo/FPS
@onready var frametime: Label = $RenderInfo/Frametime
@onready var trees: Label = $RenderInfo/Trees

@onready var climate_zone: Label = $WorldInfo/ClimateZone
@onready var landform: Label = $WorldInfo/Landform

@onready var player: PlayerMovement = $"../Player"
@onready var terrain_generator: TerrainGenerator = $"../TerrainGenerator"
@onready var foliage_generator: Node = $"../FoliageGenerator"
@onready var save_data_loader: Node = $"../TerrainGenerator/SaveDataLoader"

var player_cell : int = -1

var cells : Array[CellData] = []


func _process(delta: float) -> void:
	player_speed.text = "Speed: %.1fm/s" % player.get_real_velocity().length()
	player_height.text = "Height: %.1fm" % (player.global_position.length() - terrain_generator.planetRadius)
	frametime.text = "Frametime: %.2fms" % (delta * 1000)
	fps.text = "FPS: %.0f" % (1.0/delta)
	trees.text = "Trees: %d" % foliage_generator.nTrees;
	
	var ln = Util.PositionToLatLong(player.global_position)
	player_coords.text = "%.1f%s %.1f%s" % [ln.x, "N" if ln.x >= 0 else "S", ln.y, "W" if ln.y >= 0 else "E"]
	
	player_cell = terrain_generator.CellIDFromNormal(player.global_position.normalized(), player_cell)
	if len(cells) == 0:
		if save_data_loader.data: cells = save_data_loader.data.parse_cells()
		else: print("no save data data: ", save_data_loader.data)
	else:
		climate_zone.text = "Climate: " + str(cells[player_cell].climate_zone_id)
		landform.text = "Landform: " + terrain_generator.landforms[cells[player_cell].landform_id].name
