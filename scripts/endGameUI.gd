extends Control
class_name EndGameUI

signal reload_pressed

func _on_button_quit_pressed():
	get_tree().change_scene("res://pixelPlanets/GUI.tscn")
	get_tree().paused = false
	Sound.get_node("buttonClick").play()


func _on_button_reload_pressed():
	emit_signal("reload_pressed")
	Sound.get_node("buttonClick").play()

func _notification(what):
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			get_node("VBoxContainer/VBoxContainer/HBoxContainer/button_reload").grab_focus()
