extends Battler

class_name Enemy
signal died(battler)
@export var vision = 5	# Radius, in tiles, excluding the center (enemy itself)
@export var faction = "None"

@onready var wall_tester = $WallTester

var squad = []	# TODO: Squad mechanics, probably a separate scene for different squads like with stats
var in_vision = []	# Enemies in vision
var in_range = []	# Enemies in range, maybe not visible yet
var attacking = null
var walk_timer = 0

func _ready():
	type = "Enemy"
	$Vision/VisionShape.scale = Vector2(vision*2+1, vision*2+1)

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
	if not attacking:
		if walk_timer <= 0:
			if randi() % 2 == 0:
				walk_timer = randi() % 10	# A chance to walk in a random direction
				var direction = get_random_direction()
				look_at(direction)
			else:
				return
		else:
			walk_timer -= delta
	else:
		look_at(attacking.global_position)
	var new_velocity = transform.x * stats.speed	# Set the velocity using the chosen direction
	new_velocity = new_velocity.normalized() * stats.speed	# Set the velocity to speed
	set_velocity(new_velocity)
	var collided_with = move_and_collide(new_velocity)
	if collided_with:	# No walking into walls
		walk_timer = 0
	update_location()
	return
	
func get_random_direction() -> Vector2:
	var direction = global_position + Vector2.UP.rotated(randi() % 360 / 2 / PI)
	return direction

func check_for_targets():
	if in_vision.is_empty():	# No visible targets
		attacking = null
		return
	if attacking in in_vision:	# Already have a target that's still visible
		return
	var distances = in_vision.map(get_distance)
	var closest_idx = distances.find(distances.min())
	attacking = in_vision[closest_idx]
	
func get_distance(target):
	var A = target.global_position
	var B = wall_tester.global_position
	var distance = B - A
	return distance.length_squared()	# Faster than length

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
	var A = body.global_position
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
	
func _on_vision_body_exited(body):
	var body_index = in_vision.find(body)
	if body_index != -1:
		in_vision.remove_at(body_index)
	in_range.remove_at(in_range.find(body))
	
