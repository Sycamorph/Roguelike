extends CharacterBody2D

class_name Battler

@onready var sprite = $Sprite2D
@onready var stats = $Stats
@onready var actions = $Actions
@onready var hitbox = $HitboxShape
@export var playable = false
@export var exp_worth : int
@export var battler_name = "Name"


var grid_position : Vector2
var available_actions = []
var selected_action : Action
var type : String

signal health_changed(current, maximum)
signal create_projectile(source, target, blocks, projectile_type, exceptions)


func initialize():
	for action in actions.get_children():
		if action.get_class() == "Action":
			available_actions.append(action)
	if available_actions.size() > 0:
		selected_action = available_actions[0]
	stats.health = stats.max_health
	stats.mana = stats.max_mana
	player_initialize()
	
func player_initialize():
	pass
	
func update_stats():
	pass
	
func update_location():
	grid_position.x = int(round(position.x / World.GRID_SIZE))
	grid_position.y = int(round(position.y / World.GRID_SIZE))

func calculate_move_velocity(linear_velocity: Vector2, direction: Vector2, speed: float) -> Vector2:
	var new_velocity: = linear_velocity
	new_velocity.x = speed * direction.x * World.GRID_SIZE
	new_velocity.y = speed * direction.y * World.GRID_SIZE
	new_velocity = new_velocity.limit_length(speed * World.GRID_SIZE)
	return new_velocity

func shoot(source, target, blocks, type, extra_exceptions):
	emit_signal("create_projectile", source, target, blocks, type, extra_exceptions)
