extends CanvasLayer

@onready var label = $Label
@onready var exp_bar = $ExperienceBar
@onready var lifebars_builder = $LifebarsBuilder
@onready var pause_menu = $Pause
@onready var spell_crafting = $Spellcrafting

var current_menu = null

var player : Battler


func initialize(_character):
	player = _character
	label.update_text(_character)
	exp_bar.initialize(_character.experience, _character.experience_required)


func update_text(_character):
	label.update_text(_character)


func _on_Character_experience_gained(growth_data) -> void:
	exp_bar.experience_gained(growth_data)


func _on_Character_update_label(level, experience, experience_required):
	label.update_text(level, experience, experience_required)

func change_menu(menu):
	if menu == "pause":
		pause_menu.hide()	# Unhides in this case
		pause_menu.visible = true
	elif menu == "spellcraft":
		spell_crafting.initialize(player)
