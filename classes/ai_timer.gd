extends Timer
class_name AITimer

signal custom_timeout

var index
var team
var typeStr

func _init(index_:int, team_:String):
	index = index_
	team = team_

	connect("timeout", self, "_on_timer_timeout")
	
func _on_timer_timeout()->void:
	emit_signal("custom_timeout", index, team, typeStr)
