extends Node2D

class_name World

signal initialized()

@onready var floor_grid = $Floor
@onready var blocks = $Blocks
@onready var enemies = $Enemies
@onready var projectiles = $Projectiles

@onready var stats = $Stats
@onready var actions = $Actions

var player
var player_spawn = Vector2(0, 0)

var all_rooms = [preload("res://src/Rooms/FullJunction0.tscn"),
				preload("res://src/Rooms/FullJunction1.tscn"),
				preload("res://src/Rooms/UDJunction0.tscn")]
				
var blocktypes = [preload("res://src/Rooms/Blocks/Block.tscn"),
					preload("res://src/Rooms/Blocks/Floor.tscn"),
					preload("res://src/Rooms/Blocks/Wall.tscn"),
					preload("res://src/Rooms/Blocks/Door.tscn")]

var map = []
var tile_positions = []
var floor_positions = []
var tiles = []
var floors = []

var rooms = []
var room_rects = []
var connected_rooms = []
var world_rect 
var world_margin = 5	# Tiles of walls on the edge of the world
var num_rooms = 5
var min_room_size = Vector2(9, 9)	# Smallest generic room scene possible
const GRID_SIZE = 32
enum {FLOOR, WALL, DOOR_C}
const VOID = -1

var enemytypes = [preload("res://src/Actors/Enemy.tscn")]
var num_enemies = 1

func _ready():
	randomize()

func initialize():
	await generate_world()
	spawn_player()
	for i in range(num_enemies):
		spawn_enemy(enemytypes)
	emit_signal("initialized", player)

func spawn_enemy(pool, enemy=-1, room=-1):
	var enemy_id = enemy if enemy != -1 else randi() % pool.size()
	var new_enemy = pool[enemy_id].instantiate()
	var spawn_room = room if room != -1 else rooms[randi() % rooms.size()]
	var enemy_spawn = convert_room_to_rect(spawn_room)
	enemy_spawn = enemy_spawn.grow(-GRID_SIZE)	# Don't spawn in walls

	var x = (randi() % int(enemy_spawn.size.x / GRID_SIZE)) * GRID_SIZE + enemy_spawn.position.x
	var y = (randi() % int(enemy_spawn.size.y / GRID_SIZE)) * GRID_SIZE + enemy_spawn.position.y
	enemies.add_child(new_enemy)
	new_enemy.position = Vector2(x, y)
	new_enemy.home = Vector2(x, y)
	new_enemy.initialize()
	new_enemy.connect("create_projectile",Callable(projectiles,"create_projectile"))

func spawn_player():
	var spawned_player = preload("res://src/Actors/Player.tscn").instantiate()
	player_spawn = room_rects[randi() % room_rects.size()].get_center() - Vector2(GRID_SIZE, GRID_SIZE) / 2
	spawned_player.position = player_spawn
	add_child(spawned_player)
	player = spawned_player
	player.initialize()
	player.connect("create_projectile",Callable(projectiles,"create_projectile"))
	
func convert_room_to_rect(room):
	var global_rect_position = room.to_global(room.map_to_local(room.get_used_rect().position))
	#global_rect_position -= Vector2(1, 1) * GRID_SIZE
	var global_rect_size = room.get_used_rect().size * GRID_SIZE
	return Rect2(global_rect_position, global_rect_size)
	
func grid_to_pos(grid_pos):
	return grid_pos * GRID_SIZE

func generate_world():
	rooms.clear()
	map.clear()
	var occupied_regions = Rect2(0, 0, 0, 0)
	for i in range(num_rooms):
		await add_room(occupied_regions)

	# Adding random connections
	for room1 in rooms:
		for room2 in rooms:
			if room1 == room2:
				continue
			if [room1, room2] in connected_rooms or [room2, room1] in connected_rooms:
				continue
			if randi() % 2 == 1:
				create_door(room1, room2)
				await apply_to_main(room1)
	rebuild_map()	# Building the block map


func check_adjacent(x, y):
	var possibilities = [1, 0, 1, 1, -1, 0, -1, -1]
	var adjacent = []
	for i in range(8):
		var near = Vector2(x, y)
		near += Vector2(possibilities[i], possibilities[(i + 1) % 8])
		adjacent.append(floor_grid.get_cellv(near))
	return adjacent
			

