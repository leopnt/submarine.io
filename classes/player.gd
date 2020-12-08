extends "res://classes/subMarine.gd"
class_name Player

signal player_dead
signal player_respawn
var cam:Camera2D

var nonScaledUIRatio:float

# --- virtual smartphone var ---
# dirty access...
onready var vJoyMove:Joystick = get_parent().get_parent().get_node("UI_layer/JoystickMove")
onready var vJoyAim:Joystick = get_parent().get_parent().get_node("UI_layer/JoystickAim")
onready var vJoySpe:Joystick = get_parent().get_parent().get_node("UI_layer/JoystickSpe")


func _init():
	
	cam = Camera2D.new()
	cam.current = true
	cam.smoothing_enabled = true
	update_zoom()
	add_child(cam)
	

func _ready():
	connect("tree_exited", self, "on_player_dead") # for ui
	vJoyAim.connect("touch_ended", self, "_on_JoystickAim_touch_ended")
	vJoySpe.connect("touch_ended", self, "_on_JoystickSpe_touch_ended")
	
	
	
	emit_signal("player_respawn") # for ui

func _process(delta):
	applyInputs(delta)
	
	cam.position = 10 * Controller.get_left_axis() + 10 * aimingPoint
	update()

func _draw():
	# aiming lines:
	var radOffset = radius + 10
	var lineOffset = Vector2(radOffset, 0).rotated(aimingPoint.angle())
	
	if Global.touchControls:
		var tLen = clamp(vJoyAim.output.length(), 0, 0.7)
		draw_line(lineOffset, lineOffset + 80*tLen*aimingPoint.rotated(-0.02), Color(0, 1, 0, 0.8), 1.0, true)
		draw_line(lineOffset, lineOffset + 80*tLen*aimingPoint.rotated(0.02), Color(0, 1, 0, 0.8), 1.0, true)
	else:
		draw_line(lineOffset, lineOffset + 80*aimingPoint.rotated(-0.02), Color(0, 1, 0, 0.8), 1.0, true)
		draw_line(lineOffset, lineOffset + 80*aimingPoint.rotated(0.02), Color(0, 1, 0, 0.8), 1.0, true)
	
	
	# draw loaded torpedos
	var arc_da = PI/12
	if loadedWeapons > 0:
		var arc_center_angle = aimingPoint.angle() + PI
		draw_arc(Vector2.ZERO, radius + 14, arc_center_angle - arc_da, arc_center_angle + arc_da, 3, Color(0, 1, 0), 1.2, true)
	if loadedWeapons > 1:
		var arc_center_angle = aimingPoint.angle() - (2 * PI / 3)
		draw_arc(Vector2.ZERO, radius + 14, arc_center_angle - arc_da, arc_center_angle + arc_da, 3, Color(0, 1, 0), 1.2, true)
	if loadedWeapons > 2:
		var arc_center_angle = aimingPoint.angle() + (2 * PI / 3)
		draw_arc(Vector2.ZERO, radius + 14, arc_center_angle - arc_da, arc_center_angle + arc_da, 3, Color(0, 1, 0), 1.2, true)
	if loadedSpe == true:
			var arc_center_angle = aimingPoint.angle() + PI
			draw_arc(Vector2.ZERO, radius + 20, arc_center_angle - PI/6, arc_center_angle + PI/6, 16, Color(0, 1, 0), 1.2, true)
	
	
	if !is_in_group("sm_fst"): # fst already has a triangle shape
		# draw velocity triangle:
		var vOffset = Vector2(radius, 0).rotated(linear_velocity.angle())
		var vLeft = vOffset + 4*linear_velocity.normalized().rotated(-PI/2)
		var vUp = vOffset + 8*linear_velocity.normalized()
		var vRight = vOffset + 4*linear_velocity.normalized().rotated(PI/2)
		var tab = [-vLeft, -vUp, -vRight]
		var vertexs = PoolVector2Array(tab)
		# can't skip middle arguments so give them in the call to access antialiased at the end:
		draw_colored_polygon(vertexs, Color(0, 1, 0, 1), PoolVector2Array(  ), null, null, true)
	
	
	if loadedSpe == true:
		if is_in_group("sm_std"):
		# draw spe arc
			# draw minimum spe-enabling-distance for successful acquiring
			# check guidedTorpedo.gd for specific values
			var arc_mindist_center_angle = aimingPoint.angle()
			draw_arc(Vector2.ZERO, 178, arc_mindist_center_angle - 0.44, arc_mindist_center_angle + 0.44, 32, Color(0, 1, 0, 0.5), 1.0, true)
			draw_line(Vector2.ZERO, Vector2(0, 178).rotated(arc_mindist_center_angle - 0.44 - PI/2), Color(0, 1, 0, 0.5), 1.0, true)
			draw_line(Vector2.ZERO, Vector2(0, 178).rotated(arc_mindist_center_angle + 0.44 - PI/2), Color(0, 1, 0, 0.5), 1.0, true)
	
		if is_in_group("sm_slw"):
		# draw aiming line
			draw_line(Vector2.ZERO, Laser.laserLength * aimingPoint.normalized(), Color(0, 1, 0, 0.5), 1.0, true)
		
		if is_in_group("sm_fst"):
			draw_arc(Vector2.ZERO, Mine.collShapeRadius, 0, 2*PI, 64, Color(0, 1, 0, 0.5), 1.0, true)
		

