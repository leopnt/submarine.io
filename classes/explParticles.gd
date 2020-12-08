extends Particles2D

func _ready():
	 emitting = true

func _on_endLifeTimer_timeout():
	queue_free()
