extends Control

var terrain:Terrain
var player:Player

var ui:UI # ui is also managing game pause/state
var map:Map

const EXPLPARTICLE = preload("res://classes/explParticles.tscn")

var gameTimer:Timer
var gametime = Global.GAMETIME * 60

var respawnTimer:Timer
export var respawnCoolDown:float = 10.0 # seconds



var nb_of_ussr_ai:int = 6
var nb_of_usa_ai:int =  5 # + player
var ussrAIs:Array
var usaAIs:Array

var ussrAITimers:Array
var usaAITimers:Array

var teamsScore:Dictionary
var killCountLog:Dictionary

var strGameLog:String


# --- virtual smartphone var ---
onready var vJoyMove:Joystick = get_node("UI_layer/JoystickMove")
onready var vJoyAim:Joystick = get_node("UI_layer/JoystickAim")
onready var vJoySpe:Joystick = get_node("UI_layer/JoystickSpe")
onready var vPauseButton:Button = get_node("touchPauseButtonLayer/Button")


func _ready():
	if !Global.touchControls:
		vPauseButton.visible = false
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	randomize() # set a different seed each time

	terrain = Terrain.new() #terrain should be added after player
	$Terrain_layer.add_child(terrain)

	map = Map.new()
	$main_layer.add_child(map)

	
	if Global.GAMEMODE == Global.gamemodes.CTF:
		for i in range(3):
			var flag = Flag.new(Vector2(-250 + i * 250, 0)) #    *    *    * centered
			add_child(flag)
			flag.add_to_group("flags")
			flag.connect("flag_owned", self, "on_flag_owned")
	
	# --- add ussr ---
	if !Global.GAMEMODE == Global.gamemodes.DEATHMATCH: # there is only one general group in Battleroyal
		for _i in range(nb_of_ussr_ai):
			ussrAIs.append(AiSubMarine.new()) # instantiate array
	else:
		nb_of_usa_ai *= 2
	
	for i in range(ussrAIs.size()):
		add_ai_to_scene(i, "USSR_team", "bot_ussr", get_random_type_str())
		
		var aiRespawnTimer = AITimer.new(i, "USSR_team")
		aiRespawnTimer.wait_time = respawnCoolDown
		aiRespawnTimer.one_shot = true
		ussrAITimers.append(aiRespawnTimer)
		add_child(aiRespawnTimer)
		aiRespawnTimer.connect("custom_timeout", self, "on_aiRespawnTimer_timeout")
	
	# --- add usa ---
	for _i in range(nb_of_usa_ai):
		usaAIs.append(AiSubMarine.new()) # instantiate array
	
	for i in range(usaAIs.size()):
		add_ai_to_scene(i, "USA_team", "bot_usa", get_random_type_str())
		
		var aiRespawnTimer = AITimer.new(i, "USA_team")
		aiRespawnTimer.wait_time = respawnCoolDown
		aiRespawnTimer.one_shot = true
		usaAITimers.append(aiRespawnTimer)
		add_child(aiRespawnTimer)
		aiRespawnTimer.connect("custom_timeout", self, "on_aiRespawnTimer_timeout")
	
	ui = UI.new(self)
	$UI_layer.add_child(ui)
	vPauseButton.connect("pressed", ui, "apply_pause")
	
	
	add_player_to_scene()
	
	respawnTimer = Timer.new()
	respawnTimer.wait_time = respawnCoolDown # seconds
	respawnTimer.one_shot = true
	respawnTimer.connect("timeout", self, "on_respawnTimer_timeout")
	add_child(respawnTimer)
	
	# initialize dictionnary keys:
	# after as they depend  on specific setted variable before
	for sm in get_tree().get_nodes_in_group("USSR_team"):
		killCountLog[sm.name] = {}
		killCountLog[sm.name]["kills"] = 0
		killCountLog[sm.name]["team-kills"] = 0
		killCountLog[sm.name]["deaths"] = 0
	for sm in get_tree().get_nodes_in_group("USA_team"):
		killCountLog[sm.name] = {}
		killCountLog[sm.name]["kills"] = 0
		killCountLog[sm.name]["team-kills"] = 0
		killCountLog[sm.name]["deaths"] = 0
	
	teamsScore["USSR_score"] = 0
	teamsScore["USA_score"] = 0
	
	gameTimer = Timer.new()
	gameTimer.wait_time = gametime
	gameTimer.autostart = true
	gameTimer.one_shot = true
	gameTimer.connect("timeout", ui, "on_gameTimer_timeout")
	add_child(gameTimer)	