func applyInputs(delta)->void:
	var force = Vector2.ZERO
	
	if Global.touchControls:
		force = max_force * vJoyMove.output
		var vJoyOut = (vJoyAim.output + vJoySpe.output).clamped(1.0)
		smoothAim(vJoyOut)
	
	if Input.is_action_pressed("move_left"):
		force += max_force * Vector2.LEFT
	if Input.is_action_pressed("move_up"):
		force += max_force * Vector2.UP
	if Input.is_action_pressed("move_right"):
		force += max_force * Vector2.RIGHT
	if Input.is_action_pressed("move_down"):
		force += max_force * Vector2.DOWN
	force = force.clamped(max_force)
	
	if Controller.isConnected:
		force = max_force * Controller.get_left_axis()
		
		if Controller.get_right_axis() != Vector2.ZERO:
			smoothAimController(Controller.get_right_axis() * delta)
	else:
		if Input.is_action_pressed("aim_left"):
			increaseAimingAngle(1.2 * delta)
		if Input.is_action_pressed("aim_right"):
			decreaseAimingAngle(1.2 * delta)
	
	
	if linear_velocity.length() < max_speed:
		apply_impulse(Vector2.ZERO, force * delta)


func _input(event):
	if event.is_action_pressed("shoot"):
		if loadedWeapons > 0:
			Controller.vibrate(0.2, 0.6, 0.2)
		fireWeapon()
	
	if event.is_action_pressed("shoot_spe"):
		if loadedSpe:
			Controller.vibrate(0.4, 0.8, 0.2)
		fireSpe()
		
	# DEBUG
	"""
	var just_pressed = event.is_pressed() and not event.is_echo()
	if Input.is_key_pressed(KEY_R) and just_pressed:
		loadedWeapons = 3
		loadedSpe = true
	
	if Input.is_key_pressed(KEY_C) and just_pressed:
		takeDamage(self, null, 10)
	"""


func smoothAim(desiredAim:Vector2)->void:
	aimingPoint = lerp(aimingPoint, desiredAim, 0.5).normalized()


func smoothAimController(ControllerAxis:Vector2)->void:
	if ControllerAxis.x < 0:
		increaseAimingAngle(-1.2*ControllerAxis.x)
	else:
		decreaseAimingAngle(1.2*ControllerAxis.x)


func increaseAimingAngle(da:float)->void:
	aimingPoint = aimingPoint.rotated(-da)

func decreaseAimingAngle(da:float)->void:
	aimingPoint = aimingPoint.rotated(da)

func on_player_dead()->void:
	emit_signal("player_dead")
	emit_signal("spe_no_longer_available") # to hide joystick from main

func on_player_respawn()->void:
	emit_signal("player_respawn")
	print("player::signal emited player_respawn")


func _on_JoystickAim_touch_ended():
	if vJoyAim.output != Vector2.ZERO:
		fireWeapon()

func _on_JoystickSpe_touch_ended():
	if vJoySpe.output != Vector2.ZERO:
		fireSpe()

func update_zoom()->void:
	# called from crt texture signal
	cam.zoom = Vector2(1.2, 1.2)
	if !Global.scaledUI:
		print("zoom updated")
		nonScaledUIRatio = 600 / OS.window_size.y
		cam.zoom *= nonScaledUIRatio
