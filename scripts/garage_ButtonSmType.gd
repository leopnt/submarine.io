extends Button

export(Global.smTypes) var smType = Global.smTypes.std

func _ready():
	disabled = true
	if Global.unlockedTypes.has(smType):
		disabled = false

func _pressed():
	if Global.unlockedTypes.has(smType): # use has to avoid cheating (ui bypass in fact)
		Global.playerGameType = smType
