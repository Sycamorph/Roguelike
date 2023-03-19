extends Marker2D


signal target_selected(target)
signal action_selected(action)
signal build_actions(actions)
var current_target : Battler
var mode = "free"	# "target" or "action"
var all_targets = []
@onready var anim = $Sprite2D/AnimationPlayer
@onready var tween = $Sprite2D/Tween

func _on_CombatArena_target_cursor_appears(available_targets, selected_mode) -> void:
	mode = selected_mode
	print(available_targets)
	if mode == "target":
		all_targets = available_targets
		current_target = available_targets[0]
		anim.play("Appear")
		tween_play()
		update()
	elif mode == "action":
		emit_signal("build_actions", available_targets)
	
	
func _on_action_chosen(action):
	emit_signal("action_selected", action)
	target_cursor_disappears()
	get_parent().action_menu.die()
	
	
func target_cursor_disappears():
	anim.play("Disappear")
	tween.stop($Sprite2D, "position")
	$Sprite2D.position = Vector2(64, -32)
	mode = "free"
	current_target = null
	
	
func tween_play():
	tween.start()
	tween.set_repeat(true)
	tween.interpolate_property($Sprite2D, "position",
		Vector2(64, -32), Vector2(96, -32), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property($Sprite2D, "position",
		Vector2(96, -32), Vector2(64, -32), 1,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 1)


func update():
	position = current_target.position
	
	
func _process(delta):
	if mode == "target":
		if Input.is_action_just_pressed("ui_up"):
			move_up()
		elif Input.is_action_just_pressed("ui_down"):
			move_down()
		elif Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right"):
			change_side()
		elif Input.is_action_just_pressed("ui_accept"):
			emit_signal("target_selected", current_target)
			target_cursor_disappears()

func move_up():
	var targets = []
	for i in all_targets:
		if i.playable == current_target.playable:
			targets.append(i)
	var old_index = targets.find(current_target)
	var new_index = (old_index - 1) % len(targets)
	current_target = targets[new_index]
	update()
	

func move_down():
	var targets = []
	for i in all_targets:
		if i.playable == current_target.playable:
			targets.append(i)
	var old_index = targets.find(current_target)
	var new_index = (old_index + 1) % len(targets)
	current_target = targets[new_index]
	update()
	
func change_side():
	for i in all_targets:
		if i.playable != current_target.playable:
			current_target = i
			update()
			break

