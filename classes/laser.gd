extends "res://classes/weapon.gd"
class_name Laser

signal laser_hit

#this is used to detect if dodge maneuver for ai is needed:
var raycast:RayCast2D

const initialTimeToEnable:float = 1.5

var laserEmitter:SubMarine # special emitter used to track emitter position

const laserLength:int = 400

func _init(position_, targetPosition_, emitter_).(position_, emitter_):
	timetoenable.wait_time = initialTimeToEnable
	energy.wait_time = 3.0
	damage = 200
	
	laserEmitter = emitter_ # here we don't make a copy because laser is ~inside the submarine
	laserEmitter.connect("tree_exited", self, "_on_emiter_tree_exited")
	
	var direction = (targetPosition_ - position).normalized()
	raycast = RayCast2D.new()
	raycast.cast_to = laserLength * direction
	raycast.enabled = true
	raycast.collide_with_areas = true # this is because ai uses area2d to detect if dodging is needed
	raycast.collision_mask = 8 # THIS HAS TO BE ON SAME MASK THAN AI COLLISION2D's LAYER
	add_child(raycast)
	

func _draw():
	if isEnabled():
		draw_line(Vector2.ZERO, raycast.cast_to, Color(0, 1, 0, energy.time_left * 2), 1.0, true)
		draw_circle(raycast.cast_to, 2.0, Color(0, 1, 0, energy.time_left * 2))
	
	else:
		draw_line(Vector2.ZERO, raycast.cast_to, Color(0, 1, 0, timetoenable.time_left/initialTimeToEnable), 1.0, true)

func _process(_delta):
	position = laserEmitter.position # laser origin follow emitter

func _physics_process(_delta):
	if isEnabled():
		if raycast.is_colliding():
			on_raycast_collide(raycast.get_collider())

func _on_emiter_tree_exited()->void:
	queue_free()

func on_raycast_collide(body)->void:
	#this is a hit
	if isEnabled() && body is SubMarine:
		body.takeDamage(emitter, self, damage)		
		emit_signal("laser_hit", emitter, body, self, body.position)

		queue_free()
