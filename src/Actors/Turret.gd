extends Enemy

class_name Turret

@export var damage = 0
@export var bullet_speed = 15
@export var bullet_size = 1
@export var fire_delay = 0.1
@export var leading = 2

func add_starting_abilities():
	add_shoot_ability(bullet_size, bullet_speed, 0, -1, [], 1, add_hurt_ability(damage), fire_delay)

func shoot_ability(delta, target):	# Fire a random shoot ability and get its cooldown
	var chosen_ability : Action = shoot_abilities.pick_random()
	shoot_timer = chosen_ability.cooldown

	if leading == 0:
		chosen_ability.act(self, target.global_position)
	elif leading == 1:	# Slight leading
		chosen_ability.act(self, target.global_position + target.velocity * delta)
	elif leading > 1:	# Advanced leading, calculates your position if you don't change directions
		var direction = target.global_position - global_position
		var distance = direction.length()
		# Finding the intersection of a circle and a line
		var a = target.velocity.length_squared() - (bullet_speed * World.GRID_SIZE) ** 2
		var b = 2 * direction.dot(target.velocity)
		var c = direction.length_squared()
		var discriminant = b * b - 4 * a * c
		var time = 0
		if discriminant > 0:
			var t1 = (-b - sqrt(discriminant)) / (2 * a)
			var t2 = (-b + sqrt(discriminant)) / (2 * a)
			if t1 > 0 and t2 > 0:
				time = min(t1, t2)
			else:
				time = max(t1, t2, 0)	# Need a non-zero time
		elif discriminant == 0:
			time = -b / (2 * a)
		var predicted_position = target.global_position + target.velocity * time
		chosen_ability.act(self, predicted_position)
	
