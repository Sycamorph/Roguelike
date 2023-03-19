extends Label


func update_text(_character):
	text = """Level: %s
			Experience: %s
			Next level: %s
			Selected ability: %s""" % [_character.level, 
			_character.experience, 
			_character.experience_required,
			_character.selected_action.ability_name
			]
