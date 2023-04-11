extends Battler

class_name Projectile

var direction : Vector2
var acceleration : Vector2
var acting = false
var size_scale = 1
var flying_action : Action
var hit_action : Action
var height = 1

@onready var timer = $Timer

func initialize():
	type = "Projectile"
	sprite.scale *= size_scale
	hitbox.scale *= size_scale
	velocity = calculate_move_velocity(velocity, direction, stats.speed)
	timer.connect("timeout",Callable(self,"fizzle_out"))
	timer.start(60)	#Each projectile lives 60 seconds max, unless acting

func fizzle_out():
	if is_instance_valid(self):
		if !acting:
			destroy(false)

func _physics_process(delta: float) -> void:
	if acting:
		return
	flying_action.act(self, null, 64, get_collision_exceptions())
	velocity += direction * acceleration.x * delta
	height += acceleration.y * delta
	if height <= 0:
		set_collision_mask_value(7, true)	# Now the projectile can hit the floor
	var collided_with = move_and_collide(velocity * delta)
	if collided_with:
		print("hit")
		print(collided_with.get_collider())
		acting = true
		hitbox.disabled = true
		sprite.visible = false
		hit_action.act(collided_with.get_collider(), null, 64, get_collision_exceptions())
		return
	if height <= 0:
		fizzle_out()

func destroy(_action_success=false):
	hit_action.queue_free()
	flying_action.queue_free()
	queue_free()
