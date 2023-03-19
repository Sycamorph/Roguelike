extends ColorRect

@onready var animplayer = $AnimationPlayer


func fade_to_color():
	animplayer.play("fade_to_color")
	await animplayer.animation_finished
	

func fade_from_color():
	animplayer.play_backwards("fade_to_color")
	await animplayer.animation_finished
