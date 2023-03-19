extends Battler

class_name Block

func _ready():
	type = "Block"

func destroy():
	queue_free()


