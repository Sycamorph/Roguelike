extends Area2D

@onready var hitbox = $HitboxShape
@onready var sprite = $Sprite2D
@onready var timer = $Timer
@onready var actions = $Actions 
@onready var wall_tester = $WallTester

var aoe_action : Action
var size_scale = 1
var exceptions = []
var available_actions = []
var selected_action : Action
var acting = false
var type = "AOE" # For compatibility

signal create_projectile(source, target, blocks)

func initialize():
	sprite.scale *= size_scale
	hitbox.scale *= size_scale
	AoE_attack()
	timer.connect("timeout",Callable(self,"fizzle_out"))
	timer.start(1)	#AoE stays for 0.5 seconds

func fizzle_out():
	visible = false
	if is_instance_valid(self):
		if !acting:
			destroy(false)

func AoE_attack():
	await get_tree().create_timer(0.1).timeout
	var targets = get_overlapping_bodies()
	if targets.is_empty():
		return
	for target in targets:
		if target in exceptions:
			continue
		if target.type == "Block":
			continue
		# Test if protected by a wall, testing all corners of the target
		var protected = 0
		var target_box = target.hitbox.get_shape().get_rect()
		var A = target_box.position + target.global_position + target.hitbox.position
		var B = wall_tester.global_position
		var distance = A - B
		var collision = wall_tester.move_and_collide(distance, true)
		if collision:
			var collider = collision.get_collider()
			if collider.battler_name == "Wall":
				protected += 1
		A.x += target_box.size.x
		distance = A - B
		collision = wall_tester.move_and_collide(distance, true)
		if collision:
			var collider = collision.get_collider()
			if collider.battler_name == "Wall":
				protected += 1
		A.y += target_box.size.y
		distance = A - B
		collision = wall_tester.move_and_collide(distance, true)
		if collision:
			var collider = collision.get_collider()
			if collider.battler_name == "Wall":
				protected += 1
		A.x -= target_box.size.x
		distance = A - B
		collision = wall_tester.move_and_collide(distance, true)
		if collision:
			var collider = collision.get_collider()
			if collider.battler_name == "Wall":
				protected += 1
		if protected >= 4:	# None of the corners are accessible
			continue
		acting = true
		aoe_action.act(target, null, 64, exceptions)
		
func destroy(_action_success=false):
	return
	print("fizzled")
	aoe_action.queue_free()
	queue_free()

func shoot(source, target, blocks, type):
	emit_signal("create_projectile", source, target, blocks, type)