func add_room(occupied_regions):
	var new_room = all_rooms[randi() % all_rooms.size()].instantiate()
	var size = new_room.get_used_rect().size
	var start = Vector2i(0,0) # Placing the first room
	var attached_room
	if !rooms.is_empty():
		var rooms_to_test = rooms
		while !attached_room:
			var test_room = rooms_to_test[randi() % rooms.size()]
			start = attach_position(new_room, test_room)
			if start:
				attached_room = test_room
				start += Vector2i(-1, -1) * GRID_SIZE	# Attach_position returns floor position
			else:
				rooms_to_test.remove_at(rooms_to_test.find(test_room))
			if rooms_to_test.is_empty():
				return
	new_room.position = start
	floor_grid.add_child(new_room)
	rooms.append(new_room)
	room_rects.append(convert_room_to_rect(new_room))
	new_room.visible = false	# Hiding the room blueprint
	if !attached_room:
		apply_to_main(new_room)
		return
	create_door(new_room, attached_room)
	await apply_to_main(new_room)
	
func create_door(room1, room2):
	var rect1 = convert_room_to_rect(room1)
	var rect2 = convert_room_to_rect(room2)
	var shared_wall = rect1.intersection(rect2)
	var available_tiles = []
#	print(rect1)
#	print(rect2)
#	print(shared_wall)
	if shared_wall.size.x < 3 * GRID_SIZE and shared_wall.size.y < 3 * GRID_SIZE:
		return false	# Failed to create a door
	if shared_wall.size.x > GRID_SIZE:	# The wall is either on the x or y axis
		for x in range(shared_wall.size.x / GRID_SIZE):
			available_tiles.append(WALL)
		var random_tile = (randi() % (available_tiles.size() - 2)) + 1	# Index from 1 to end-1
		var y = (shared_wall.position.y)
		var x = (shared_wall.position.x) + random_tile * GRID_SIZE
		add_tile(x, y, DOOR_C)
		if available_tiles.size() > 3:	# Double door chance
			if randi() % 2 == 1:
				if random_tile == 1:
					random_tile += 1
				elif random_tile == available_tiles.size() - 1:
					random_tile -= 1
				y = (shared_wall.position.y)
				x = (shared_wall.position.x) + random_tile * GRID_SIZE
				add_tile(x, y, DOOR_C)
			
	elif shared_wall.size.y > GRID_SIZE:
		for y in range(shared_wall.size.y / GRID_SIZE):
			available_tiles.append(WALL)
		var random_tile = (randi() % (available_tiles.size() - 2)) + 1
		var y = (shared_wall.position.y) + random_tile * GRID_SIZE
		var x = (shared_wall.position.x)
		add_tile(x, y, DOOR_C)
		if available_tiles.size() > 3:	# Double door chance
			if randi() % 2 == 1:
				if random_tile == 1:
					random_tile += 1
				elif random_tile == available_tiles.size() - 1:
					random_tile -= 1
				y = (shared_wall.position.y) + random_tile * GRID_SIZE
				x = (shared_wall.position.x)
				add_tile(x, y, DOOR_C)
			
			
	connected_rooms.append([room1, room2])

func attach_position(new_room, base_room):
	var test_rect = new_room.get_used_rect()
	var floor_rect = test_rect.grow(-1)
	floor_rect.position *= GRID_SIZE
	floor_rect.size *= GRID_SIZE
	var base_rect = base_room.get_used_rect()
	var available_positions = []
	for x in range(base_rect.position.x + 2 - floor_rect.size.x / GRID_SIZE, base_rect.end.x - 1):	#Don't place rooms in corners
		var y = base_rect.position.y - floor_rect.size.y / GRID_SIZE 
		floor_rect.position = Vector2i(base_room.to_global(base_room.map_to_local(Vector2i(x,y))))
		#floor_rect.position -= Vector2i(1, 1) * GRID_SIZE
		var intersects = false
		for room in room_rects:
			if floor_rect.intersects(room):
				intersects = true
				break
		if !intersects:
			available_positions.append(floor_rect.position)
		y = base_rect.end.y
		floor_rect.position = Vector2i(base_room.to_global(base_room.map_to_local(Vector2i(x,y))))
		#floor_rect.position -= Vector2i(1, 1) * GRID_SIZE
		intersects = false
		for room in room_rects:
			if floor_rect.intersects(room):
				intersects = true
				break
		if !intersects:
			available_positions.append(floor_rect.position)

	for y in range(base_rect.position.y + 2 - floor_rect.size.y / GRID_SIZE, base_rect.end.y - 1):	#Don't place rooms in corners
		var x = base_rect.position.x - floor_rect.size.x / GRID_SIZE
		floor_rect.position = Vector2i(base_room.to_global(base_room.map_to_local(Vector2i(x,y))))
		#floor_rect.position -= Vector2i(1, 1) * GRID_SIZE
		var intersects = false
		for room in room_rects:
			if floor_rect.intersects(room):
				intersects = true
				break
		if !intersects:
			available_positions.append(floor_rect.position)
		x = base_rect.end.x
		floor_rect.position = Vector2i(base_room.to_global(base_room.map_to_local(Vector2i(x,y))))
		#floor_rect.position -= Vector2i(1, 1) * GRID_SIZE
		intersects = false
		for room in room_rects:
			if floor_rect.intersects(room):
				intersects = true
				break
		if !intersects:
			available_positions.append(floor_rect.position)
	
	if available_positions.size() == 0:
		return false
	elif available_positions.size() == 1:
		return available_positions[0]
	else:
		return available_positions[randi() % available_positions.size()]

	
