extends TextureProgressBar


func initialize(current, maximum):
	max_value = maximum
	value = current


func experience_gained(growth_data):
	for line in growth_data:
		var target_experience = line[0]
		var max_experience = line[1]
		max_value = max_experience
		await animate_value(target_experience)
		if abs(max_value - value) < 0.01:
			value = 0
	
	
func animate_value(target, tween_duration=0.5):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, 'value', target, tween_duration)
	tween.play()
	await tween.finished
