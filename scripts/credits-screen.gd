extends Control

func _ready():
	get_node("VBoxContainer/exit-credits").grab_focus()

func _on_exitcredits_pressed():
	get_tree().change_scene("res://pixelPlanets/GUI.tscn")
	Sound.get_node("buttonClick").play()

func _input(event):	
	if event.is_action_pressed("ui_cancel"):
		_on_exitcredits_pressed()