func set_tile(x, y, tile, grid=floor_grid, override=false):
	if(grid.get_cell_source_id(0, Vector2i(x, y))) != -1 and !override:
		return
	grid.set_cell(0, Vector2i(x, y), tile, Vector2i(0, 0))
	
func apply_to_main(grid):
	var grid_rect = convert_room_to_rect(grid)
	var cell_list = grid.get_used_cells(0)
	for cell in cell_list:
		var w_x = grid_rect.position.x / GRID_SIZE + cell.x
		var w_y = grid_rect.position.y / GRID_SIZE + cell.y 
		var tile = grid.get_cell_source_id(0, cell)
		set_tile(w_x, w_y, tile)
	world_rect = convert_room_to_rect(floor_grid)

func rebuild_map():
	map.clear()
	var grid_rect = convert_room_to_rect(floor_grid)
	var cell_list = floor_grid.get_used_cells(0)
	for cell in cell_list:
		var w_x = cell.x * GRID_SIZE
		var w_y = cell.y * GRID_SIZE
		var tile = floor_grid.get_cell_source_id(0, cell)
		add_tile(w_x, w_y, tile)
		if tile != FLOOR and tile != WALL:	# Adding a floor under every tile
			add_tile(w_x, w_y, FLOOR)
	
func add_tile(x, y, tile):	
	set_tile(x / GRID_SIZE, y / GRID_SIZE, tile, floor_grid, true)
	var new_block = blocktypes[tile + 1].instantiate()
	var new_pos = Vector2i(x, y)
	new_block.position = new_pos
	blocks.add_child(new_block)
	if tile == FLOOR:
		if new_pos not in floor_positions:
			floor_positions.append(new_pos)
			floors.append(new_block)
		else:
			var id = floor_positions.find(new_pos)
			var old_block = floors[id]
			old_block.destroy()
			floor_positions.remove_at(id)
			floors.remove_at(id)
			floor_positions.insert(id, new_pos)
			floors.insert(id, new_block)
	elif tile == WALL:	# Walls replace floors and tiles
		if new_pos in floor_positions:
			var id = floor_positions.find(new_pos)
			var old_block = floors[id]
			print(old_block)
			old_block.destroy()
			floor_positions.remove_at(id)
			floors.remove_at(id)
		if new_pos not in tile_positions:
			tile_positions.append(new_pos)
			tiles.append(new_block)
		else:
			var id = tile_positions.find(new_pos)
			var old_block = tiles[id]
			old_block.destroy()
			tile_positions.remove_at(id)
			tiles.remove_at(id)
			tile_positions.insert(id, new_pos)
			tiles.insert(id, new_block)
	else:	#Everything else replaces everything else and walls
		if new_pos not in tile_positions:
			tile_positions.append(new_pos)
			tiles.append(new_block)
		else:
			var id = tile_positions.find(new_pos)
			var old_block = tiles[id]
			old_block.destroy()
			tile_positions.remove_at(id)
			tiles.remove_at(id)
			tile_positions.insert(id, new_pos)
			tiles.insert(id, new_block)
	await new_block.initialize()
	
func place_to_zero(): 	# Doesn't work yet, remove or fix
	var floor_rect = convert_room_to_rect(floor_grid)
	print(floor_rect)
	var start = floor_rect.position
	var end = floor_rect.end
	room_rects.clear()
	floor_grid.clear()
	for room in rooms:
		room.position.x -= start.x - GRID_SIZE * world_margin	# Leaving a wall margin of 5 tiles
		room.position.y -= start.y - GRID_SIZE * world_margin
		apply_to_main(room)
		room_rects.append(convert_room_to_rect(room))
