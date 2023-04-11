extends Node2D

class_name Action

signal action_complete(success)
signal create_projectile(actor, target, blocks, projectile_type, exceptions)

const type = "ABILITY"

@onready var timer = $Timer



# All blocks are just numbers
enum {
# Types of spells
		CASTER, AOE, SHOOT_BASIC, REPEAT, CHAIN,
# Commands
		ADD_STAT,
# Stats
		HEALTH, MANA
		}
		
var block_dict = {
# Types of spells
		CASTER:"CASTER", AOE:"AOE", SHOOT_BASIC:"SHOOT_BASIC", REPEAT:"REPEAT", CHAIN:"CHAIN",
# Commands
		ADD_STAT:"ADD_STAT",
# Stats
		HEALTH:"HEALTH", MANA:"MANA"}

@export var ability_name = "Action"

@export var active = true	# Active or passive ability

@export var cooldown = 0
@export var on_cooldown = false

@export var mana_consumed = 0

var depth = []
var current_depth = 0
var last_depth = 0
var breaking_depth = 0

var used_in_another = false	# True if another action calls this action
var used_in : Action	# Where exactly it is used

var blocks = [[CASTER, ADD_STAT, HEALTH, 1, 0.1],	# Heal the caster for 1, cooldown for 0.1 seconds
				[SHOOT_BASIC, 1, 2, 1, -1, # Then shoot a basic projectile with asize of 100%, speed of 2 tiles/s, with horizontal and vertical acceleration of 1 and -1
					[[AOE, 1, [[CASTER, ADD_STAT, HEALTH, -1, 0], [CASTER, ADD_STAT, HEALTH, -1, 0]], 0]], 1, # while producing AOE that hurts every 1 second in area of 1 tile twice
					[[CASTER, ADD_STAT, HEALTH, -1, 0], # and then damages the target for 1 on hit
						[CASTER, ADD_STAT, HEALTH, -1, 0]], # and then again damages the target for 1 on hit
					0],	# 0 cooldown
				[CASTER, ADD_STAT, HEALTH, 1, 0],	# Heal the caster again
				[CASTER, ADD_STAT, HEALTH, 1, 0]]	

var used_blocks = []
#var used_blocks = ["CASTER", "ADD_STAT", "HEALTH", 1, 0.1, 
#					"SHOOT_BASIC", 1, 2, 1, -1,
#						"AOE", 1, 0, 
#					1,
#					"CASTER", "ADD_STAT", "HEALTH", -1, 0, 
#					"CASTER", "ADD_STAT", "HEALTH", -1, 0,
#					0,
#					"CASTER", "ADD_STAT", "HEALTH", 1, 0,
#					"CASTER", "ADD_STAT", "HEALTH", 1, 0]
#var used_blocks = ["CASTER", "ADD_STAT", "HEALTH", 1, 0.1, 
#					"SHOOT_BASIC", 1, 2, 1, -1,
#						"AOE", 1, 
#							"CASTER", "ADD_STAT", "HEALTH", -1, 0, 
#							"CASTER", "ADD_STAT", "HEALTH", -1, 0, 
#						0, 
#					1,
#					"CASTER", "ADD_STAT", "HEALTH", -1, 0, 
#					"CASTER", "ADD_STAT", "HEALTH", -1, 0,
#					0,
#					"CASTER", "ADD_STAT", "HEALTH", 1, 0,
#					"CASTER", "ADD_STAT", "HEALTH", 1, 0]
	
	
func update():
	mana_consumed = 0
	cooldown = used_blocks[-1]
	depth = []	# For the spellcrafting screen
	current_depth = 0
	print("Updating")
	blocks = compile_blocks(used_blocks)[0]
	print("Compiled")
	print(blocks)
	print(depth)
	print(depth.size())
	print(last_depth)
	print(breaking_depth)
	if used_blocks.size() != depth.size():
		return false	# Failed to build the ability, TODO
	
func cd_mana_cost(block):
	var cooldown = block.contents
	var a = 0.03
	var b = 1.5
	var c = 2
	var d = 0.07
	return round(a * pow(b, (1/(d*(cooldown + 1)))) - c)
	
func val_mana_cost(block):
	var value = block.contents
	var a = 2
	var b = 1.5 
	return round(a * (pow(b, abs(value)) - 1))
	
func size_mana_cost(block):
	var value = block.contents
	var a = 0.5
	var b = 3
	var c = 2
	var d = 1
	return round(a * (pow(b, (c * value - d)) - 1))

func add_first_block(block_to_add_to, _blocks):
	var new_block = _blocks[0]
	block_to_add_to.append(add_block(new_block))
	_blocks.remove_at(0)
	depth.append(current_depth)
	if new_block is ActionBlock:
		mana_consumed += new_block.mana_worth
	elif new_block is Action:
		mana_consumed += new_block.mana_consumed
		
func add_first_block_as_action(block_to_add_to, _blocks):
	var new_block = _blocks[0]
	block_to_add_to.append(new_block)
	_blocks.remove_at(0)
	depth.append(current_depth)
	mana_consumed += new_block.mana_consumed

