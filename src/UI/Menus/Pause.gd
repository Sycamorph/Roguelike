extends Control

var is_paused = false
signal change_menu(menu)


func _input(event):
	if event.is_action_pressed("open_menu"):
		if not get_tree().paused or visible:	# Switch state if the game isn't paused or if the pause screen is visible
			switch_pause_state()
		
func switch_pause_state():
	is_paused = not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused
	
func hide_menu():	# Hide / unhide this menu
	visible = not visible

func _on_resume_pressed():
	switch_pause_state()


func _on_spellcrafting_pressed():
	hide_menu()
	emit_signal("change_menu", "spellcraft")


func _on_quit_pressed():
	get_tree().quit()
