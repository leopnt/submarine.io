extends Node

enum smTypes {std = 0, fst = 1, slw = 2}
enum smTypesUnlockScore {std = 0, fst = 3000, slw = 9000}
var unlockedTypes:Array = [0]
var generalScore = 0
var playerGameType = smTypes.std

enum gamemodes {TEAMDEATHMATCH = 0, DEATHMATCH = 1, CTF = 2, BATTLEROYAL = 3}
var GAMEMODE = gamemodes.TEAMDEATHMATCH # default game mode
var GAMETIME = 6 # minutes

const settingsFilePath = "user://settings.cfg"
enum inputType {KEY = 0, JOYPAD_BUTTON = 1, JOYPAD_MOTION = 2}
const controlsFilePath:String = "user://controls.json"
const dataFilePath:String = "user://data.bin"

var platforms = {desktop = 0, mobile = 1, web = 2}
var platform = platforms.desktop

# --- settings var ---
# put default var when settings doesn't exists here
var scaledUI:bool = true # aspect setting
var TVeffect:bool = true
var touchControls:bool
var musicVolume:int = -6
var effectsVolume:int = 0
var powerSaver:bool = false

# 0 = isoline; 1 = shade
var terrainDisplay:int = 1


func _ready():
	print("loading settings from Global...")
	load_settings() # settings are loaded here to override default variables above before gui is loaded
	# not very efficient as it is loaded also in gui but works

func alert(text: String, title: String='Message') -> void:
	var scene_tree = Engine.get_main_loop()
	var dialog = AcceptDialog.new()
	dialog.modulate = Color(0.0, 1.0, 0.0, 1.0) # green color on popup
	dialog.theme = load("res://pixelPlanets/Theme.tres")
	dialog.dialog_text = text
	dialog.window_title = title
	dialog.connect('modal_closed', dialog, 'queue_free')
	scene_tree.current_scene.add_child(dialog)
	dialog.popup_centered_clamped(Vector2(OS.window_size.x, 100), 0.75)


func toStringType(smType)->String:
	match smType:
		smTypes.std:
			return "std"
		smTypes.fst:
			return "fst"
		smTypes.slw:
			return "slw"
	
	return "Unknown smType"


func getSmTypeUnlockScore(smType)->int:
	match smType:
		smTypes.std:
			return smTypesUnlockScore.std
		smTypes.fst:
			return smTypesUnlockScore.fst
		smTypes.slw:
			return smTypesUnlockScore.slw
	
	return -1

func updateUnlockedTypes()->void:
	var lastUnlockedTypes = unlockedTypes
	
	if generalScore >= smTypesUnlockScore.fst:
		unlockedTypes = [0, 1]
	if generalScore >= smTypesUnlockScore.slw:
		unlockedTypes = [0, 1, 2]
	
	if lastUnlockedTypes.size() < unlockedTypes.size():
		if unlockedTypes.size() == 2:
			alert("FST is now available", "Submarine unlocked!")
		if unlockedTypes.size() == 3:
			alert("SLW is now available", "Submarine unlocked!")

		save_data() # save the new unlocktypes so that notification doesn't show every time


func save_data():
	var f = File.new()
	f.open(dataFilePath, File.WRITE)
	f.store_var(generalScore)
	f.store_var(unlockedTypes)
	f.store_var(playerGameType)
	f.close()


func load_data():
	var f = File.new()
	if f.file_exists(dataFilePath):
		f.open(dataFilePath, File.READ)
		generalScore = f.get_var()
		unlockedTypes = f.get_var()
		playerGameType = f.get_var()
		f.close()
		print(dataFilePath + " loaded successfully")
	else:
		print(dataFilePath + " doesn't exists")


