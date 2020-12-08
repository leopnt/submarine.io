# it tracks torpedos from the group worldTorpedos
# it's way more efficient than giving a tracking array to each submarine

extends "res://classes/subMarine.gd"
class_name AiSubMarine

var minDodgeReaction:float = 0.96 #where 0.0 is when the torpedo is going at 90° away and 1.0 straight to self
var minDangerDistance:int = 300 #above this, ai will not try to dodge torpedo

var dodge_force:Vector2 #the global force used to add multiple dodging maneuver but clamp to max_force

var autoShootTimer:Timer
var speAutoShootTimer:Timer

var steer:Vector2

var avoidArea:Area2D
var avoidTorpColShape:CollisionShape2D
var avoidShape:CircleShape2D

var turnAroundDir:float # so that each ai in the game will turn (decide) clockwise or anticlockwise randomly

func _init():
	autoShootTimer = Timer.new()
	autoShootTimer.wait_time = rand_range(1.0, coolDownTime + 5.0) # seconds
	autoShootTimer.autostart = true
	add_child(autoShootTimer)
	
	speAutoShootTimer = Timer.new()
	speAutoShootTimer.wait_time = rand_range(1.0, specialCoolDownTime + 5.0) # seconds
	speAutoShootTimer.autostart = true
	add_child(speAutoShootTimer)
	
	
	avoidShape = CircleShape2D.new()
	avoidShape.radius = 28
	avoidTorpColShape = CollisionShape2D.new()
	avoidTorpColShape.shape = avoidShape
	avoidTorpColShape.set_deferred("disabled", false)
	avoidArea = Area2D.new()
	avoidArea.add_child(avoidTorpColShape)
	avoidArea.collision_layer = 2 # THIS HAS TO BE ON SAME LAYER THAN TORPEDO's RAYCAST MASK
	add_child(avoidArea)

	turnAroundDir = rand_range(-1.0, 1.0)
	if turnAroundDir >= 0:
		turnAroundDir = 1
	else:
		turnAroundDir = -1

func _ready():
	autoShootTimer.connect("timeout", self, "on_shootingTimer_timeout")
	speAutoShootTimer.connect("timeout", self, "on_speAutoShootTimer_timeout")

func _draw():
	#draw_circle(Vector2.ZERO, 4, Color(0, 1, 0))
	#draw_arc(Vector2.ZERO, 4, 0, 2*PI, 8, Color(0, 1, 0), 1, true)
	draw_line(Vector2.ZERO, steer, Color(1, 0, 0))
	

func _process(delta):
	applyGameLogic()
	
	avoidArea.position = linear_velocity # so that dodging takes velocity into account (not best solution)
	
	var canSlowDown = true # if at least one torpedo need to dodged
	var canSeek = true
	for torpedo in get_tree().get_nodes_in_group("worldTorpedos"):
		if needManeuver(torpedo):
			dodgeManeuver(torpedo)
			canSlowDown = false
			canSeek = false
	
	for mine in get_tree().get_nodes_in_group("worldMines"):
		fleeMine(mine) # call this BEFORE fleeWall as it is more important to dodge wall in case ai encounters both
	
	# for slow down movement
	if canSlowDown && steer == Vector2.ZERO:
		apply_impulse(Vector2.ZERO, -linear_velocity.clamped(max_force) * delta)
	
	# for follow movement
	if !canSeek:
		steer = Vector2.ZERO 
	
	# for dodge movement
	# no matter how many torpedos are tracked, the force will never exceed max_force:
	dodge_force = dodge_force.normalized() * max_force
	# same for steering
	steer = steer.clamped(max_force)
	
	fleeWall() 
	
	# apply movements
	if linear_velocity.length() < max_speed:
		var force = (dodge_force + steer).clamped(max_force)
		apply_central_impulse(delta * force)
	
	dodge_force = Vector2.ZERO #reset force
	steer = Vector2.ZERO

	update()

func applyGameLogic()->void:
	if Global.GAMEMODE == Global.gamemodes.TEAMDEATHMATCH:
		if is_in_group("USSR_team"):
			apply_tdm_ai_logic("USA_team")
		elif is_in_group("USA_team"):
			apply_tdm_ai_logic("USSR_team")
	
	if Global.GAMEMODE == Global.gamemodes.CTF:
		if is_in_group("USSR_team"):
			apply_flag_ai_logic("USA_team")
		elif is_in_group("USA_team"):
			apply_flag_ai_logic("USSR_team")
		
	if Global.GAMEMODE == Global.gamemodes.DEATHMATCH:
		apply_dm_ai_logic("USA_team")


func apply_flag_ai_logic(aiEnnemyTeam:String)->void:
	var threat = getClosestFromGroup(get_tree().get_nodes_in_group(aiEnnemyTeam))
	aimAt(threat)
	
	if life >= 25:
		var flag = getClosestFlag(get_tree().get_nodes_in_group("flags"))
		#if flag.has_owner():
		if flag.flagOwner != self: # if ai is not already the owner of the flag
			# var distToFlag = (ai.position - flag.position).length()
			if !flag.has_owner():
				seek(flag)
			elif flag.has_owner():
				threat = flag.flagOwner
				seekAndArrive(threat)
			else:
				seekAndArrive(threat)
		else:
			flee(threat)
	else:
		flee(threat)