func compile_blocks(blocks_to_use=used_blocks):	# A used block is a scene
	current_depth += 1	# Increase the current depth by 1 every time this is called
	var compiled_block = []
	var _blocks = blocks_to_use.duplicate(true)
	if _blocks.is_empty():
		current_depth -= 1
		last_depth = max(current_depth, last_depth)	# No overwriting
		return [[], _blocks]
	var block = _blocks[0]
	#if block is String:
	print("_blocks and blocks")
	print(_blocks)
	print(blocks)
	if block.type == "BLOCK":
		var block_to_compile = []
		if block.contents == "CHAIN":
			block_to_compile.append(CHAIN)
			_blocks.remove_at(0)	# Remove the chain signifier and add each ability
			var block_size = block.order.size() - 2	# - 1 for CHAIN, -1 for the placeholder at the end
			_blocks = _blocks.slice(0, block_size)
			for i in range(block_size):
				add_first_block_as_action(block_to_compile, _blocks)
		elif block.contents == "REPEAT":	# Adding the whole ability to blocks
			block_to_compile.append(REPEAT)
			_blocks.remove_at(0)	# Remove the repetition signifier and add the ability and value
			add_first_block_as_action(block_to_compile, _blocks)
			add_first_block(block_to_compile, _blocks)
		else:
			var n = block.contents
			var block_size = block.order.size()
			for i in range(block_size):
				if _blocks.is_empty():
					last_depth = current_depth
					break
	#			if block.order[i] == "VALUE":
	#				mana_consumed += val_mana_cost(_blocks[0])
	#			elif block.order[i] == "DELAY":	# It will be 1, add modifying code here
	#				mana_consumed += cd_mana_cost(_blocks[0])
	#			elif block.order[i] == "SIZE":	# It will be 1, add modifying code here
	#				mana_consumed += size_mana_cost(_blocks[0])
	#			elif block.order[i] == "SPEED":
	#				mana_consumed += size_mana_cost(_blocks[0])
	#			if block.order[i] == "ABILITY":
	#				var data = compile_blocks(_blocks)
	#				var aoe_blocks = data[0]
	#				_blocks = data[1]
	#				block_to_compile.append(aoe_blocks)
	#			else:
				add_first_block(block_to_compile, _blocks)
		compiled_block.append(block_to_compile)
		current_depth -= 1	# Return to the previous depth every time this ends
	else:
		breaking_depth = current_depth
		current_depth -= 1	# Return to the previous depth every time this ends
		return [[], _blocks]
	if not _blocks.is_empty():
		var data = compile_blocks(_blocks)
		var extra_blocks = data[0]
		_blocks = data[1]
		compiled_block.append_array(extra_blocks)
	return [compiled_block, _blocks]
	
func add_block(block):
	var value
	if block is Action:
		value = block.blocks
	elif not block is ActionBlock:
		value = block	# The block is just a number
	elif block.type == "VALUE":
		value = block.contents
	elif block.type == "ABILITY":
		value = block.contents.blocks
	else:
		value = block_dict.find_key(block.contents)
	return value

func act(actor, target = null, spell_range=64, extra_exceptions=[]):
	if on_cooldown:
		emit_signal("action_complete", false)
		return
	if actor.type == "Block":
		world_acts(actor, target, spell_range)
		return
	if actor.stats.mana < mana_consumed:
		emit_signal("action_complete", false)
		return
	if !is_instance_valid(actor):
		emit_signal("action_complete", false)
		return
	if target == null:	# Get a random target in range in case it is needed
		target = get_random_direction(actor)
	on_cooldown = true
	var action_succeeded = true
	var blocks_left = blocks.duplicate(true)
	while !blocks_left.is_empty():	# Not needed for abilities created through spellcrafting
		var block = blocks_left[0]
		if block[0] == CASTER:
			action_succeeded = self_act(actor, block)
			if block[-1] != 0:	# Delay is in the end
				timer.start(block[-1])
				await timer.timeout
		elif block[0] == SHOOT_BASIC or block[0] == AOE:
			action_succeeded = shoot_act(actor, target, block, extra_exceptions)
			if block[-1] != 0:	# Delay is in the end
				timer.start(block[-1])
				await timer.timeout
		elif block[0] == REPEAT:
			if block[-1] >= 0:	
				for i in range(block[-1]):
					action_succeeded = await block[1].act(actor, target, spell_range, extra_exceptions)
		elif block[0] == CHAIN:
			block.remove_at(0)
			for i in block:
				action_succeeded = await i.act(actor, target, spell_range, extra_exceptions)
		blocks_left.remove_at(0)
	if action_succeeded and is_instance_valid(actor):
		actor.stats.mana -= mana_consumed	# Mana is consumed only after the spell TODO: Remove mana?
	emit_signal("action_complete", true)
	if cooldown != 0:
		timer.start(cooldown)
		await timer.timeout
	on_cooldown = false

func force_cooldown(duration=cooldown):
	if duration != 0:
		on_cooldown = true
		timer.start(duration)
		await timer.timeout
		on_cooldown = false

func self_act(actor, block):
	if block[1] == ADD_STAT:
		return act_add_stat(actor, block[2], block[3])
	
func shoot_act(actor, target, blocks, extra_exceptions=[]):
	emit_signal("create_projectile", actor, target, blocks, block_dict[blocks[0]], extra_exceptions)
	return

func world_acts(actor, target, spell_range):
	emit_signal("action_complete", true)	# Doesn't matter
	return

func act_add_stat(target, stat, amount):
	if stat == HEALTH:
		target.stats.health = min(target.stats.max_health, target.stats.health + amount)
		target.update_stats()
		return true
	elif stat == MANA:
		target.stats.mana = min(target.stats.max_mana, target.stats.mana + amount)
		target.update_stats()
		return true

func get_random_direction(origin):
	var random_vector = Vector2.UP
	random_vector = random_vector.rotated(randi())
	return origin.position + random_vector

