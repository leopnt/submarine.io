# need to be in a canvasLayer with follow_viewport disabled
# this is easier to position ui on screen
# so origin is top-left corner in this class

extends Control
class_name UI

var pixelFont:DynamicFont
var pixelFont_big:DynamicFont
var velocityTextPos:Vector2

var mainWorld # ui can access everything in main

var topoGraphArr:Array
const graphRange:float = 20.0 # seconds
var graphPlotTimer:Timer
const refreshRate:float = 0.5 # seconds
var graphOriginPos:Vector2

var pauseMenu:PauseMenu
var endGameUI:EndGameUI

var show_respawn_info:bool
var playerDead:bool

const darker_screen_alpha:float = 0.5

func _init(mainReference):
	pause_mode = Node.PAUSE_MODE_PROCESS # ui will get inputs no matter what (paused game or not)
	set_anchors_preset(Control.PRESET_WIDE)
	
	mainWorld = mainReference
	
	pixelFont = DynamicFont.new()
	pixelFont.font_data = load("res://fonts/PressStart2P-Regular.ttf")
	pixelFont.size = 8

	pixelFont_big = DynamicFont.new()
	pixelFont_big.font_data = load("res://fonts/PressStart2P-Regular.ttf")
	pixelFont_big.size = 16

	velocityTextPos = Vector2(3*pixelFont.size, 3*pixelFont.size)
	
	graphPlotTimer = Timer.new()
	graphPlotTimer.wait_time = refreshRate # seconds
	graphPlotTimer.autostart = true # because sm fully loaded at start. it will start when shoot occures
	add_child(graphPlotTimer)
	
	
	endGameUI = load("res://scenes/endGameUI.tscn").instance()
	endGameUI.visible = false
	add_child(endGameUI)
	endGameUI.connect("reload_pressed", self, "on_reload_pressed")
	
	# pause menu have priority on all other menus so it has to be added last
	pauseMenu = load("res://scenes/pause-menu.tscn").instance()
	pauseMenu.visible = false # menu is hidden by default
	add_child(pauseMenu)
	pauseMenu.connect("resume_pressed", self, "on_resume_pressed")
	
	
	show_respawn_info = false
	
func _ready():
	graphPlotTimer.connect("timeout", self, "on_graphPlotTImer_timeout")

	graphOriginPos = Vector2(velocityTextPos.x, get_viewport_rect().size.y - velocityTextPos.y)
	var firstArrayValue = Vector2(velocityTextPos.x, graphOriginPos.y)
	for _i in range(graphRange):
		topoGraphArr.append(firstArrayValue)

func _process(_delta):
	update()

