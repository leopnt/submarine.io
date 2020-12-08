extends TextureRect

signal crt_rect_changed # emited for camera player zoom to adapt

var endAnimationTimer:Timer
var playanimation = false
const initialModifier = 100.0
var shadermodifier:float

func _ready():
	endAnimationTimer = Timer.new()
	endAnimationTimer.wait_time = 0.5
	add_child(endAnimationTimer)
	endAnimationTimer.connect("timeout", self, "on_endAnimationTimer_timeout")
	visible = Global.TVeffect

func _process(_delta):
	if playanimation:
		shadermodifier = lerp(shadermodifier, 1.1, 0.2)
		var dir =  (randi() % 2) - (randi() % 2)
		material.set_shader_param("bleeding_range_x", dir * shadermodifier)
		dir =  (randi() % 2) - (randi() % 2)
		material.set_shader_param("bleeding_range_y", dir * shadermodifier)

func _on_CRT_texture_item_rect_changed():
	# when window is resized, the shader needs to be updated
	material.set_shader_param("screen_width", rect_size.x)
	material.set_shader_param("screen_height", rect_size.y)

	emit_signal("crt_rect_changed")

func on_endAnimationTimer_timeout()->void:
	playanimation = false
	endAnimationTimer.stop()
	# reset initial values
	material.set_shader_param("bleeding_range_x", 1.1)
	material.set_shader_param("bleeding_range_y", 1.1)

func startDamageAnimation()->void:
	shadermodifier = initialModifier
	endAnimationTimer.start()
	playanimation = true

