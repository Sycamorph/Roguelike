extends TextureProgressBar


func initialize(current, maximum):
	max_value = maximum
	value = current
	
	
func health_changed(new_health, max_health):
	max_value = max_health
	print("Changing health")
	await animate_value(new_health)
	if value == 0:
		queue_free()
	
func animate_value(target, tween_duration=0.5):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, 'value', target, tween_duration)
	tween.play()
	await tween.finished
