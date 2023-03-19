extends Control

@onready var base_screen = $BaseScreen
@onready var action_builder = $ActionBuilder
@onready var available = $BaseScreen/AvailableBlocks/BlockController
@onready var abilities = $BaseScreen/Abilities/BlockController
@onready var builder_available = $ActionBuilder/AvailableBlocks/BlockController
@onready var builder_lines = $ActionBuilder/BlockEditor/Lines
var current_ability : Action	# The ability that is being edited
var current_block : ActionBlock	# The starting block of the current ability
var stored_block	# The block that is being dragged and dropped
var current_fragment = []	# The ability
var current_name : String
var available_blocks = []
var available_actions = []

var stage = 0	# Current stage of ability creation


var player : Battler

var button = preload("res://src/UI/BlockButton.tscn")

signal change_menu(menu)

func initialize(character):
	player = character
	visible = true
	update_available()
	build_menu()

func update_available():
	available_blocks = player.actions.blocks.get_children()
	available_actions = player.available_actions

func hide_menu():
	visible = not visible

func build_menu() -> void:
	clear_buttons()	# Rebuilding from scratch every time
	for i in available_blocks:
		if i.type != "BLOCK":
			continue
		var new_button = button.instantiate()
		available.add_child(new_button)
		new_button.assigned_block = i
		new_button.update_text()
		new_button.connect("block_pressed",Callable(self,"block_pressed"))
	for i in available_actions:
		if i.used_in_another:	# These are handled later
			continue
		var new_button = button.instantiate()
		abilities.add_child(new_button)
		new_button.is_ability = true
		new_button.assigned_block = i
		new_button.update_text()
		new_button.connect("block_pressed",Callable(self,"block_pressed"))
		add_sub_abilities(i, 1)

func add_sub_abilities(ability : Action, depth, offset=16):
	for i in ability.used_blocks:
		if i is Action:
			var new_container = MarginContainer.new()
			abilities.add_child(new_container)
			new_container.add_theme_constant_override("margin_left", depth * offset)
			var new_button = button.instantiate()
			new_container.add_child(new_button)
			new_button.is_ability = true
			new_button.assigned_block = i
			new_button.update_text()
			new_button.connect("block_pressed",Callable(self,"block_pressed"))
			add_sub_abilities(i, depth + 1)

func block_pressed(block, button):	# The first block or an ability is pressed
	initialize_action_builder(block, button)
	
func initialize_action_builder(block, button):
	clear_buttons()
	if button.is_ability:	# Selected an ability to edit
		current_ability = button.assigned_block
		current_fragment = current_ability.used_blocks.duplicate()
		stage = current_fragment.size()
		current_block = current_fragment[0]
		current_name = current_ability.ability_name
	else:	# Selected a starting block
		stage = 1 
		current_block = block
		current_fragment = []
		for i in range(block.order.size()):
			current_fragment.append(0)
		current_fragment[0] = current_block
		player.actions.remove_block(current_block)
	base_screen.visible = false
	action_builder.visible = true
	build_action_builder()
	build_action_lines()
	
func build_action_builder():	# Called after every stage completed
	print(stage)
	clear_buttons()
	if stage >= current_block.order.size():
		create_confirm_button()
	else:
		var element = current_block.order[stage]
		var new_category = Label.new()
		new_category.text = "ABILITY"
		builder_available.add_child(new_category)
		if element in ActionBlock.VALUE_TYPES:
			stage += 1
			build_action_builder()
			return
		else:
			for i in available_blocks:
				if i.type != element:
					continue
				var new_button = button.instantiate()
				builder_available.add_child(new_button)
				new_button.assigned_block = i
				new_button.update_text()
				new_button.connect("builder_block_pressed",Callable(self,"builder_block_pressed"))
		if element in ActionBlock.OPTIONAL:
			stage += 1	# Can leave it as nothing and continue
			build_action_builder()
			return
	if "ABILITY" in current_block.order.slice(0, stage):
		var new_category = Label.new()
		new_category.text = "ABILITY"
		builder_available.add_child(new_category)
		for i in available_actions:
			if not i.used_in_another and not i == self:	# No making infinite loops
				var new_button = button.instantiate()
				builder_available.add_child(new_button)
				new_button.is_ability = true
				new_button.assigned_block = i
				new_button.update_text()
				new_button.connect("builder_block_pressed",Callable(self,"builder_block_pressed"))
	create_delete_button()
				
