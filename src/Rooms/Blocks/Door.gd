extends Block

@export var closed = false

func _ready():
	if closed:
		close_door()

func open_door():
	hitbox.set_deferred("disabled", true)
	
func close_door():
	hitbox.set_deferred("disabled", false)
