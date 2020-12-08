extends Control

onready var planet_holder = $HBoxContainer/PlanetHolder
onready var planets = [
	preload("res://pixelPlanets/Planets/GasPlanet/GasPlanet.tscn"),
	preload("res://pixelPlanets/Planets/LandMasses/LandMasses.tscn"),
	preload("res://pixelPlanets/Planets/NoAtmosphere/NoAtmosphere.tscn"),
	preload("res://pixelPlanets/Planets/Rivers/Rivers.tscn")
]
var pixels = 70.0
var scale = 1.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	print("loading settings from GUI...")
	Global.load_settings()
	Global.read_inputs()
	Global.load_data()
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("MUSIC"), Global.musicVolume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("EFFECTS"), Global.effectsVolume)
	
	get_node("HBoxContainer/Settings/VBoxContainer2/Control2/VBoxContainer/play").grab_focus()
	
	Global.updateUnlockedTypes()
	
	# stop each previous sound
	for soundNode in Sound.get_children():
		if soundNode != Sound.get_node("computer") && soundNode != Sound.get_node("gameScreenMusic1"):
			if soundNode.playing == true:
				soundNode.stop()
	
	if !Sound.get_node("computer").playing:
		Sound.get_node("computer").play()
		
	if !Sound.get_node("gameScreenMusic1").playing:
		Sound.get_node("gameScreenMusic1").play(9.06)
	
	if Sound.get_node("gameMainMusic1").playing:	
		Sound.get_node("gameMainMusic1").stop()

	if Sound.get_node("smInside").playing == true:
		Sound.get_node("smInside").stop()


func _on_Control_gui_input(event):
	if (event is InputEventMouseMotion || event is InputEventScreenTouch): #&& Input.is_action_pressed("mouse"):
		var normal = event.position / (16 * $Control.rect_size) + Vector2(0.6, 0.4)
		planet_holder.get_child(0).set_light(normal)


func _create_new_planet():
	var new_p = planets[randi() % planets.size()].instance()
	new_p.set_seed(randi())
	new_p.set_pixels(pixels)
	planet_holder.get_child(0).queue_free()
	planet_holder.add_child(new_p)

func _on_play_pressed():
	get_tree().change_scene("res://scenes/mode-menu.tscn")
	Sound.get_node("buttonClick").play()


func _on_exitgame_pressed():
	Sound.get_node("buttonClick").play()
	get_tree().quit()


func _on_credits_pressed():
	get_tree().change_scene("res://scenes/credits-screen.tscn")
	Sound.get_node("buttonClick").play()


func _on_settings_pressed():
	get_tree().change_scene("res://scenes/settings.tscn")
	Sound.get_node("buttonClick").play()


func _on_garage_pressed():
	get_tree().change_scene("res://scenes/garage-menu.tscn")
	Sound.get_node("buttonClick").play()