func build_action_lines(clear=true):
	if clear:
		clear_action_lines()
	var new_label = Label.new()
	builder_lines.add_child(new_label)
	new_label.text = "Ability editor"
	new_label = Label.new()
	builder_lines.add_child(new_label)
	new_label.text = current_block.descriptions["BLOCK"]	# Base description
	for i in range(1, min(stage, current_fragment.size()-1)+1):
		var element = current_block.order[i]
		new_label = Label.new()
		builder_lines.add_child(new_label)
		var desc = current_block.descriptions[element]
		if desc is String:
			new_label.text = desc
		else: # Multiple possibilities
			var count = 0
			for j in range(current_block.order.size()):	# Searching for the occurances of it
				if current_block.order[j] == element:
					if j == i:	# Found it
						break
					count +=1
			new_label.text = desc[count]
		if element in ActionBlock.VALUE_TYPES and not element in current_block.editable_values:
			if element in ActionBlock.HIDDEN_VALUES and not element in current_block.editable_values:
				new_label.queue_free()
				continue
			new_label.text += "%d" % current_block.defaults[element]
			current_fragment[i] = current_block.defaults[element]
		elif element in current_block.editable_values:
			var new_spinbox = preload("res://src/UI/ValueBox.tscn").instantiate()
			builder_lines.add_child(new_spinbox)
			new_spinbox.min_value = -player.level
			new_spinbox.max_value = player.level
			new_spinbox.block_id = i
			if current_fragment[i] == 0:
				new_spinbox.value = current_block.defaults[element]
				current_fragment[i] = current_block.defaults[element]
			else:
				new_spinbox.value = current_fragment[i]
			new_spinbox.connect("change_value_block", Callable(self, "change_value_block"))
		else:
			var new_block_holder = button.instantiate()	# Empty button, nothing happens if clicked
			builder_lines.add_child(new_block_holder)
			new_block_holder.assigned_block = null
			new_block_holder.is_in_builder_lines = true
			new_block_holder.block_id = i
			if element == "ABILITY":
				new_block_holder.is_ability = true
				new_block_holder.update_text("Nothing")
				if not current_fragment[i] is Action:
					current_fragment[i] = []
			if current_fragment[i] is ActionBlock or current_fragment[i] is Action:
				new_block_holder.assigned_block = current_fragment[i]
				new_block_holder.update_text()
			new_block_holder.connect("builder_block_pressed",Callable(self,"builder_block_pressed"))
	new_label = Label.new()
	builder_lines.add_child(new_label)
	new_label.text = "Ability name: "
	var new_line_edit = LineEdit.new()
	builder_lines.add_child(new_line_edit)
	if current_name:
		new_line_edit.text = current_name
	new_line_edit.connect("text_changed", Callable(self, "change_ability_name"))

func change_ability_name(new_name):
	current_name = new_name

func change_value_block(block_id, new_value):
	if current_fragment.size() < block_id:
		return	# Prevent the crash when quitting
	current_fragment[block_id] = new_value

func builder_block_pressed(block_id, block, button):
	if button.is_in_builder_lines:
		
		if button.assigned_block == null:
			if stored_block:
				button.assigned_block = stored_block
				button.update_text()
				add_block(block_id, stored_block)	# Adding to the current fragment
				stored_block = null
		else:
			remove_block(block_id)
		return
	else:
		stored_block = block

func create_delete_button():
	var new_container = MarginContainer.new()
	builder_available.add_child(new_container)
	new_container.add_theme_constant_override("margin_left", 16)
	new_container.add_theme_constant_override("margin_top", 16)
	var new_button = preload("res://src/UI/Button.tscn").instantiate()
	new_container.add_child(new_button)
	new_button.update_text("Delete ability")
	new_button.connect("pressed",Callable(self,"delete_ability"))

func delete_ability():
	if current_ability:
		for i in current_ability.used_blocks:
			if i is Action:
				i.used_in = null
				i.used_in_another = false
		if current_ability.used_in_another:
			var id = current_ability.used_in.used_blocks.find(current_ability)
			current_ability.used_in.used_blocks[id] = []
			current_ability.used_in.update()
		player.actions.remove_ability(player, current_ability)
	current_ability = null
	back()

