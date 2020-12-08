extends Control

func _ready():
	Global.read_inputs()
	for button in get_tree().get_nodes_in_group("remapButtons"):
		button._custom_ready()
		

func save_inputs():
	var inputStorage = {}
	
	for action in InputMap.get_actions():
		for event in InputMap.get_action_list(action):
			if !inputStorage.has(action):
				inputStorage[action] = []
			if event is InputEventKey:
				inputStorage[action].append(Global.inputType.KEY)
				inputStorage[action].append(event.get_scancode_with_modifiers())
			elif event is InputEventJoypadButton:
				inputStorage[action].append(Global.inputType.JOYPAD_BUTTON)
				inputStorage[action].append(event.button_index)
			elif event is InputEventJoypadMotion:
				inputStorage[action].append(Global.inputType.JOYPAD_MOTION)
				if event.axis_value < 0:
					inputStorage[action].append(-(event.axis + 1000))
				else:
					inputStorage[action].append(event.axis)
	
	var file = File.new()
	var json = to_json(inputStorage)
	file.open(Global.controlsFilePath, File.WRITE)
	file.store_string(json)
	file.close()


func _on_SaveButton_pressed():
	save_inputs()
	Sound.get_node("buttonClick").play()
	get_tree().change_scene("res://scenes/settings.tscn")

func _on_CancelButton_pressed():
	Sound.get_node("buttonClick").play()
	get_tree().change_scene("res://scenes/settings.tscn")


func _on_ResetButton_pressed():
	InputMap.load_from_globals()
	save_inputs()
	get_tree().reload_current_scene()
