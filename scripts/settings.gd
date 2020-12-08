extends Control

onready var checkBoxFullscreen:CheckButton = get_node("VBoxContainer/HBoxContainer/VBoxContainer/CheckButtonFullscreen")
onready var checkBoxScaledUI:CheckButton = get_node("VBoxContainer/HBoxContainer/VBoxContainer/CheckButtonScaledUI")
onready var sliderMusicVolume:HSlider = get_node("VBoxContainer/HBoxContainer/VBoxContainer2/VBoxContainer/HSliderMusic")
onready var sliderEffectsVolume:HSlider = get_node("VBoxContainer/HBoxContainer/VBoxContainer2/VBoxContainer2/HSliderEffects")
onready var optionButtonTerrainDisplay:OptionButton = get_node("VBoxContainer/HBoxContainer/VBoxContainer/VBoxContainer/OptionButton")
onready var checkButtonPowerSaver:CheckButton = get_node("VBoxContainer/HBoxContainer/VBoxContainer/CheckButtonPowerSaver")
onready var checkButtonTVeffect:CheckButton = get_node("VBoxContainer/HBoxContainer/VBoxContainer2/CheckButtonTVeffect")
onready var checkButtonTouchControls:CheckButton = get_node("VBoxContainer/HBoxContainer/VBoxContainer/CheckButtonTouchControls")


func _ready():
	checkBoxFullscreen.pressed = OS.window_fullscreen
	checkBoxFullscreen.grab_focus()
	
	checkButtonTouchControls.pressed = Global.touchControls
	
	#"Android", "BlackBerry 10", "Flash", "Haiku", "iOS", "HTML5", "OSX", "Server", "Windows", "WinRT", "X11"
	var platform = OS.get_name()
	if platform == "Android" || platform == "BlackBerry 10" || platform == "Flash" || platform == "iOS" || platform == "HTML5":
		checkButtonTouchControls.disabled = true
		checkBoxFullscreen.disabled = true
		
	
	checkBoxScaledUI.pressed = Global.scaledUI
	if Global.powerSaver:
		checkBoxScaledUI.disabled = true
	
	checkButtonPowerSaver.pressed = Global.powerSaver
	
	checkButtonTVeffect.pressed = Global.TVeffect
	
	sliderMusicVolume.value = Global.musicVolume
	sliderEffectsVolume.value = Global.effectsVolume
	
	optionButtonTerrainDisplay.selected = Global.terrainDisplay

func _on_ButtonBack_pressed():
	Sound.get_node("buttonClick").play()
	Global.save_settings()
	get_tree().change_scene("res://pixelPlanets/GUI.tscn")


func _on_ButtonControls_pressed():
	Sound.get_node("buttonClick").play()
	get_tree().change_scene("res://input_mapping/InputRemapMenu.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_ButtonBack_pressed()


func _on_CheckButtonFullscreen_toggled(button_pressed):
	Sound.get_node("buttonClick").play()
	if button_pressed:
		OS.window_fullscreen = true
	else:
		OS.window_fullscreen = false


func _on_CheckButtoScaledUI_toggled(button_pressed):
	Sound.get_node("buttonClick").play()
	if button_pressed:
		get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D,  SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1024, 600))
		Global.scaledUI = true
	else:
		get_tree().set_screen_stretch(SceneTree.STRETCH_ASPECT_IGNORE,  SceneTree.STRETCH_ASPECT_IGNORE, Vector2(1024, 600))
		Global.scaledUI = false
		Global.alert("This setting is experimental\nOnly relevant for bigger screen", "Warning: disable Scaled UI")
	


func _on_HSliderMusic_value_changed(value):
	Global.musicVolume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("MUSIC"), value)


func _on_HSliderEffects_value_changed(value):
	Sound.get_node("buttonClick").play()
	Global.effectsVolume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("EFFECTS"), value)


func _on_OptionButton_item_selected(index):
	Global.terrainDisplay = index
	
	if index == 0:
		Global.alert("May see some flickering", "Warning: isoline Terrain Display")


func _on_CheckButtonPowerSaver_toggled(button_pressed):
	Sound.get_node("buttonClick").play()
	if button_pressed:
		Global.powerSaver = true
		Global.alert("Game fps maxed at 30\nResolution set to 1024x600", "Power saver enabled")
		Engine.set_target_fps(30)
		get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT,  SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1024, 600))
		checkBoxScaledUI.disabled = true
	else:
		Global.powerSaver = false
		Engine.set_target_fps(0)
		checkBoxScaledUI.disabled = false
		if Global.scaledUI: # because this setting is overriden by scaled ui
			get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D,  SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1024, 600))
		else:
			get_tree().set_screen_stretch(SceneTree.STRETCH_ASPECT_IGNORE,  SceneTree.STRETCH_ASPECT_IGNORE, Vector2(1024, 600))
			


func _on_CheckButtonTVeffect_toggled(button_pressed):
	Sound.get_node("buttonClick").play()
	if button_pressed and !Global.TVeffect:
		Global.TVeffect = true
		get_node("CRTeffect_layer/CRT_texture").show() # for the effect to take place immediately as it self-check in _ready for Global.TVeffect
	elif !button_pressed and Global.TVeffect:
		Global.TVeffect = false
		get_node("CRTeffect_layer/CRT_texture").hide()


func _on_CheckButtonTouchControls_toggled(button_pressed):
	if button_pressed:
		Global.touchControls = true
	else:
		Global.touchControls = false