func create_confirm_button():
	if current_block.contents == "CHAIN" and current_fragment.size() < 4: 	# 1 - block, 2 - ability, 3 - ability, 4 - nothing
		return
	if current_block.contents == "REPEAT" and not current_fragment[1] is Action:
		return
	var new_button = preload("res://src/UI/Button.tscn").instantiate()
	builder_available.add_child(new_button)
	new_button.update_text("Confirm")
	new_button.connect("pressed",Callable(self,"confirm_ability"))
	
func confirm_ability():
	create_new_ability()
	back()
	
func create_new_ability():
	if current_ability:	# Replacing the edited ability with an updated one
		for i in current_fragment:
			if i is Action:
				i.used_in = current_ability	
		current_ability.used_blocks = current_fragment
		current_ability.ability_name = current_name
		if current_ability.used_in_another:
			player.actions.update_all(player)
		else:
			current_ability.update()
	else:
		current_ability = player.actions.add_ability(player, current_fragment, current_name)
		for i in current_fragment:
			if i is Action:
				i.used_in = current_ability
	current_ability = null
	current_fragment = []
	
func clear_action_lines():
	for i in builder_lines.get_children():
		i.queue_free()

func clear_buttons():
	for i in available.get_children():
		i.queue_free()
	for i in abilities.get_children():
		i.queue_free()
	for i in builder_available.get_children():
		i.queue_free()

func add_block(block_id, block):
	if block is ActionBlock:
		player.actions.remove_block(block)
	elif block is Action:
		block.used_in_another = true
	current_fragment[block_id] = block
	if not block.type in ActionBlock.OPTIONAL:
		stage += 1
	if current_block.contents == "CHAIN":
		stage +=1 
		current_block.order.append("ABILITY")
		current_fragment.append(0)
	update_available()
	build_action_builder()
	build_action_lines()

func remove_block(block_id, chained=false):
	var block = current_fragment[block_id]
	current_fragment[block_id] = 0
	if block is ActionBlock:
		player.actions.add_block(block)
	elif block is Action:
		block.used_in = null
		block.used_in_another = false
	if not chained:	# Starting only 1 chain
		stage = block_id	# Reset to the point you clicked
		for i in range(block_id + 1, current_fragment.size()):	#Clearing everything after the removed block
			if current_fragment[i] is Action or current_fragment[i] is ActionBlock:
				remove_block(i, true)
		if current_block.contents == "CHAIN":
			current_fragment = current_fragment.slice(1, block_id)
		update_available()
		build_action_builder()
		build_action_lines()
		

func die():
	for i in get_children():
		i.queue_free()
		
func back():
	print("Back is called")
	if stage > 0:	# Going back to the base screen
		stage = 0 
		if current_ability:
			for i in current_fragment.size():
				if current_block.order[i] in ActionBlock.VALUE_TYPES:
					continue
				if current_fragment[i] is ActionBlock:
					if current_fragment[i] == current_ability.used_blocks[i]:
						continue
					else:
						player.actions.add_block(current_fragment[i])	# Return it to the player if it was replaced
					current_fragment[i] = current_ability.used_blocks[i]
					player.actions.remove_block(current_fragment[i])	# putting the blocks back into the ability
				elif current_fragment[i] is Action:
					if current_fragment[i] == current_ability.used_blocks[i]:
						continue
					else:
						current_fragment[i].used_in = null
						current_fragment[i].used_in_another = false
					current_fragment[i] = current_ability.used_blocks[i]
				else:	# Probably just a 0
					current_fragment[i] = current_ability.used_blocks[i]
					if current_fragment[i] is ActionBlock:
						player.actions.remove_block(current_fragment[i])
			create_new_ability()
		else:
			for i in current_fragment:	# Refund everything to the player
				if i is Action:
					i.used_in = null
					i.used_in_another = false
				elif i is ActionBlock:
					print("adding block")
					player.actions.add_block(i)
		current_fragment = []
		base_screen.visible = true
		action_builder.visible = false
		initialize(player)
		return
	hide_menu()	# Going back to the pause
	emit_signal("change_menu", "pause")

func _input(event):
	if event.is_action_pressed("open_menu"):
		if visible:
			back()
