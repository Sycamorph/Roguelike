extends VBoxContainer

var button = preload("res://src/UI/Button.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_SelectArrow_build_actions(actions) -> void:
	for i in actions:
		var new_button = button.instantiate()
		add_child(new_button)
		new_button.assigned_action = i
		new_button.update_text(i.action_name)
		new_button.connect("button_pressed",Callable(get_parent().select_arrow,"_on_action_chosen"))


func die():
	for i in get_children():
		i.queue_free()
