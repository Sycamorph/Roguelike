extends TextureButton


@onready var label = $Label
var assigned_block
var is_in_builder_lines = false	# True if it's a part of the description
var is_ability = false

var block_id = 0	# Block ID in the order
signal block_pressed(block, button)
signal builder_block_pressed(block_id, block, button)


func update_text(new_text=null) -> void:
	var text
	if new_text == null:
		if is_ability:
			text = "%s" % assigned_block.ability_name
		else:
			text = "%s (%d)" % [assigned_block.contents, assigned_block.amount]
	else:
		text = new_text
	label.text = text
	label.offset_top = (size.y - label.size.y)/2
	size.x += label.size.x


func _pressed():
	emit_signal("block_pressed", assigned_block, self)
	emit_signal("builder_block_pressed", block_id, assigned_block, self)