func save_settings():
	var config = ConfigFile.new()
	var err = config.load(settingsFilePath)
	if err == OK: # If not, something went wrong with the file loading
		config.set_value("display", "fullscreen", OS.window_fullscreen)
		config.set_value("display", "touchControls", touchControls)
		config.set_value("display", "scaledUI", scaledUI)
		config.set_value("display", "terrainDisplay", terrainDisplay)
		config.set_value("display", "TVeffect", TVeffect)
		config.set_value("performance", "powerSaver", powerSaver)
		config.set_value("audio", "musicVolume", musicVolume)
		config.set_value("audio", "effectsVolume", effectsVolume)
		# Save the changes by overwriting the previous file
		
		config.save(settingsFilePath)
		print(settingsFilePath + " loaded successfully")
		
	else:
		print("Error opening ", settingsFilePath, ". File inexistant, corrupted data or wrong code variable name")

func load_settings():	
	var config = ConfigFile.new()
	var err = config.load(settingsFilePath)
	if err == OK: # If not, something went wrong with the file loading
		OS.window_fullscreen = config.get_value("display", "fullscreen", false)
		touchControls = config.get_value("display", "touchControls", OS.has_touchscreen_ui_hint())
		scaledUI = config.get_value("display", "scaledUI", scaledUI)
		if scaledUI:
			get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D,  SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1024, 600))
		else:
			get_tree().set_screen_stretch(SceneTree.STRETCH_ASPECT_IGNORE,  SceneTree.STRETCH_ASPECT_IGNORE, Vector2(1024, 600))
		terrainDisplay = config.get_value("display", "terrainDisplay", terrainDisplay)
		TVeffect = config.get_value("display", "TVeffect", TVeffect)
		powerSaver = config.get_value("performance", "powerSaver", powerSaver)
		if powerSaver:
			Engine.set_target_fps(30)
			get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT,  SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1024, 600))
		musicVolume = config.get_value("audio", "musicVolume", musicVolume)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("MUSIC"), musicVolume)
		effectsVolume = config.get_value("audio", "effectsVolume", effectsVolume)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("EFFECTS"), effectsVolume)
		
		print(settingsFilePath + " loaded successfully")
	else:
		print("Error opening ", settingsFilePath, ". File inexistant, corrupted data or wrong code variable name")

	config.save(settingsFilePath)

func read_inputs():
	var file = File.new()
	if file.file_exists(controlsFilePath):
		file.open(controlsFilePath, File.READ)
		var result = parse_json(file.get_line())
		file.close()
		
		if typeof(result) == TYPE_DICTIONARY:
			if typeof(result[result.keys()[0]]) == TYPE_ARRAY:
				print(controlsFilePath + " loaded successfully")
			else:
				print("error opening " + controlsFilePath + " unexpected format")
		else:
			print("error opening " + controlsFilePath + " unexpected format")
		for action in result.keys():
			InputMap.action_erase_events(action)
			
			for i in range(result[action].size()):
				var event
				var type = i
				var id = i + 1
				
				if i % 2 == 0:
					if result[action][type] == inputType.KEY:
						event = InputEventKey.new()
						event.scancode = result[action][id]
					elif result[action][type] == inputType.JOYPAD_BUTTON:
						event = InputEventJoypadButton.new()
						event.button_index = result[action][id]
					elif result[action][type] == inputType.JOYPAD_MOTION:
						event = InputEventJoypadMotion.new()
						
						# see input saving for custom info
						# we need to save the minus information
						# but keep one number to save in the json
						# so custom numbers are necessary
						var customAxis = result[action][id]
						if customAxis < 0:
							event.axis = -(customAxis + 1000)
							event.axis_value = -1.0
						else:
							event.axis = customAxis
							event.axis_value = 1.0
							
					if !InputMap.has_action(action):
						InputMap.add_action(action)
					
					InputMap.action_add_event(action, event)
	else:
		print(controlsFilePath + " doesn't exists")


func map(value:float, istart:float, istop:float, ostart:float, ostop:float)->float:
	return ostart + (ostop - ostart) * ((value - istart) / (istop - istart))
