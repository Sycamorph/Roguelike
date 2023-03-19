extends Node2D

var lifebar = preload("res://src/UI/HealthBar.tscn")


func _on_CombatArena_lifebar_appears(battler) -> void:
	var new_lifebar = lifebar.instantiate()
	add_child(new_lifebar)
	new_lifebar.position = battler.position
	new_lifebar.get_child(0).initialize(battler.job.stats.health, battler.job.stats.max_health)
	battler.connect("health_changed",Callable(new_lifebar.get_child(0),"health_changed"))
