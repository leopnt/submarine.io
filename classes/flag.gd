extends Area2D
class_name Flag

signal flag_owned
signal flag_lost

var colShape:CollisionShape2D
var shape:Shape2D

var flagOwner:SubMarine
var isOwned:bool
var ownedTimer:Timer # emit signal to tell that flag is owned

func _init(pos:Vector2):
	position = pos
	rotation = PI/4 # because draw is a rect and we want a losange
	
	shape = CircleShape2D.new()
	shape.radius = 16
	colShape = CollisionShape2D.new()
	colShape.shape = shape
	colShape.set_deferred("disabled", false)
	add_child(colShape)

	ownedTimer = Timer.new()
	ownedTimer.wait_time = 1 # seconds
	ownedTimer.autostart = true
	add_child(ownedTimer)
	
	isOwned = false
	
func _ready():
	connect("body_entered", self, "on_body_entered")
	connect("body_exited", self, "on_body_exited")
	ownedTimer.connect("timeout", self, "on_ownedTimer_timeout")

func _draw():
	draw_rect(Rect2(Vector2(-shape.radius, -shape.radius), Vector2(2*shape.radius, 2*shape.radius)), Color(0, 1, 0), false, 2.0, true)

func _process(_delta):
	if isOwned:
		position = flagOwner.position
	
	update()

func on_body_entered(body:SubMarine)->void:
	if body is SubMarine && !isOwned: # check if not already owned...
		isOwned = true
		flagOwner = body
		ownedTimer.start() # restarts the timer when catched

func on_body_exited(body:SubMarine)->void:
	if body is SubMarine && body == flagOwner:
		isOwned = false
		ownedTimer.stop() # restarts the timer when catched
		emit_signal("flag_lost")

func has_owner()->bool:
	if isOwned:
		return true
	return false

func on_ownedTimer_timeout()->void:
	if isOwned:
		emit_signal("flag_owned", flagOwner)
