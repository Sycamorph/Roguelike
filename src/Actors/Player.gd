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
	actions.add_ability(self, [["CASTER", "ADD_STAT", "HEALTH", 1, 1]], "Heal")
	var hurt_ability = actions.add_ability(self, [["CASTER", "ADD_STAT", "HEALTH", -1, 1]], "Hurt")
	hurt_ability.used_in_another = true
	hurt_ability.used_in = actions.add_ability(self, [["SHOOT_BASIC", 1, 1, 0, -1, [], 1, hurt_ability, 1]], "Shoot")

func _physics_process(delta: float) -> void:
	var direction: = get_direction()	# Keep global parameters to a minimum
	velocity = calculate_move_velocity(velocity, direction, stats.speed)
	set_velocity(velocity)
	move_and_slide()
	update_location()
	if Input.is_action_pressed("use_ability"):
		target = get_global_mouse_position()
		use_ability(target)
	spam_prevention = max(0, spam_prevention - 1)	# Action spam prevention
	
func _input(event):
	if Input.is_action_just_released("scroll_down"):	# TODO: Remove all this, add equip button to actions
		var action_list = available_actions.duplicate()
		for i in action_list:
			var current_id = action_list.find(i)
			if action_list[current_id].used_in_another:
				action_list.remove_at(current_id)
		var selected_action_id = 0
		if selected_action in action_list:
			selected_action_id = action_list.find(selected_action)
		selected_action_id = selected_action_id - 1 if selected_action_id > 0 else action_list.size() - 1
		selected_action = action_list[selected_action_id]
		emit_signal("switch_action", self)
	if Input.is_action_just_released("scroll_up"):
		var action_list = available_actions.duplicate()
		for i in action_list:
			var current_id = action_list.find(i)
			if action_list[current_id].used_in_another:
				action_list.remove_at(current_id)
		var selected_action_id = 0
		if selected_action in action_list:
			selected_action_id = action_list.find(selected_action)
		selected_action_id = selected_action_id + 1 if selected_action_id < action_list.size() - 1 else 0
		selected_action = action_list[selected_action_id]
		emit_signal("switch_action", self)
		
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


