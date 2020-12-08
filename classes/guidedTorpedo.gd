extends "res://classes/torpedo.gd"
class_name GuidedTorpedo

var seekArea:Area2D
var seekColShape:CollisionShape2D
var seekShape:ConvexPolygonShape2D

var trackedTarget:SubMarine

var steer:Vector2
const max_steer_force:float = 12.0 #0.2 delta

func _init(position_, targetPosition_, emitter_).(position_, targetPosition_, emitter_):
	seekShape = ConvexPolygonShape2D.new()
	seekShape.points = PoolVector2Array([
		Vector2(0, 0),
		Vector2(80, 170).rotated(direction.angle() - PI/2),
		Vector2(-80, 170).rotated(direction.angle() - PI/2)
		])
		
	seekColShape = CollisionShape2D.new()
	seekColShape.shape = seekShape
	seekColShape.set_deferred("disabled", false)
	
	seekArea = Area2D.new()
	seekArea.add_child(seekColShape)
	seekArea.position = direction.normalized()
	add_child(seekArea)
	
	trackedTarget = null
	
	steer = Vector2.ZERO

func _ready():
	seekArea.connect("body_entered", self, "on_seek_area_entered")
	seekArea.connect("body_exited", self, "on_seek_area_exited")
	
	
func _process(delta):
	seek(trackedTarget)
	if linear_velocity.length() < maxVel:
		apply_central_impulse(steer * delta)
	else:
		apply_central_impulse(-linear_velocity.clamped(2) * delta) # some impulse to slow down and allow to use more steer

	steer = Vector2.ZERO
	
	
func seek(target:RigidBody2D)->void:
	if isEnabled() && target != null:
		rotateSelf()
		
		base_force = Vector2.ZERO # needs to be disabled because it is executed before in parent class. this is because _process can't be overrided
		
		var desiredVel = (target.position + target.linear_velocity) - position
		steer = (desiredVel - linear_velocity).clamped(max_steer_force)


func rotateSelf()->void:
	# rotate every aspect of the torpedo manually
	
	direction = linear_velocity.normalized()
	seekArea.rotation = direction.angle() - initialDirection.angle()
	raycast.rotation = direction.angle() - initialDirection.angle()
	colArea.position = 12*direction.normalized()


func _draw():
	# to differentiate from classic torpedos
	if isEnabled():
		# rear ailerons
		draw_line(Vector2.ZERO, 10 * Vector2.LEFT.rotated(direction.angle() - PI/8), Color(0, 1, 0, energy.time_left), 1, true)
		draw_line(Vector2.ZERO, 10 * Vector2.LEFT.rotated(direction.angle() + PI/8), Color(0, 1, 0, energy.time_left), 1, true)

	# show that target is acquiered
	if trackedTarget != null:
		draw_line(14 * direction, 9 * direction.rotated(PI/4), Color(0, 1, 0), 1, true)
		draw_line(14 * direction, 9 * direction.rotated(-PI/4), Color(0, 1, 0), 1, true)


func on_seek_area_entered(body)->void:
	if trackedTarget == null &&  body.name != emitter.name:
		# we don't want to assign another target if there is already one tracked
		# torpedo will never track emitter (actually to avoid bugs at shoot time when emitter is in the area)
		# note that we COMPARE NAMES because emitter is a copy of the actual one (see torpedo constructor)
		# so comparing references directly doesn't not work
		
		trackedTarget = body

	
func on_seek_area_exited(body)->void:
	if body == trackedTarget:
		trackedTarget = null
