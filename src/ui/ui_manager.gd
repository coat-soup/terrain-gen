extends Control

@onready var player_speed: Label = $PlayerInfo/PlayerSpeed
@onready var player_height: Label = $PlayerInfo/PlayerHeight
@onready var fps: Label = $RenderInfo/FPS
@onready var frametime: Label = $RenderInfo/Frametime
@onready var trees: Label = $RenderInfo/Trees
@onready var player: PlayerMovement = $"../Player"
@onready var terrain_generator: TerrainGenerator = $"../TerrainGenerator"
@onready var foliage_generator: Node = $"../FoliageGenerator"


func _process(delta: float) -> void:
	player_speed.text = "Speed: %.1fm/s" % player.get_real_velocity().length()
	player_height.text = "Height: %.1fm" % (player.global_position.length() - terrain_generator.planetRadius)
	frametime.text = "Frametime: %.2fms" % (delta * 1000)
	fps.text = "FPS: %.0f" % (1.0/delta)
	trees.text = "Trees: %d" % foliage_generator.nTrees;
	
