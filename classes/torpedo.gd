#a class for torpedos. This is a weapon fired from a submarine
#the torpedo appears in the scene. It follows a direction

extends "res://classes/weapon.gd"
class_name Torpedo

signal torpedo_hit

var initialDirection:Vector2 # to keep track of rotation for child class
var direction:Vector2
var targetPos:Vector2
const maxVel:int = 40
const maxAcc:float = 6.0 #0.1 delta


#we add an area to detect proximity with other objects 
var colArea:Area2D
var colShape:CollisionShape2D
var shape:CircleShape2D

#this is used to detect if dodge maneuver for ai is needed:
var raycast:RayCast2D

var base_force:Vector2 # used to go straight


func _init(position_, targetPosition_, emitter_).(position_, emitter_):
	targetPos = targetPosition_
	
	damage = 65
	timetoenable.wait_time = 1.0
	
	
	direction = (targetPos - position).normalized()
	initialDirection = direction
	
	linear_velocity = 0.8 * maxVel * initialDirection # sets initial velocity
	base_force = maxAcc * direction
	
	shape = CircleShape2D.new()
	shape.radius = 10
		
	colShape = CollisionShape2D.new()
	colShape.shape = shape
	colShape.set_deferred("disabled", false)
	
	colArea = Area2D.new()
	colArea.add_child(colShape)
	colArea.position = 12*direction.normalized()
	add_child(colArea)
	
	raycast = RayCast2D.new()
	raycast.cast_to = 200 * direction
	raycast.enabled = true
	raycast.collide_with_areas = true # this is because ai uses area2d to detect if dodging is needed
	raycast.collision_mask = 2 # THIS HAS TO BE ON SAME MASK THAN AI AREA2D's LAYER
	add_child(raycast)
	

func _ready():
	colArea.connect("body_entered", self, "on_body_entered")
	
func _draw():
	#draw triangle:
	var vLeft = 3*direction.normalized().rotated(-PI/2)
	var vUp = 12*direction.normalized()
	var vRight = 3*direction.normalized().rotated(PI/2)
	var vDown = -4*direction.normalized()
	var tab = [vLeft, vUp, vRight, vDown]
	var vertexs = PoolVector2Array(tab)
	if isEnabled():
		# can't skip middle arguments so give them in the call to access antialiased at the end:
		# to have it fade on end of life, alpha is set to energy. It works because energy is > to 1 and alpha only takes values between 0 and 1
		draw_colored_polygon(vertexs, Color(0, 1, 0, energy.time_left), PoolVector2Array(  ), null, null, true)
	else:
		draw_colored_polygon(vertexs, Color(0, 1, 0, 0.25), PoolVector2Array(  ), null, null, true)
		
	# draw detection circle:
	draw_arc(colArea.position, shape.radius, 0, 2*PI, 16, Color(0, 1, 0, 0.2), 1.0, true)


func _process(delta):
	if linear_velocity.length() < maxVel:
		apply_impulse(Vector2.ZERO, base_force * delta)
	

func on_body_entered(body)->void:
	if isEnabled():
		#this is a hit
		body.takeDamage(emitter, self, damage)
		
		emit_signal("torpedo_hit", emitter, body, self, position)
		
		#deletes the torpedo
		#remove_from_group("worldTorpedos") not necessary ?
		queue_free()
