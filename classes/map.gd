# all static/rigid map objects should be added here

extends Sprite
class_name Map

const radius:int = 800

func _init():
    pass

func _draw():
    draw_arc(Vector2.ZERO, radius, 0, 2*PI, 128, Color(0, 1, 0, 0.6), 1.5, true)
    draw_arc(Vector2.ZERO, radius + 5, 0, 2*PI, 128, Color(0, 1, 0, 0.3), 1.5, true)
    draw_arc(Vector2.ZERO, radius + 10, 0, 2*PI, 128, Color(0, 1, 0, 0.1), 1.5, true)

func _process(_delta):
    update()