func on_torpedo_fired(fromPos, targetPos, emitter)->void:
	var torpedo = Torpedo.new(fromPos, targetPos, emitter)
	$main_layer.add_child(torpedo)
	torpedo.connect("torpedo_hit", self, "on_weapon_hit")
	torpedo.add_to_group("worldTorpedos")


func on_guided_torpedo_fired(fromPos, targetPos, emitter)->void:	
	var guidedTorp = GuidedTorpedo.new(fromPos, targetPos, emitter)
	$main_layer.add_child(guidedTorp)
	guidedTorp.connect("torpedo_hit", self, "on_weapon_hit")
	guidedTorp.add_to_group("worldTorpedos")


func on_mine_dropped(fromPos, emitter)->void:
	var mine = Mine.new(fromPos, emitter)
	$main_layer.add_child(mine)
	mine.connect("mine_hit", self, "on_weapon_hit")
	mine.add_to_group("worldMines")


func on_laser_fired(fromPos, targetPos, emitter)->void:
	var laser = Laser.new(fromPos, targetPos, emitter)
	$main_layer.add_child(laser)
	laser.connect("laser_hit", self, "on_weapon_hit")
	laser.add_to_group("worldLasers")


func on_weapon_hit(weaponEmitter:SubMarine, touchedBody:SubMarine, _weapon:Weapon, explPosition:Vector2)->void:
	var explParticle = EXPLPARTICLE.instance()
	explParticle.position = explPosition
	$main_layer.add_child(explParticle)
	
	if touchedBody == player:
		get_node("CRTeffect_layer/CRT_texture").startDamageAnimation()
		Controller.vibrate(1.0, 1.0, 0.5)
	
	print(weaponEmitter.name + " hit -> " + touchedBody.name)

func on_submarine_killed(killedSubDamageSourceName:String, killedSubDamageSourceGroup:String, killedSubName:String, killedSubGroup:String):
	# to avoid crash if player dies of something else (eg outside map) before getting hit
	if Global.GAMEMODE == Global.gamemodes.TEAMDEATHMATCH || Global.GAMEMODE == Global.gamemodes.CTF:
		if killedSubGroup == "USA_team" and killedSubDamageSourceGroup == "USA_team":
			# this is a team kill, score added to other team
			killCountLog[killedSubDamageSourceName]["team-kills"] += 1
			teamsScore["USSR_score"] += 1
		elif killedSubGroup == "USA_team" and killedSubDamageSourceGroup == "USSR_team":
			# this is a USSR kill
			killCountLog[killedSubDamageSourceName]["kills"] += 1
			teamsScore["USSR_score"] += 1
		elif killedSubGroup == "USSR_team" and killedSubDamageSourceGroup == "USSR_team":
			# this is a team kill, score added to other team
			killCountLog[killedSubDamageSourceName]["team-kills"] += 1
			teamsScore["USA_score"] += 1
		elif killedSubGroup == "USSR_team" and killedSubDamageSourceGroup == "USA_team":
			# this is a USA kill
			killCountLog[killedSubDamageSourceName]["kills"] += 1
			teamsScore["USA_score"] += 1
			
	else:
		killCountLog[killedSubDamageSourceName]["kills"] += 1
		
	print(killedSubDamageSourceName +  " killed " + killedSubName)
	strGameLog += (killedSubDamageSourceName +  " killed " + killedSubName + "\n")
	
	# individual log:
	killCountLog[killedSubName]["deaths"] += 1
	
	"""
	if killedsub.lastDamageSource != null: # to avoid crash if player dies of something else (eg outside map) before getting hit
		if Global.GAMEMODE == Global.gamemodes.TEAMDEATHMATCH || Global.GAMEMODE == Global.gamemodes.CTF:
			if killedsub.is_in_group("USA_team") and killedsub.lastDamageSource.is_in_group("USA_team"):
				# this is a team kill, score added to other team
				killCountLog[killedsub.lastDamageSource.name]["team-kills"] += 1
				teamsScore["USSR_score"] += 1
			elif killedsub.is_in_group("USA_team") and killedsub.lastDamageSource.is_in_group("USSR_team"):
				# this is a USSR kill
				killCountLog[killedsub.lastDamageSource.name]["kills"] += 1
				teamsScore["USSR_score"] += 1
			elif killedsub.is_in_group("USSR_team") and killedsub.lastDamageSource.is_in_group("USSR_team"):
				# this is a team kill, score added to other team
				killCountLog[killedsub.lastDamageSource.name]["team-kills"] += 1
				teamsScore["USA_score"] += 1
			elif killedsub.is_in_group("USSR_team") and killedsub.lastDamageSource.is_in_group("USA_team"):
				# this is a USA kill
				killCountLog[killedsub.lastDamageSource.name]["kills"] += 1
				teamsScore["USA_score"] += 1
			
		else:
			killCountLog[killedsub.lastDamageSource.name]["kills"] += 1
		
		print(killedsub.lastDamageSource.name +  " killed " + killedsub.name)
		strGameLog += (killedsub.lastDamageSource.name +  " killed " + killedsub.name + "\n")
	
	# individual log:
	killCountLog[killedsub.name]["deaths"] += 1
	"""

