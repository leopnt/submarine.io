extends "res://classes/weapon.gd"
class_name Mine

signal mine_hit

#we add an area to detect proximity with other objects 
var colArea:Area2D
var colShape:CollisionShape2D
var shape:CircleShape2D

var chargingPhase:bool = true

const collShapeRadius:int = 100

const initialTimeToEnable:float = 8.5

func _init(position_, emitter_).(position_, emitter_):
	timetoenable.wait_time = initialTimeToEnable
	energy.wait_time = 85.0

	shape = CircleShape2D.new()
	shape.radius = collShapeRadius
		
	colShape = CollisionShape2D.new()
	colShape.shape = shape
	colShape.set_deferred("disabled", false)
	
	colArea = Area2D.new()
	colArea.add_child(colShape)
	add_child(colArea)

	damage = 85

func _ready():
	colArea.connect("body_entered", self, "on_body_entered")


func _process(_delta):
	if chargingPhase && isEnabled():
		# to solve mine not exploding when body already inside area
		# this is executed only one time
		
		chargingPhase = false
		var counter = false
		for body in colArea.get_overlapping_bodies():
			if body is SubMarine:
				body.takeDamage(emitter, self, damage)
				emit_signal("mine_hit", emitter, body, self, position)
				counter = true
		
		if counter: # there was a hit
			queue_free()
		

func _draw():
	draw_arc(Vector2.ZERO, 6, 0, 2*PI, 12, Color(0, 1, 0), 1.0, true)
	if isEnabled():
		for angle in range(8):
			draw_line(6*Vector2.UP.rotated(angle * PI/4), 10*Vector2.UP.rotated(angle * PI/4), Color(0, 1, 0), 1.2, true)
	else:
		var loadingAngle = deg2rad(timetoenable.time_left * 180.0 / initialTimeToEnable)
		draw_arc(Vector2.ZERO, 8, -loadingAngle/2, loadingAngle/2, 12, Color(0, 1, 0), 1.2, true)
		draw_arc(Vector2.ZERO, 8, -loadingAngle/2 + PI, loadingAngle/2 + PI, 12, Color(0, 1, 0), 1.2, true)
	
	# area border:
	draw_arc(Vector2.ZERO, shape.radius, 0, 2*PI, 32, Color(0, 1, 0, 0.3), 1.0, true)


func on_body_entered(body):
	#this is a hit
	if isEnabled():
		body.takeDamage(emitter, self, damage)
		
		emit_signal("mine_hit", emitter, body, self, position)
		
		#deletes the weapon
		queue_free()