func _draw():
	var strToShow = null # initialize
	var strSize = null
	
	# always drawn watever happens:
	# USA team
	if Global.GAMEMODE == Global.gamemodes.TEAMDEATHMATCH || Global.GAMEMODE == Global.gamemodes.CTF:
		strToShow = "%2d" % mainWorld.teamsScore["USA_score"]
		strSize = pixelFont_big.get_string_size(strToShow)
		draw_string(
			pixelFont_big,
			Vector2(velocityTextPos.x + int(get_viewport_rect().size.x/4) - 3 * strSize.x, velocityTextPos.y + strSize.y/2),
			"USA: " + strToShow,
			Color(0, 255, 0, 1)
			)
		
		# USSR team
		strToShow = "%2d" % mainWorld.teamsScore["USSR_score"]
		strSize = pixelFont_big.get_string_size(strToShow)
		draw_string(
			pixelFont_big,
			Vector2(velocityTextPos.x + int(3*get_viewport_rect().size.x/4) - strSize.x/2, velocityTextPos.y + strSize.y/2),
			"USSR: " + strToShow,
			Color(0, 255, 0, 1)
			)
	else:
		strToShow = "%2d" % mainWorld.killCountLog["player"]["kills"]
		strSize = pixelFont_big.get_string_size(strToShow)
		draw_string(
			pixelFont_big,
			Vector2(velocityTextPos.x + int(3*get_viewport_rect().size.x/4) - strSize.x/2, velocityTextPos.y + strSize.y/2),
			"Kills: " + strToShow,
			Color(0, 255, 0, 1)
		)
	
	# show game time
	var minutes = int(round(mainWorld.gameTimer.time_left) / 60 )
	var seconds = int(round(mainWorld.gameTimer.time_left)) % 60
	strToShow = "%02d:%02d" % [minutes, seconds]
	strSize = pixelFont_big.get_string_size(strToShow)
	draw_string(
		pixelFont_big,
		get_viewport_rect().size - velocityTextPos - Vector2(strSize.x, 0),
		strToShow,
		Color(0, 255, 0, 1)
		)
	
	# depends on player in scene:
	if !playerDead:
		strToShow = "%2d" % round(mainWorld.player.linear_velocity.length())
		draw_string(
			pixelFont,
			velocityTextPos,
			#"v = " + str(round(mainWorld.player.linear_velocity.length())) + "%2d s" %2,
			"v:  " + strToShow + "k",
			Color(0, 255, 0, 1)
			)
		
		# number of ammunitions
		draw_string(
			pixelFont,
			velocityTextPos + Vector2(0, 2 * pixelFont.size),
			"η:   " + str(mainWorld.player.loadedWeapons),
			Color(0, 255, 0, 1)
			)
		
		# remaining reload time
		strToShow = "%2d" % round(mainWorld.player.reloadTimer.time_left)
		draw_string(
			pixelFont,
			velocityTextPos + Vector2(0, 4 * pixelFont.size),
			"τ:  " + strToShow + "s",
			Color(0, 255, 0, 1)
			)
		
		# remaining spe reload time
		strToShow = "%2d" % round(mainWorld.player.specialReloadTimer.time_left)
		draw_string(
			pixelFont,
			velocityTextPos + Vector2(0, 6 * pixelFont.size),
			"μ:  " + strToShow + "s",
			Color(0, 255, 0, 1)
			)
		
		# altitude
		strToShow = "%3d" % round(mainWorld.terrain.getHeightAt(mainWorld.player.position))
		draw_string(
			pixelFont,
			velocityTextPos + Vector2(0, 8 * pixelFont.size),
			"λ: " + strToShow + "m",
			Color(0, 255, 0, 1)
			)
		
		
		# spe cooldown timer
		strToShow = "μ ["
		# get maximum length
		for _i in range(SubMarine.coolDownTime):
			strToShow += "|"
		strToShow += "]: reload"
		strSize = pixelFont.get_string_size(strToShow).x
		# apply drawing
		strToShow = "μ ["
		for _i in range(round(map(mainWorld.player.specialReloadTimer.time_left, 0, SubMarine.specialCoolDownTime, 0, SubMarine.coolDownTime))):
			strToShow += "|"
		for _i in range(SubMarine.coolDownTime - round(map(mainWorld.player.specialReloadTimer.time_left, 0, SubMarine.specialCoolDownTime, 0, SubMarine.coolDownTime))):
			strToShow += " "
		draw_string(
				pixelFont,
				Vector2(get_viewport_rect().size.x / 2 - strSize / 2, velocityTextPos.y),
				strToShow + "]: reload spe",
				Color(0, 255, 0, 1)
				)
		
		# cooldown timer
		strToShow = "τ ["
		# get maximum length
		for _i in range(SubMarine.coolDownTime):
			strToShow += "."
		strToShow += "]: reload"
		strSize = pixelFont.get_string_size(strToShow).x
		# apply drawing
		strToShow = "τ ["
		for _i in range(round(mainWorld.player.reloadTimer.time_left)):
			strToShow += "."
		for _i in range(SubMarine.coolDownTime - round(mainWorld.player.reloadTimer.time_left)):
			strToShow += " "
		draw_string(
				pixelFont,
				Vector2(get_viewport_rect().size.x / 2 - strSize / 2, 2 * velocityTextPos.y),
				strToShow + "]: reload",
				Color(0, 255, 0, 1)
				)
				
				
		# life
		strToShow = "Λl ["
		# get maximum length
		for _i in range(15):
			strToShow += "."
		strToShow += "]: struct"
		strSize = pixelFont.get_string_size(strToShow).x
		strToShow = "Λl ["
		# apply drawing
		var mappedLife = round(Global.map(mainWorld.player.life, 0, mainWorld.player.max_life, 0, 15))
		for _i in range(mappedLife):
			strToShow += "#"
		for _i in range(15 - mappedLife):
			strToShow += " "
		draw_string(
				pixelFont,
				Vector2(get_viewport_rect().size.x / 2 - strSize / 2, get_viewport_rect().size.y - velocityTextPos.y),
				strToShow + "]: struct",
				Color(0, 255, 0, 1)
				)
		
		# draw graph
		draw_line(Vector2(velocityTextPos.x, get_viewport_rect().size.y - velocityTextPos.y), Vector2(velocityTextPos.x, get_viewport_rect().size.y - velocityTextPos.y) + Vector2(0, -50), Color(0, 1, 0))
		draw_line(Vector2(velocityTextPos.x, get_viewport_rect().size.y - velocityTextPos.y), Vector2(velocityTextPos.x, get_viewport_rect().size.y - velocityTextPos.y) + Vector2(100, 0), Color(0, 1, 0))
		if topoGraphArr.size() >= 2:
			draw_polyline(PoolVector2Array(topoGraphArr), Color(0, 1, 0), 1, true)
	
	# depends on show screen
	if show_respawn_info:
		# darker background:
		draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0, 0, 0, darker_screen_alpha))
		
		# text:
		var strToShowResp = "Respawn in " + str(round(mainWorld.respawnTimer.time_left))
		var strSizeResp = pixelFont_big.get_string_size(strToShowResp)
		draw_string(
			pixelFont_big,
			Vector2(get_viewport_rect().size.x / 2 - strSizeResp.x / 2, get_viewport_rect().size.y / 2 - strSizeResp.y /2),
			strToShowResp,
			Color(0, 255, 0, 1)
			)
	

