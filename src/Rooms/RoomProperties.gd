extends TileMap


var properties = []
var floor_health = 10000
var wall_health = 100
var door_health = 50

#Obscure and meta
var world_mana = 0
var speed = 0
var level = 0 
var exp_worth = 0
var abilities = []

enum {FLOOR, WALL, DOOR_C, DOOR_O}


func initialize_properties(map):
	properties.clear()
	for row in map:
		properties.append([])
		for y in row:
			var stat_block = []	#Health, max_health, mana, max_mana, speed, level, exp_worth, abilities
			if map[row][y] == FLOOR:
				stat_block.append(floor_health)
				stat_block.append(floor_health)
			elif map[row][y] == WALL:
				stat_block.append(wall_health)
				stat_block.append(wall_health)
			elif map[row][y] == DOOR_C or map[row][y] == DOOR_O:
				stat_block.append(door_health)
				stat_block.append(door_health)
			stat_block.append(world_mana)
			stat_block.append(world_mana)
			stat_block.append(speed)
			stat_block.append(map[row][y])	# Level
			stat_block.append(exp_worth)
			stat_block.append(abilities)
			properties[row].append(stat_block)

func change_properties(map, x, y, property, value):
	return
			
	
