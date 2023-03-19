extends Node2D

@onready var world = $World
@onready var interface = $Interface

var player : Battler

var menu = null


func _ready() -> void:
	world.initialize()
	world.player.connect("switch_action",Callable(interface,"update_text"))
	


func _on_world_initialized(_player):
	player = _player
	interface.initialize(player)