func on_respawnTimer_timeout()->void:
	add_player_to_scene()

func on_aiRespawnTimer_timeout(index, team, typeStr)->void:
	if team == "USA_team":
		add_ai_to_scene(index, team, "bot_usa", typeStr)
	elif team == "USSR_team":
		add_ai_to_scene(index, team, "bot_ussr", typeStr)
		
	"""
	for i in range(ussrAIs.size()):
		if ussrAIs[i] == null:
			add_ai_to_scene(i, "USSR_team", "bot_ussr")
	
	for i in range(usaAIs.size()):
		if usaAIs[i] == null:
			add_ai_to_scene(i, "USA_team", "bot_usa")
	"""

func add_player_to_scene()->void:
	player = Player.new()
	match Global.playerGameType:
		Global.smTypes.std:
			player.add_to_group("sm_std")
		Global.smTypes.fst:
			player.add_to_group("sm_fst")
		Global.smTypes.slw:
			player.add_to_group("sm_slw")
			
	player.initTypeVar()
	player.name = "player"
	
	if Global.GAMEMODE == Global.gamemodes.DEATHMATCH:
		var randAngle = rand_range(0, 2*PI)
		var radius = rand_range(Map.radius - 600, Map.radius - 10)
		player.position = radius * Vector2.UP.rotated(randAngle)
	else:
		player.position = Vector2(int(rand_range(-400, 400)), int(rand_range(400, 450)))
		
	player.add_to_group("USA_team")
	player.connect("torpedo_fired", self, "on_torpedo_fired")
	player.connect("guided_torpedo_fired", self, "on_guided_torpedo_fired")
	player.connect("mine_dropped", self, "on_mine_dropped")
	player.connect("laser_fired", self, "on_laser_fired")
	player.connect("player_dead", ui, "on_player_dead")
	player.connect("player_respawn", ui, "on_player_respawn")
	player.connect("killed", self, "on_submarine_killed")
	player.connect("spe_available", self, "on_player_spe_available")
	player.connect("spe_no_longer_available", self, "on_player_spe_no_longer_available")
	get_node("CRTeffect_layer/CRT_texture").connect("crt_rect_changed", player, "update_zoom")
	
	$main_layer.add_child(player)


