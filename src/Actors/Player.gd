extends Battler

class_name Player

signal experience_gained(growth_data)
signal update_label(level, experience, experience_required)
signal hero_died()
signal switch_action(character)

# Leveling
@export var level = 1
var experience = 0
var experience_total = 0
var experience_required = get_required_experience(level + 1)

var target 
var selected_action_id = 0
var spam_prevention = 0

var menu = null

enum {
# Types of spells
		CASTER, AOE, SHOOT_BASIC, REPEAT, CHAIN,
# Commands
		ADD_STAT,
# Stats
		HEALTH, MANA
		}

func _ready():
	type = "Player"
	for i in range(100):
		actions.add_random_block()
		
func player_initialize():
	actions.add_ability(self, [[CASTER, ADD_STAT, HEALTH, 1, 0]], "Heal")
	actions.add_ability(self, [[CASTER, ADD_STAT, HEALTH, 1, 0.1],	# Heal the caster for 1, cooldown for 0.1 seconds
				[SHOOT_BASIC, 1, 0.5, 0, 0, # Then shoot a basic projectile with asize of 100%, speed of 2 tiles/s, with horizontal and vertical acceleration of 1 and -1
					[[AOE, 10, [[CASTER, ADD_STAT, HEALTH, -1, 0]], 0]], 0.5, # while producing AOE that hurts every 0.5 seconds in area of 1 tile
					[[CASTER, ADD_STAT, HEALTH, -1, 0], # and then damages the target for 1 on hit
						[CASTER, ADD_STAT, HEALTH, -1, 0]], # and then again damages the target for 1 on hit
					0],	# 0 cooldown
				[CASTER, ADD_STAT, HEALTH, 1, 0],	# Heal the caster again
				[CASTER, ADD_STAT, HEALTH, 1, 0]], "Attack")

func _physics_process(delta: float) -> void:
	var direction: = get_direction()	# Keep global parameters to a minimum
	velocity = calculate_move_velocity(velocity, direction, stats.speed)
	set_velocity(velocity)
	move_and_slide()
	update_location()
	if Input.is_action_pressed("use_ability"):
		target = get_global_mouse_position() - Vector2(World.GRID_SIZE, World.GRID_SIZE) / 2
		use_ability(target)
	if Input.is_action_just_released("scroll_down"):
		selected_action_id = selected_action_id - 1 if selected_action_id > 0 else available_actions.size() - 1
		selected_action = available_actions[selected_action_id]
		emit_signal("switch_action", self)
	if Input.is_action_just_released("scroll_up"):
		selected_action_id = selected_action_id + 1 if selected_action_id < available_actions.size() - 1 else 0
		selected_action = available_actions[selected_action_id]
		emit_signal("switch_action", self)
		
	spam_prevention = max(0, spam_prevention - 1)
	
# Action
func use_ability(target):
	if spam_prevention == 0:
		spam_prevention = 5	# Can only fire every 5 frames
		selected_action.act(self, target)
	

# Movement
func get_direction() -> Vector2:
	return Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

func update_stats():
	emit_signal("health_changed", stats.health, stats.max_health)
	if stats.health <= 0:
		emit_signal("hero_died")


# Level
func get_required_experience(level):
	return round(pow(level, 1.6) + level * 4 + 10)

func gain_experience(amount):
	experience_total += amount
	experience += amount
	var growth_data = []
	while experience >= experience_required:
		experience -= experience_required
		growth_data.append([experience_required, experience_required])
		level_up()
	growth_data.append([experience, experience_required])
	emit_signal("experience_gained", growth_data)
		
func level_up():
	level += 1
	experience_required = get_required_experience(level + 1)
	var stats = ["max_health", "strength", "magic", "speed"]	# TODO: Make not random
	var random_stat = stats[randi() % stats.size()]	# $ means mod
	stats.set(random_stat, stats.get(random_stat) + randi() % 4 + 2)
	emit_signal("update_label", level, experience, experience_required)