func apply_tdm_ai_logic(aiEnnemyTeam:String)->void:
	var threat = getClosestFromGroup(get_tree().get_nodes_in_group(aiEnnemyTeam))
	aimAt(threat)
	if life >= 50:
		seekAndArrive(threat)
	else:
		flee(threat)


func apply_dm_ai_logic(generalGroup:String)->void:
	var threat = getClosestFromGroup(get_tree().get_nodes_in_group(generalGroup))
	aimAt(threat)
	if life >= 50:
		seekAndArrive(threat)
	else:
		flee(threat)



func fleeWall()->void:
	# if close to wall, modify steer
	if (position + 4 * linear_velocity).length() > 0.95 * Map.radius:
		steer = -position.clamped(max_force)
		dodge_force = Vector2.ZERO


func needManeuver(torpedo:Torpedo)->bool:
	# returns true if the torpedo's raycast touches the avoidArea
	if torpedo.raycast.is_colliding():
		if torpedo.raycast.get_collider() == avoidArea:
			return true
		
	return false

func dodgeManeuver(torpedo:Torpedo)->void:
	# it moves away from a torpedo direction
	#
	#       <-*->   self
	#
	#         ^     torpedo
	#         |
	#
	# it doesn't take into account linear_velocity
	
	var torpToSelf:Vector2 = position - torpedo.position
	var torpDir:Vector2 = (torpedo.position - torpedo.targetPos)
	
	
	# to decide if needs to go left or right from torpedo
	var dodgeDirection:float = sin(torpToSelf.angle_to(torpDir))
	if dodgeDirection > 0:
		dodgeDirection = 1
	else:
		dodgeDirection = -1
	
	dodge_force += dodgeDirection * torpDir.normalized().rotated(-PI/2)
	# note the + sign, this is because dodge_force is global and take into account more than one torpedo

func aimAt(sm:SubMarine)->void:
	if is_in_group("sm_slw"):
		aimingPoint = getLaserInterPred(sm).normalized()
	else:
		aimingPoint = getInterPred(sm).normalized()
	
	aimingPoint *= (sm.position - position).length()

func on_shootingTimer_timeout()->void:
	if aimingPoint.length() < max_shooting_dist:
		fireWeapon()
		autoShootTimer.wait_time = rand_range(1.0, coolDownTime + 5.0) # seconds

func on_speAutoShootTimer_timeout()->void:
	if aimingPoint.length() < max_shooting_dist && aimingPoint.length() > 200: # see guided torpedo area for value approximations
		fireSpe()
		speAutoShootTimer.wait_time = rand_range(1.0, specialCoolDownTime + 5.0)

func seek(target:Node2D)->void:
	var desiredVel = target.position - position
	steer += desiredVel - linear_velocity

func seekAndArrive(target:Node2D)->void:
	var desiredVel = target.position - position
	if desiredVel.length() > 250:
		steer += desiredVel - linear_velocity
	
	else:
		# turn around the target
		steer += (desiredVel - linear_velocity).rotated(turnAroundDir * (PI/1.5))
	
	
func flee(ennemy:Node2D)->void:
	var desiredVel = position - ennemy.position
	if desiredVel.length() < 250:
		steer += desiredVel - linear_velocity


func fleeMine(mine:Mine)->void:
	var desiredVel = position - mine.position
	if desiredVel.length() < 1.2 * Mine.collShapeRadius:
		steer = desiredVel - linear_velocity

func getLaserInterPred(sm:SubMarine)->Vector2:
	# returs intersection prediction position
	var smPos:Vector2 = sm.position
	var smVel:Vector2 = sm.linear_velocity
	
	var t = Laser.initialTimeToEnable
	
	var selfPos:Vector2 = position + t * linear_velocity
	
	var intersectinPoint = smPos + t * smVel
	var predictedColPos = (intersectinPoint - selfPos) / t
	
	return predictedColPos


func getInterPred(sm:SubMarine)->Vector2:
	# returs intersection prediction position
	var selfPos:Vector2 = position
	var smPos:Vector2 = sm.position
	var torpSpeed:float = Torpedo.maxVel
	var smVel:Vector2 = sm.linear_velocity
	var selfToSm:Vector2 = selfPos - smPos
	var l:float = selfToSm.length()
	var smSpeed:float = smVel.length()
	
	# quadratic equation resolution
	var a = pow(torpSpeed, 2) - pow(smSpeed, 2)
	var b = 2 * selfToSm.dot(smVel)
	var c = -pow(l, 2)
	var t = (-b + sqrt(pow(b, 2) - 4 * a * c)) / (2 * a)
	
	var intersectinPoint = smPos + t * smVel
	var predictedColPos = (intersectinPoint - selfPos) / t
	
	return predictedColPos


func getClosestFromGroup(groupArray:Array)->SubMarine:
	# return null if group is empty
	var closestSm:SubMarine = null
	var closest_dist = INF
	for sm in groupArray:
		if sm != self:
			var dist = (sm.position - position).length()
			if dist < closest_dist:
				closest_dist = dist
				closestSm = sm
	
	return closestSm

func getClosestFlag(flags:Array)->Flag:
	var closestF:Flag = null
	var closest_dist = INF
	for flag in flags:
		var dist = (flag.position - position).length()
		if dist < closest_dist:
			closest_dist = dist
			closestF = flag
	
	return closestF
