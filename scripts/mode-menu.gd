extends Control


func _ready():
	get_node("VBoxContainer/HSlider").value = Global.GAMETIME
	get_node("VBoxContainer/HSlider/Label").text = str(Global.GAMETIME) + " min"
	
	get_node("VBoxContainer/TeamDeathmatch").grab_focus()

func _input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_quit_pressed()

func _on_TeamDeathmatch_pressed():
	Global.GAMEMODE = Global.gamemodes.TEAMDEATHMATCH
	get_tree().change_scene("res://scenes/Team-deathmatch.tscn")
	prepareSoundForGame()


func _on_CaptureTheFlag_pressed():
	Global.GAMEMODE = Global.gamemodes.CTF
	get_tree().change_scene("res://scenes/Team-deathmatch.tscn")
	prepareSoundForGame()


func _on_Deathmatch_pressed():
	Global.GAMEMODE = Global.gamemodes.DEATHMATCH
	get_tree().change_scene("res://scenes/Team-deathmatch.tscn")
	prepareSoundForGame()


func _on_quit_pressed():
	get_tree().change_scene("res://pixelPlanets/GUI.tscn")
	Sound.get_node("buttonClick").play()


func prepareSoundForGame()->void:
	Sound.get_node("buttonClick").play()
	Sound.get_node("gameScreenMusic1").stop()
	Sound.get_node("gameMainMusic1").play()
	Sound.get_node("computer").stop()
	#Sound.get_node("computer").volume_db = -18


func _on_HSlider_value_changed(value):
	Global.GAMETIME = value # convert to seconds
	get_node("VBoxContainer/HSlider/Label").text = str(Global.GAMETIME) + " min"
	Sound.get_node("buttonClick").play()
