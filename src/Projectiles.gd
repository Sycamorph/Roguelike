extends Node2D

var projectile_types = [preload("res://src/Actors/Projectiles/Projectile.tscn"),
		preload("res://src/Actors/Projectiles/AoE.tscn")]
var action = preload("res://src/Actors/Actions/Action.tscn")

func create_projectile(source, target, main, type, extra_exceptions=[]):
	if type == "SHOOT_BASIC":
		var new_projectile = projectile_types[0].instantiate()
		add_child(new_projectile)
		new_projectile.size_scale = main[1]
		new_projectile.stats.speed = main[2]
		new_projectile.acceleration = Vector2(main[3], main[4])
		new_projectile.hit_action = new_projectile.actions.add_ability(new_projectile, main[7])
		# Exception chain
		new_projectile.add_collision_exception_with(source)
		if source.type == "Projectile":
			for i in source.get_collision_exceptions():
				new_projectile.add_collision_exception_with(i)
		if source.type == "AOE":
			for i in source.exceptions:
				new_projectile.add_collision_exception_with(i)
		for i in extra_exceptions:
			new_projectile.add_collision_exception_with(i)
		# Flying
		new_projectile.position = source.position
		new_projectile.direction = new_projectile.global_position.direction_to(target)
		new_projectile.hit_action.connect("action_complete",Callable(new_projectile,"destroy"))
		new_projectile.flying_action = new_projectile.actions.add_ability(new_projectile, main[5], "ability_name", main[6])	# Cooldown will make sure it's not constant
		new_projectile.connect("create_projectile",Callable(self,"create_projectile"))
		new_projectile.initialize()
	elif type == "AOE":
		var new_aoe = projectile_types[1].instantiate()
		add_child(new_aoe)
		new_aoe.size_scale = main[1]
		new_aoe.position = source.position
		new_aoe.aoe_action = new_aoe.actions.add_ability(new_aoe, main[2])
		new_aoe.aoe_action.connect("action_complete",Callable(new_aoe,"destroy"))
		# Exception chain
		new_aoe.exceptions.append(source)
		if source.type == "Projectile":
			for i in source.get_collision_exceptions():
				new_aoe.exceptions.append(i)
		if source.type == "AOE":
			for i in source.exceptions:
				new_aoe.axceptions.append(i)
		for i in extra_exceptions:
			new_aoe.exceptions.append(i)
		new_aoe.connect("create_projectile",Callable(self,"create_projectile"))
		new_aoe.initialize()

# Typical block passed to here
#				[SHOOT_BASIC, 1, 2, 1, -1, # Then shoot a basic projectile with asize of 100%, speed of 2 tiles/s, with horizontal and vertical acceleration of 1 and -1
#					[[AOE, 1, [[CASTER, ADD_STAT, HEALTH, -1, 0]], 0]], 1, # while producing AOE that hurts every 1 second in area of 1 tile
#					[[CASTER, ADD_STAT, HEALTH, -1, 0], # and then damages the target for 1 on hit
#						[CASTER, ADD_STAT, HEALTH, -1, 0]], # and then again damages the target for 1 on hit
#					0],	# 0 cooldown
