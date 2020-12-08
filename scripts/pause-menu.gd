extends Control
class_name PauseMenu

signal resume_pressed

func _on_ButtonResume_pressed():
	emit_signal("resume_pressed")
	Sound.get_node("buttonClick").play()

func _on_ButtonQuit_pressed():
	#emit_signal("quit_pressed")
	get_tree().change_scene("res://pixelPlanets/GUI.tscn")
	get_tree().paused = false
	Sound.get_node("buttonClick").play()

func _notification(what):
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			get_node("VBoxContainer/ButtonResume").grab_focus()
