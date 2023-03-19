extends SpinBox

var block_id : int	# Block ID in the order
signal change_value_block(connected_block, new_value)

func _ready():
	step = 1

func _value_changed(new_value):
	emit_signal("change_value_block", block_id, value)
