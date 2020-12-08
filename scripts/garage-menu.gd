extends Control

var dynamic:bool = false # used in-game to interact/display differently

onready var LabelScore:Label = get_node("VBoxContainer/Label2")

func _ready():
	for panel in get_tree().get_nodes_in_group("garagePanel"):
		var label:Label = panel.get_node("VBoxContainer/Label")
		var button:Button = panel.get_node("Button")
		button.connect("pressed", self, "on_any_button_pressed")
		
		if button.disabled:
			label.text = "Unlock at score " + str(Global.getSmTypeUnlockScore(button.smType))
		else:
			label.text = Global.toStringType(button.smType).to_upper()
		
		if button.smType == Global.playerGameType:
			button.grab_focus()

	LabelScore.text = "Score: " + str(Global.generalScore)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if !dynamic:
			Sound.get_node("buttonClick").play()
			get_tree().change_scene("res://pixelPlanets/GUI.tscn")


func on_any_button_pressed()->void:
	Sound.get_node("buttonClick").play()
	if dynamic:
		visible = false
	else:
		Global.save_data()
		get_tree().change_scene("res://pixelPlanets/GUI.tscn")
	
