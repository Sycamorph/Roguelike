extends Node2D

class_name ActionGenerator

signal create_ability(ability, used_blocks)

var ability_gen = preload("res://src/Actors/Actions/Action.tscn")
var block_gen = preload("res://src/Actors/Actions/Block.tscn")
@onready var blocks = $BlockContainer

func add_ability(target, blocks, ability_name="New Ability", cooldown=0, mana_consumed=0, active=true):
	var new_ability = ability_gen.instantiate()
	new_ability.ability_name = ability_name
	new_ability.active = active
	new_ability.blocks = blocks
	print(blocks)
	if blocks.size() > 0:
		if not blocks[0] is ActionBlock:	# Blocks are just a list of names
			for block in blocks[0]:
				if block is String:
					new_ability.used_blocks.append(create_block(block, 0, 1))
				else:
					new_ability.used_blocks.append(block)
		if new_ability.used_blocks[0] is ActionBlock:	# Successfully created actual blocks
			print("used blocks:")
			print(new_ability.used_blocks)
			new_ability.update()
	# Overwrite things
	new_ability.cooldown = cooldown
	new_ability.mana_consumed = mana_consumed
	target.actions.add_child(new_ability)
	target.available_actions.append(new_ability)
	if active:
		target.selected_action = new_ability
	new_ability.connect("create_projectile",Callable(target,"shoot"))
	sort_abilities(target)
	return new_ability

func add_random_block():
	var type = "Block"
	var possibilities = Action.new().block_dict.values()
	var contents = possibilities[randi() % possibilities.size()]
	add_block(create_block(contents, 0, 1))
	return

func create_block(contents, rarity, amount):
	var new_block = block_gen.instantiate()
	new_block.contents = contents 
	new_block.initialize_properties(contents)
	new_block.rarity = rarity
	new_block.amount = amount
	return new_block

func add_block(block):	# Adds 1 block
	for i in blocks.get_children():
		if (i.type == block.type 
		and i.contents == block.contents 
		and i.mana_worth == block.mana_worth 
		and i.rarity == block.rarity):
			i.amount += 1
			return
	blocks.add_child(block)
	sort_blocks(self)
	
func remove_block(block):
	block.amount -= 1
	
	if block.amount <= 0:
		block.queue_free()
		
func add_action_block(action, block):
	action.used_blocks.append(block)
	action.update()
		
func move_block_from_action(block_id, action : Action):
	var block = action.used_blocks[block_id]
	action.used_blocks.remove_at(block_id)
	add_block(block)
	action.update()
	
func remove_ability(target, ability):
	target.actions.remove_child(ability)
	target.available_actions.remove_at(target.available_actions.find(ability))
	if ability.active:
		target.selected_action = target.available_actions[0]
	ability.queue_free()
	
func update_all(target : Battler):
	for i in target.available_actions:
		i.update()

func sort_abilities(target):
	target.available_actions.sort_custom(Callable(self, 'sort_abilities_names'))
	for i in target.available_actions:
		target.actions.move_child(i, 0)
	
static func sort_abilities_names(a: Action, b: Action) -> bool:
	return a.ability_name.naturalnocasecmp_to(b.ability_name) > 0

func sort_blocks(target):
	var sorting_blocks = target.blocks.get_children()
	sorting_blocks.sort_custom(Callable(self, 'sort_blocks_names'))
	for i in sorting_blocks:
		target.blocks.move_child(i, 0)
	
static func sort_blocks_names(a: ActionBlock, b: ActionBlock) -> bool:
	return a.contents.naturalnocasecmp_to(b.contents) > 0
