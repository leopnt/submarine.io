extends Node

var controllerID = 0
var isConnected = false
const deadZone = 0.2

enum axis {
	LEFT_R = 0,
	LEFT_D = 1,
	RIGHT_R = 2,
	RIGHT_D = 3,
	LEFT_L = -1000,
	LEFT_U = -1001,
	RIGHT_L = -1002,
	RIGHT_U = -1003
	} # -1000 stores the minus information


func _ready():
	Input.connect("joy_connection_changed",self,"joy_con_changed")
	if Input.get_connected_joypads().size() > 0:
		isConnected = true
	
func joy_con_changed(deviceid,isConnected_):
	if isConnected_:
		print("Controller " + str(deviceid) + " connected")
		controllerID = deviceid
	
	if Input.is_joy_known(0):
		print("Recognized and compatible joystick")
		print(Input.get_joy_name(controllerID) + " connected")
	else:
		print("Controller " + str(deviceid) + " disconnected")
		controllerID = null
	
	isConnected = isConnected_


func get_left_axis()->Vector2:
	var returnaxis = Vector2.ZERO
	if isConnected:
		var joyLX = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		var joyLY = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		
		returnaxis = Vector2(joyLX, joyLY)	
		
	return returnaxis


func get_right_axis()->Vector2:
	var returnaxis = Vector2.ZERO
	if isConnected:
		var joyRX = Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left")
		var joyRY = Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
		
		returnaxis = Vector2(joyRX, joyRY)
	
	return returnaxis


func vibrate(vibSpeed:float, vibStrenght:float, vibTime:float):
	Input.start_joy_vibration(controllerID, vibSpeed, vibStrenght, vibTime)
		
	
func map(value:float, istart:float, istop:float, ostart:float, ostop:float)->float:
	return ostart + (ostop - ostart) * ((value - istart) / (istop - istart))