func on_graphPlotTImer_timeout()->void:
	if !show_respawn_info:
		graphOriginPos = Vector2(velocityTextPos.x, get_viewport_rect().size.y - velocityTextPos.y)
		topoGraphArr.append(Vector2(0, -map(mainWorld.terrain.getHeightAt(mainWorld.player.position), 0, 300, 0, 50) + graphOriginPos.y))
		# arrange vectors for plotting
		for i in range(topoGraphArr.size()):
			topoGraphArr[i].x = i * graphRange/(graphRange/(10*refreshRate)) + graphOriginPos.x
		
		
		# remove to get constant size
		if topoGraphArr.size() >= graphRange:
			topoGraphArr.pop_front()

func map(value:float, istart:float, istop:float, ostart:float, ostop:float)->float:
	return ostart + (ostop - ostart) * ((value - istart) / (istop - istart))
	
func _input(event):
	if event.is_action_pressed("ui_pause") && !pauseMenu.visible:
		apply_pause()
		
	elif event.is_action_pressed("ui_pause") || event.is_action_pressed("ui_cancel") && pauseMenu.visible:
		_apply_resume()

func apply_pause()->void:
	get_tree().paused = true
	pauseMenu.show()
	Sound.get_node("buttonClick").play()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _apply_resume()->void:
	on_resume_pressed()
	Sound.get_node("buttonClick").play()
	if !OS.has_touchscreen_ui_hint():
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func on_player_dead()->void:
	if mainWorld.respawnTimer.is_inside_tree(): # prevents call when closing the main scene
		mainWorld.respawnTimer.start()
		mainWorld.get_node("RespawnCamera").current = true
		show_respawn_info = true
		playerDead = true

func on_player_respawn()->void:
	mainWorld.get_node("RespawnCamera").current = false
	playerDead = false
	show_respawn_info = false