func get_random_type_str()->String:
	var randomType = round(rand_range(0, 2))
	var typeStr = ""
	if randomType == Global.smTypes.std:
		typeStr = "sm_std"
	elif randomType == Global.smTypes.fst:
		typeStr = "sm_fst"
	elif randomType == Global.smTypes.slw:
		typeStr = "sm_slw"
	
	return typeStr

func add_ai_to_scene(index:int, team:String, baseName:String, typeStr:String):
	
	if team == "USA_team":
		usaAIs[index] = AiSubMarine.new()
		usaAIs[index].add_to_group(typeStr)
		usaAIs[index].initTypeVar()
		usaAIs[index].name = baseName + str(index)
		usaAIs[index].index = index
		
		if Global.GAMEMODE == Global.gamemodes.DEATHMATCH:
			var randAngle = rand_range(0, 2*PI)
			var radius = rand_range(Map.radius - 600, Map.radius - 10)
			usaAIs[index].position = radius * Vector2.UP.rotated(randAngle)
		else:
			usaAIs[index].position = Vector2(int(rand_range(-400, 400)), int(rand_range(400, 450)))
		
		$main_layer.add_child(usaAIs[index])
		usaAIs[index].add_to_group(team)
		usaAIs[index].connect("torpedo_fired", self, "on_torpedo_fired")
		usaAIs[index].connect("guided_torpedo_fired", self, "on_guided_torpedo_fired")
		usaAIs[index].connect("mine_dropped", self, "on_mine_dropped")
		usaAIs[index].connect("laser_fired", self, "on_laser_fired")
		usaAIs[index].connect("submarine_dead", self, "on_submarine_dead")
		usaAIs[index].connect("submarine_respawn", self, "on_submarine_respawn")
		usaAIs[index].connect("killed", self, "on_submarine_killed")
	
	
	else:
		ussrAIs[index] = AiSubMarine.new()
		ussrAIs[index].add_to_group(typeStr)
		ussrAIs[index].initTypeVar()
		ussrAIs[index].name = baseName + str(index)
		ussrAIs[index].index = index
		
		if Global.GAMEMODE == Global.gamemodes.DEATHMATCH:
			var randAngle = rand_range(0, 2*PI)
			var radius = rand_range(Map.radius - 200, Map.radius - 10)
			ussrAIs[index].position = radius * Vector2.UP.rotated(randAngle)
		else:
			ussrAIs[index].position = Vector2(int(rand_range(-400, 400)), int(rand_range(-400, -450)))
		
		$main_layer.add_child(ussrAIs[index])
		ussrAIs[index].add_to_group(team)
		ussrAIs[index].connect("torpedo_fired", self, "on_torpedo_fired")
		ussrAIs[index].connect("guided_torpedo_fired", self, "on_guided_torpedo_fired")
		ussrAIs[index].connect("mine_dropped", self, "on_mine_dropped")
		ussrAIs[index].connect("laser_fired", self, "on_laser_fired")
		ussrAIs[index].connect("submarine_dead", self, "on_submarine_dead")
		ussrAIs[index].connect("submarine_respawn", self, "on_submarine_respawn")
		ussrAIs[index].connect("killed", self, "on_submarine_killed")
		

func on_submarine_dead(index, team, typeStr)->void:
	if team == "USA_team":
		usaAITimers[index].typeStr = typeStr
		usaAITimers[index].start()
	elif team == "USSR_team":
		ussrAITimers[index].typeStr = typeStr
		ussrAITimers[index].start()
	
func on_submarine_respawn()->void:
	pass

func on_flag_owned(flagOwner:SubMarine)->void:
	if flagOwner.is_in_group("USA_team"):
		teamsScore["USA_score"] += 1
		if teamsScore["USSR_score"] > 0:
			teamsScore["USSR_score"] -= 1
	elif flagOwner.is_in_group("USSR_team"):
		teamsScore["USSR_score"] += 1
		if teamsScore["USA_score"] > 0:
			teamsScore["USA_score"] -= 1


func on_player_spe_available()->void:
	if Global.touchControls:
		vJoySpe.visible = true

func on_player_spe_no_longer_available()->void:
	vJoySpe.visible = false
