extends Node2D

class_name ActionBlock

const VALUE_TYPES = ["VALUE", "DELAY", "SIZE", "SPEED", "ACCELERATION", "FALLOFF", "REPEAT"]
const HIDDEN_VALUES = ["SIZE", "SPEED", "ACCELERATION", "FALLOFF"]	# No need to think about them, unless special
#const POSITIVE_VALUES = ["REPEAT"]
#const PERCENTAGE_VALUES = ["SIZE", "SPEED"]
const OPTIONAL = ["ABILITY"]
var editable_values = ["VALUE", "REPEAT"]

#var defaults = {"VALUE":1, "DELAY":1, "SIZE":1, "SPEED":1, "ACCELERATION":0, "FALLOFF":-1, "REPEAT":1, "CHAIN":1}
enum type_legend {BLOCK, INTEGER, POSITIVE, FLOAT, FLOAT_POSITIVE, PERCENTAGE}
var defaults = []
var type_map = []
var descriptions = {"VALUE":"By ", "DELAY":"With a cooldown of "}

var type = "BLOCK"
var contents = "CASTER"	# A block number or a value
# Enums and the dictionary are stored in the Action class

var mana_worth = 0
var rarity = 0
var rarity_effects = []
var possible_effects = []
var amount = 0	# How many in the current stack
var order = []

func reset():
	initialize_properties(contents)

func initialize_properties(_contents):
	contents = _contents
	if contents is Action:
		type = "ABILITY"
		return
	elif not contents is String:	#If it's a number
		type = "VALUE"
		return
	elif contents == "CASTER":
		order = ["BLOCK", "COMMAND", "SPECIFICATION", "VALUE", "DELAY"]
		type_map = [type_legend.BLOCK, type_legend.BLOCK, type_legend.BLOCK, type_legend.INTEGER, type_legend.FLOAT_POSITIVE]
		defaults = ["BLOCK", "COMMAND", "SPECIFICATION", 1, 15]
		descriptions["BLOCK"] = "This action will be applied to whoever touched this spell last. "
		descriptions["COMMAND"] = "Action to be applied: "
		descriptions["SPECIFICATION"] = "Which stat to edit: "	# Might be other possibilities
		type = "BLOCK"
		mana_worth = 1
		# Lasting effets aren't added yet
		possible_effects = [["LASTING", null], [null, "CHAOTIC"]]
	elif contents == "SHOOT_BASIC":
		order = ["BLOCK", "SIZE", "SPEED", "ACCELERATION", "FALLOFF", "ABILITY", "DELAY", "ABILITY", "DELAY"]
		type_map = [type_legend.BLOCK, type_legend.PERCENTAGE, type_legend.PERCENTAGE, type_legend.FLOAT, type_legend.FLOAT, type_legend.BLOCK, type_legend.FLOAT_POSITIVE, type_legend.BLOCK, type_legend.FLOAT_POSITIVE]
		defaults = ["BLOCK", 1, 1, 0, -1, "ABILITY", 0.1, "ABILITY", 1]
		descriptions["BLOCK"] = "Fire a projectile, causing whoever was hit to cast a spell."
		descriptions["SIZE"] = "Projectile size: "
		descriptions["SPEED"] = "Projectile speed: "
		descriptions["ACCELERATION"] = "Projectile acceleration: "
		descriptions["FALLOFF"] = "Projectile falloff: "
		descriptions["ABILITY"] = ["Cast while flying: ", "The target will cast: "]
		type = "BLOCK"
		mana_worth = 1
		# Multiple and angled projectiles possibility isn't added yet
		possible_effects = [["CHEAP", "EXPENSIVE"], ["BIG", "SMALL"], ["FAST", "SLOW"], ["ACCELERATING", "DECELERATING"], [null, "ANGLED"], [null, "INVISIBLE"], [null, "MULTIPLE"], [null, "ENVIRONMENT EFFECT"]]
	elif contents == "AOE":
		# AOE of value1 size with ability effect, value2 delay
		order = ["BLOCK", "SIZE", "ABILITY", "DELAY"]
		type_map = [type_legend.BLOCK, type_legend.PERCENTAGE, type_legend.BLOCK, type_legend.FLOAT_POSITIVE]
		defaults = ["BLOCK", 1, "ABILITY", 1]
		descriptions["BLOCK"] = "Cause everyone in range to cast a spell"
		descriptions["SIZE"] = "Range: "
		descriptions["ABILITY"] = ["The targets will cast: "]
		type = "BLOCK"
		mana_worth = 5
		possible_effects = [["CHEAP", "EXPENSIVE"], ["BIG", "SMALL"], [null, "ENVIRONMENT EFFECT"]]
	elif contents == "REPEAT":
		#Repeat the ability value1 times
		order = ["BLOCK", "ABILITY", "REPEAT"]
		type_map = [type_legend.BLOCK, type_legend.BLOCK, type_legend.POSITIVE]
		defaults = ["BLOCK", "ABILITY", 1]
		descriptions["BLOCK"] = "Repeat the same ability."
		descriptions["ABILITY"] = "Ability to repeat: "
		descriptions["REPEAT"] = "Amount of times: "
		type = "BLOCK" 
		mana_worth = 0
	elif contents == "CHAIN":
		#Chain a value amount of abilities
		order = ["BLOCK", "ABILITY"]
		type_map = [type_legend.BLOCK, type_legend.BLOCK]
		defaults = ["BLOCK", "ABILITY"]
		descriptions["BLOCK"] = "Chain multiple abilities together."
		descriptions["ABILITY"] = "Add an ability to the chain: "
		type = "BLOCK"
		mana_worth = 0
	# Command block
	elif contents == "ADD_STAT":
		type = "COMMAND"
		mana_worth = 1
	# Specification block
	elif contents == "HEALTH":
		type = "SPECIFICATION"
		mana_worth = 1
	elif contents == "MANA":
		type = "SPECIFICATION"
		mana_worth = 0

func get_random_effects():
	if rarity == 0:
		return
	var effects = 2 * (randi() % (rarity * 5)) + rarity	
	var first_positive = randi() % possible_effects.size()
	rarity_effects.append(possible_effects[first_positive][0])	# Getting the first positive effect
	effects -= 1
	var possible_negatives = possible_effects.duplicate(true)
	possible_negatives.remove_at(first_positive)	# Can't have contradictory effects
	var possible_positives = possible_effects.duplicate(true)
	for i in range(effects):
		if i % 2 == 0 or effects - i < rarity:
			var new_positive = possible_positives[randi() % possible_positives.size()]
			var removed_negative = possible_negatives.find(new_positive)
			if removed_negative != -1:
				possible_negatives.remove_at(removed_negative)
			rarity_effects.append(new_positive[0])
		else:
			var new_negative = possible_negatives[randi() % possible_negatives.size()]
			var removed_positive = possible_positives.find(new_negative)
			if removed_positive != -1:
				possible_positives.remove_at(removed_positive)
			rarity_effects.append(new_negative[1])

