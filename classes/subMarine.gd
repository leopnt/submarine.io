extends RigidBody2D
class_name SubMarine

signal submarine_dead
signal submarine_respawn

signal torpedo_fired
signal guided_torpedo_fired
signal mine_dropped
signal laser_fired

signal spe_available
signal spe_no_longer_available

signal killed

var life:int
var max_life:int
const regenerationCooldownTime:float = 1.0 # in seconds
var regenerationTimer:Timer

const outsideOfMapCountDown:float = 1.0
var outsideOfMapKillerTimer:Timer

var max_force:float
var max_undetectable_vel:float
var max_speed:float
var aimingPoint:Vector2

const radius:int = 8

var colShape:CollisionShape2D
var shape:CircleShape2D

var loadedWeapons:int
const max_loadedWeapons:int = 3

var loadedSpe:bool # can only have 1 special shot

var reloadTimer:Timer
const coolDownTime:float = 10.0

var specialReloadTimer:Timer # for special weapon
const specialCoolDownTime:float = 30.0

var immune:bool # to avoid spawn kill
var immuneTimer:Timer
const immuneTimerCooldown:float = 10.0

const max_shooting_dist:int = 300

var lastDamageSource:SubMarine
var weaponDamageSource:Torpedo

var torpedoShootSound:AudioStreamPlayer2D
var torpedoHitSound:AudioStreamPlayer2D
var engineSound:AudioStreamPlayer2D

var respawnTimer:Timer
const respawnCoolDown:float = 10.0

var index:int # used to track in main respawn timers

func _init():
	collision_layer = 8 #only layer 4 for laser detection
	
	mode = RigidBody2D.MODE_CHARACTER # disable rotation
	
	# default type variables
	# we put this defaults here because initVarType is called manually in the main so after _init()
	max_life = 100
	life = max_life
	
	max_force = 0.1
	max_undetectable_vel = 10.0 #knots
	max_speed = 25
	
	
	regenerationTimer = Timer.new()
	regenerationTimer.wait_time = regenerationCooldownTime # seconds
	regenerationTimer.autostart = true
	add_child(regenerationTimer)
	
	outsideOfMapKillerTimer = Timer.new()
	outsideOfMapKillerTimer.wait_time = outsideOfMapCountDown # seconds
	outsideOfMapKillerTimer.autostart = true
	add_child(outsideOfMapKillerTimer)
	
	aimingPoint = Vector2.UP
	
	loadedWeapons = max_loadedWeapons
	loadedSpe = false
	
	reloadTimer = Timer.new()
	reloadTimer.wait_time = coolDownTime # seconds
	reloadTimer.autostart = false # because sm fully loaded at start. it will start when shoot occures
	add_child(reloadTimer)
	
	specialReloadTimer = Timer.new()
	specialReloadTimer.wait_time = specialCoolDownTime # seconds
	specialReloadTimer.autostart = true # because spe is not loaded at start
	add_child(specialReloadTimer)
	
	immune = true
	immuneTimer = Timer.new()
	immuneTimer.wait_time = immuneTimerCooldown
	immuneTimer.autostart = true
	add_child(immuneTimer)
	
	shape = CircleShape2D.new()
	shape.radius = radius
	colShape = CollisionShape2D.new()
	colShape.shape = shape
	add_child(colShape)

	torpedoShootSound = AudioStreamPlayer2D.new()
	torpedoShootSound.stream = load("res://sounds/Jarusca-missile_launch.wav")
	torpedoShootSound.volume_db = 6
	torpedoShootSound.pitch_scale = 0.45
	torpedoShootSound.attenuation = 12
	torpedoShootSound.bus = "underwater"
	add_child(torpedoShootSound)
	
	torpedoHitSound = AudioStreamPlayer2D.new()
	torpedoHitSound.stream = load("res://sounds/tommccann-explosion.wav")
	torpedoHitSound.volume_db = 0
	torpedoHitSound.pitch_scale = 1
	torpedoHitSound.attenuation = 10
	torpedoHitSound.bus = "underwater"
	add_child(torpedoHitSound)

	engineSound = AudioStreamPlayer2D.new()
	engineSound.stream = load("res://sounds/Samantha_Dolman-submarin_inside.wav")
	engineSound.volume_db = -6
	engineSound.pitch_scale = 0.9 + 0.01 * linear_velocity.length()
	engineSound.attenuation = 15
	engineSound.bus = "sm-inside"
	engineSound.autoplay = true
	add_child(engineSound)


func initTypeVar()->void:
	if is_in_group("sm_std"):
		max_life = 100
		life = max_life
		max_force = 6 #0.1 delta
		max_undetectable_vel = 10.0 #knots
		max_speed = 25 #1500
	elif is_in_group("sm_fst"):
		max_life = 50
		life = max_life
		max_force = 9 #0.15
		max_undetectable_vel = 10.0 #knots
		max_speed = 35
	elif is_in_group("sm_slw"):
		max_life = 150
		life = max_life
		max_force = 3 #0.05
		max_undetectable_vel = 10.0 #knots
		max_speed = 15


func _ready():
	reloadTimer.connect("timeout", self, "on_reloadTimer_timeout")
	specialReloadTimer.connect("timeout", self, "on_specialReloadTimer_timeout")
	immuneTimer.connect("timeout", self, "on_immuneTimer_timeout")
	regenerationTimer.connect("timeout", self, "on_regenerationTimer_timeout")
	outsideOfMapKillerTimer.connect("timeout", self, "on_outsideOfMapKillerTimer_timeout")

	emit_signal("submarine_respawn")

