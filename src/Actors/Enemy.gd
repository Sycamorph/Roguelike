extends Battler

class_name Enemy
signal died(battler)


func _ready():
	type = "Enemy"

func update_stats():
	emit_signal("health_changed", stats.health, stats.max_health)
	if stats.health <= 0:
		emit_signal("died", self)
		queue_free()
