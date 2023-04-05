extends Battler

class_name Enemy
signal died(battler)
@export var vision_range = 5	# Radius, in tiles, excluding the center (enemy itself)
@export var follow_range = 15	# How far to follow 
@export var keep_distance = 1
@export var faction = "None"
# Character traits, their effect is exponential
@export var aggressiveness = 1
@export var cowardice = 1

@onready var wall_tester = $WallTester

var squad = []	# TODO: Squad mechanics, probably a separate scene for different squads like with stats
var in_vision = []	# Enemies in vision_range
var in_range = []	# Enemies in range, maybe not visible yet
var attacking = null
var walk_timer = 0.0
var agro_timer = 0.0

var going_home = false
var home : Vector2

func _ready():
	type = "Enemy"
	$Vision/VisionShape.scale = Vector2(vision_range*2+1, vision_range*2+1)
	$NavigationAgent2D.max_speed = stats.speed * World.GRID_SIZE

func update_stats():
	emit_signal("health_changed", stats.health, stats.max_health)
	if stats.health <= 0:
		emit_signal("died", self)
		queue_free()

func _physics_process(delta):
	# Test if hidden by a wall, testing all corners of the target
	for i in in_range:
		if i in in_vision:	# TODO: mechanic for walking around obstacles, A*?
			continue
		if test_visiblity(i):
			print("found you")
			in_vision.append(i)
			
	check_for_targets()
	if going_home:
		var next_path_position = $NavigationAgent2D.get_next_path_position()
		var new_velocity = global_position.direction_to(next_path_position) * stats.speed * World.GRID_SIZE
		set_velocity(new_velocity)
		move_and_slide()
		if $NavigationAgent2D.is_navigation_finished():
			going_home = false
	elif not attacking:
		if walk_timer <= 0:
			if randi() % 100 == 0:
				walk_timer = randfn(1, 1)	# A chance to walk in a random direction
				var direction = get_random_direction()
				look_at(direction)
		else:	# Random walk cycle
			walk_timer -= delta
			var new_velocity : Vector2 = transform.x * stats.speed	# Set the velocity using the chosen direction
			new_velocity = new_velocity.normalized() * stats.speed / 5 * World.GRID_SIZE * delta	# Set the velocity to speed/5
			set_velocity(new_velocity)
			var collided_with = move_and_collide(new_velocity)
			if collided_with:	# Turn around if you walked into something
				var collider = collided_with.get_collider()
				look_at(global_position + collider.global_position * -1)

	else:
		look_at(attacking.global_position)
		engage_enemy(delta)
	update_location()
	
func engage_enemy(delta):
	var new_velocity = transform.x
	var distance = get_distance(attacking)
	var can_aim = test_aim()
	if distance < keep_distance * World.GRID_SIZE and can_aim:
		# Back off slowly
		new_velocity = new_velocity.normalized() * stats.speed * -1 * World.GRID_SIZE / 10
		set_velocity(new_velocity)
		move_and_slide()
	elif distance > (keep_distance + 1) * World.GRID_SIZE or not can_aim:	# The target is too far or not visible
		agro_timer -= delta
		if distance > (keep_distance + 1) * aggressiveness * World.GRID_SIZE:	# Absolute limit
			agro_timer = 0
		# Approach quickly
		$NavigationAgent2D.set_target_position(attacking.global_position)
		if not $NavigationAgent2D.is_target_reachable():
			print("not reachable")
			go_home()
			return
		var next_path_position = $NavigationAgent2D.get_next_path_position()
		new_velocity = global_position.direction_to(next_path_position) * stats.speed * World.GRID_SIZE
		set_velocity(new_velocity)
		move_and_slide()
		return
	
	reset_agro_timer()	# The target is in range and visible, time to be aggressive

	
func go_home():	# Navigate back to spawn
	attacking = null
	print("home")
	print(home)
	$NavigationAgent2D.set_target_position(home)
	going_home = true
	
func get_random_direction() -> Vector2:
	var direction = global_position + Vector2.UP.rotated(randi() % 360 / 2 / PI)
	return direction

func check_for_targets():
	if attacking:
		if get_distance(attacking) > (follow_range + vision_range + 1) * World.GRID_SIZE:
			if agro_timer <= 0:	# If the target is out of range, and the enemy got tired of the chase, go home; else continue
				go_home()
		return
	if in_vision.is_empty():	# No visible targets
		attacking = null
		return
	# Find a new target to attack
	var distances = in_vision.map(get_distance)
	var closest_idx = distances.find(distances.min())
	attacking = in_vision[closest_idx]
	going_home = false
	
func reset_agro_timer():
	agro_timer = clamp(randfn(aggressiveness**2, aggressiveness), 0, 300)	# More aggressive enemies will stay agro'd for longer
	
func get_distance(target):
	var A = target.global_position
	var B = wall_tester.global_position
	var distance = B - A
	return distance.length()

func _on_vision_body_entered(body):
	if body == self:
		return
	if body.type == "Enemy":
		if body.faction == faction and faction != "None":
			# No attacking if it's the same faction, but might form a squad
			return
	if body.type == "Block":
		return
	in_range.append(body)

func test_visiblity(body):
	var hidden = 0
	var target_box = body.hitbox.get_shape().get_rect()
	var A = body.global_position + target_box.position
	var B = wall_tester.global_position
	var distance = A - B
	var collision = wall_tester.move_and_collide(distance, true)
	if collision:
		var collider = collision.get_collider()
		if collider.battler_name == "Wall":
			hidden += 1
	A.x += target_box.size.x
	distance = A - B
	collision = wall_tester.move_and_collide(distance, true)
	if collision:
		var collider = collision.get_collider()
		if collider.battler_name == "Wall":
			hidden += 1
	A.y += target_box.size.y
	distance = A - B
	collision = wall_tester.move_and_collide(distance, true)
	if collision:
		var collider = collision.get_collider()
		if collider.battler_name == "Wall":
			hidden += 1
	A.x -= target_box.size.x
	distance = A - B
	collision = wall_tester.move_and_collide(distance, true)
	if collision:
		var collider = collision.get_collider()
		if collider.battler_name == "Wall":
			hidden += 1
	if hidden >= 4:	# None of the corners are visible
		return false
	return true
	
func test_aim():
	var A = attacking.global_position
	var B = wall_tester.global_position
	var distance = A - B
	var collision = wall_tester.move_and_collide(distance, true)
	if collision:
		return false
	return true

func _on_vision_body_exited(body):
	var body_index = in_vision.find(body)
	if body_index != -1:
		in_vision.remove_at(body_index)
	in_range.remove_at(in_range.find(body))
	