func on_resume_pressed()->void:
	if !OS.has_touchscreen_ui_hint():
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Sound.get_node("buttonClick").play()
	
	if !endGameUI.visible:
		get_tree().paused = false
	
	pauseMenu.hide()

func on_reload_pressed()->void:
	Sound.get_node("buttonClick").play()
	
	get_tree().paused = false
	get_tree().reload_current_scene()

func on_gameTimer_timeout()->void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	
	if Global.GAMEMODE == Global.gamemodes.TEAMDEATHMATCH || Global.GAMEMODE == Global.gamemodes.CTF:
		if mainWorld.teamsScore["USSR_score"] > mainWorld.teamsScore["USA_score"]:
			endGameUI.get_node("VBoxContainer/VBoxContainer/LabelMain").text = "USSR team won"
		elif mainWorld.teamsScore["USSR_score"] < mainWorld.teamsScore["USA_score"]:
			endGameUI.get_node("VBoxContainer/VBoxContainer/LabelMain").text = "USA team won"
		else:
			endGameUI.get_node("VBoxContainer/VBoxContainer/LabelMain").text = "Draw"
	else:
		var playerKills = mainWorld.killCountLog["player"]["kills"]
		
		var playerDeaths = mainWorld.killCountLog["player"]["deaths"]
		if playerDeaths > 0: # to avoid zero division
			playerDeaths = mainWorld.killCountLog["player"]["deaths"]
		else:
			playerDeaths = 1
			
		var ratio = float(playerKills) / float(playerDeaths)
		endGameUI.get_node("VBoxContainer/VBoxContainer/LabelMain").text = "Kills: " + str(playerKills) + " Deaths: " + str(playerDeaths) + " K/D: " + str(ratio)
	
	# show players and bot individual logs:
	var logTab = []
	for sm_key in mainWorld.killCountLog.keys():
		# --- this is made only for ratio calculations ---
		# don't use those variable as is as they may not be relevant
		var smKills = mainWorld.killCountLog[sm_key]["kills"]
		var smDeaths = mainWorld.killCountLog[sm_key]["deaths"]
		if smDeaths > 0: # to avoid zero division
			smDeaths = mainWorld.killCountLog[sm_key]["deaths"]
		else:
			smDeaths = 1
		# --- this is made only for ratio calculations ---
		var ratio = float(smKills) / float(smDeaths)
		
		# --- individual score logic ---
		var customScore = 100 * (2 * mainWorld.killCountLog[sm_key]["kills"] - mainWorld.killCountLog[sm_key]["deaths"] - 2 * mainWorld.killCountLog[sm_key]["team-kills"])
		
		logTab.append([sm_key, customScore, mainWorld.killCountLog[sm_key]["kills"], mainWorld.killCountLog[sm_key]["deaths"], stepify(ratio, 0.01), mainWorld.killCountLog[sm_key]["team-kills"]])

		if sm_key == "player" && customScore > 0:
			Global.generalScore += customScore
			Global.save_data()
		

	logTab.sort_custom(MyCustomSorter, "sort_descending")
	set_result(logTab, endGameUI.get_node("VBoxContainer/RichTextLabel"))
	endGameUI.show()



class MyCustomSorter:
	static func sort_descending(a, b):
		if a[1] > b[1]:
			return true
		return false


func set_result(rows: Array, rtl:RichTextLabel) -> void:
	var header = ["name", "score", "kills", "deaths", "k/d", "teamkills"]
	
	rtl.append_bbcode("[center]")
	rtl.push_table(header.size())
	for key in header: # Add table headers
		rtl.push_cell()
		rtl.push_align(RichTextLabel.ALIGN_CENTER)
		rtl.push_underline()
		rtl.add_text(key)
		rtl.pop()
		rtl.pop()
		rtl.pop()
	
	for row in rows: # Add table values
		for val in row:
			rtl.push_cell()
			rtl.push_align(RichTextLabel.ALIGN_CENTER)
			rtl.add_text(str(val))
			rtl.pop()
			rtl.pop()
	rtl.pop()
	rtl.newline()
	rtl.newline()
