extends TextureButton


@onready var label = $Label


func update_text(text) -> void:
	label.text = text
	label.offset_top = (size.y - label.size.y)/2
	size.x += label.size.x

