extends Button

export(String) var action = "ui_up"

func _custom_ready():
	# because _ready is called before parent's one
	# so _custom_ready is called from scene node
	
	assert(InputMap.has_action(action))
	set_process_unhandled_key_input(false)
	display_current_key()


func _toggled(button_pressed):
	set_process_unhandled_key_input(button_pressed)
	if button_pressed:
		text = "... Key"
		release_focus()
	else:
		display_current_key()

	Sound.get_node("buttonClick").play()

func _unhandled_key_input(event):
	# Note that you can use the _input callback instead, especially if
	# you want to work with gamepads.
	remap_action_to(event)
	pressed = false


func remap_action_to(event):
	if event is InputEventKey:
		var events = InputMap.get_action_list(action)
		for lastevent in events:
			if lastevent is InputEventKey:			
				InputMap.action_erase_event(action, lastevent)
				break
	
	elif event is InputEventJoypadButton:
		var events = InputMap.get_action_list(action)
		for lastevent in events:
			if lastevent is InputEventJoypadButton:			
				InputMap.action_erase_event(action, lastevent)
				break
	
	"""
	elif event is InputEventJoypadMotion:
		print(Input.get_joy_axis_string(event.axis))
		var events = InputMap.get_action_list(action)
		for lastevent in events:
			if lastevent is InputEventJoypadMotion:			
				InputMap.action_erase_event(action, lastevent)
				break
	"""
	InputMap.action_add_event(action, event)
	
	
	text = "%s" % event.as_text()
	print("key remapped to: ", event.as_text())


func display_current_key():
	var current_keys = ""
	for userevent in InputMap.get_action_list(action):
		if userevent is InputEventJoypadMotion:
			"""
			var axis = userevent.axis
			var current_key = "Unnamed axis"
			if axis == 0:
				current_key = "L-stick_H-axis"
			elif axis == 1:
				current_key = "L-stick_V-axis"
			elif axis == 2:
				current_key = "R-stick_H-axis"
			elif axis == 3:
				current_key = "R-stick_V-axis"
			
			current_keys += (current_key + " | ")
			"""
		elif !(userevent is InputEventJoypadButton):
				current_keys += (userevent.as_text())
	
	text = "%s" % current_keys
