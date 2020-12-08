extends RigidBody2D
class_name Weapon

var damage = 50 # by default, changed by weapon type
var emitter
const initialEnergy:float = 17.0
var energy:Timer

var isEnabledVar:bool = false

#set the time after which the weapon will be enabled
#it means that after that it will explode with anything,
#even the player
var timetoenable:Timer


func _init(position_, emitter_):
	position = position_
	emitter = emitter_.duplicate() # make a copy in case the emitter dies before his torpedo touches an ennemy (it avoids null error)

	energy = Timer.new()
	energy.wait_time = initialEnergy
	energy.one_shot = true
	add_child(energy)
	
	timetoenable = Timer.new()
	timetoenable.wait_time = 1.0
	timetoenable.one_shot = true
	add_child(timetoenable)

func _ready():
	energy.connect("timeout", self, "on_energy_timeout")
	timetoenable.connect("timeout", self, "on_time_to_enable_timeout")

	energy.start()
	timetoenable.start()

func _process(_delta):
	update()

func on_energy_timeout()->void:
	queue_free()

func on_time_to_enable_timeout()->void:
	isEnabledVar = true

func isEnabled()->bool:
	return isEnabledVar