func _draw():	
	if Global.GAMEMODE == Global.gamemodes.TEAMDEATHMATCH || Global.GAMEMODE == Global.gamemodes.CTF:
		if is_in_group("USA_team"):
			if is_in_group("sm_std"):
				draw_arc(Vector2.ZERO, radius, 0, 2*PI, 16, Color(0, 1, 0), 1.3, true)
			elif is_in_group("sm_fst"):
				var VelVect = linear_velocity + Vector2(0, -0.0001) # add a little vector to prevent not drawing at null veloticy
				var vLeft = 1.2*radius*VelVect.normalized().rotated(-3*PI/4)
				var vLeftOff = 0.4*radius*VelVect.normalized().rotated(-PI/2)
				var vUp = 1.2*radius*VelVect.normalized()
				var vRightOff = 0.4*radius*VelVect.normalized().rotated(PI/2)
				var vRight = 1.2*radius*VelVect.normalized().rotated(3*PI/4)
				var tab = [vLeft, vLeftOff, vUp, vRightOff, vRight, vLeft] #vLeft is added for polyline to close the shape
				var vertexs = PoolVector2Array(tab)
				draw_polyline(vertexs, Color(0, 1, 0, 1), 1.3, true)
			elif is_in_group("sm_slw"):
				draw_rect(
					Rect2(Vector2(-radius, -radius), 2*Vector2(radius, radius)), Color(0, 1, 0), false, 1.3, true)
		
		elif is_in_group("USSR_team"):
			draw_circle(Vector2.ZERO, radius, Color(0, 1, 0))
	
	else:
		draw_circle(Vector2.ZERO, radius, Color(0, 1, 0))

func isDead()->bool:
	if life <= 0:
		return true
	return false

func fireTorpedoAt(targetPos:Vector2)->void:
	# deprecated
	# used for mouse position shoot; for debug
	
	if loadedWeapons > 0:
		emit_signal("torpedo_fired", position, targetPos + position)
		loadedWeapons -= 1

func fireWeapon()->void:
	# standard shoot
	if loadedWeapons > 0:
		emit_signal("torpedo_fired", position, aimingPoint + position, self)
		loadedWeapons -= 1
		reloadTimer.start()
	
		torpedoShootSound.play()
			

func fireSpe()->void:
	if loadedSpe == true:
		if is_in_group("sm_fst"):
			emit_signal("mine_dropped", position, self)
			loadedSpe = false
			specialReloadTimer.start()
			
			torpedoShootSound.play()
		
		elif is_in_group("sm_std"):
			emit_signal("guided_torpedo_fired", position, aimingPoint + position, self)
			loadedSpe = false
			specialReloadTimer.start()
			
			torpedoShootSound.play()
		
		elif is_in_group("sm_slw"):
			emit_signal("laser_fired", position, aimingPoint + position, self)
			loadedSpe = false
			specialReloadTimer.start()
			
			torpedoShootSound.play()
		
		emit_signal("spe_no_longer_available")


func on_reloadTimer_timeout()->void:
	if loadedWeapons < max_loadedWeapons:
		loadedWeapons += 1
	if loadedWeapons == max_loadedWeapons:
		# doesn't need reload anymore until next shoot
		# timer will start on next shoot
		reloadTimer.stop()

func on_specialReloadTimer_timeout()->void:
	if loadedSpe == false:
		loadedSpe = true
		emit_signal("spe_available")
	if loadedSpe == true:
		# doesn't need reload anymore until next shoot
		# timer will start on next shoot
		specialReloadTimer.stop()

func on_immuneTimer_timeout()->void:
	immune = false

func on_regenerationTimer_timeout()->void:
	if life < max_life:
		life += 1

func on_outsideOfMapKillerTimer_timeout()->void:
	# not optimized, maybe use an Area2D as map boundaries instead
	if position.length() > Map.radius:
		takeDamage(self, null, 10)

func _process(_delta):
	#submarine manages his own destruction from the world
	engineSound.pitch_scale = 0.9 + 0.01 * linear_velocity.length()
	
	
	

func updateDisplay()->void:
	#function called as the default subMarine
	if linear_velocity.length() > max_undetectable_vel:
		visible = true
	else:
		visible = false

func takeDamage(source:SubMarine, sourceweapon:Torpedo, damage)->void:
	lastDamageSource = source
	weaponDamageSource = sourceweapon
	if !immune:
		life -= damage
	
	if life > 0: # we need to emit a global sound because childsound will be deleted on die
		torpedoHitSound.play()
	
	if life <= 0:
		var lastDamageSourceGr = "nullGroup"
		if lastDamageSource.is_in_group("USA_team"):
			lastDamageSourceGr = "USA_team"
		elif lastDamageSource.is_in_group("USSR_team"):
			lastDamageSourceGr = "USSR_team"
		
		var selfGroup = "nullGroup"
		if is_in_group("USA_team"):
			selfGroup = "USA_team"
		elif is_in_group("USSR_team"):
			selfGroup = "USSR_team"
		
		# for logging kills:
		emit_signal("killed", lastDamageSource.name, lastDamageSourceGr, name, selfGroup)
		if is_in_group("USA_team"):
			emit_signal("submarine_dead", index, "USA_team", get_type_str())
		elif is_in_group("USSR_team"):
			emit_signal("submarine_dead", index, "USSR_team", get_type_str())
	
		Sound.get_node("torpedoHitInside").play()
		Sound.get_node("torpedoHitInside").position = position
		queue_free()


func get_type_str()->String:
	var strType = ""
	if is_in_group("sm_std"):
		strType = "sm_std"
	elif is_in_group("sm_fst"):
		strType = "sm_fst"
	elif is_in_group("sm_slw"):
		strType = "sm_slw"
	
	return strType
