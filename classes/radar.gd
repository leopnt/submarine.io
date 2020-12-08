extends Node2D
class_name Radar

var maxRange:float

var taltitude:int #terrain elevation
var circleRadius:float

var default_font:DynamicFont

#position is same as parent
#so define an offset if necessary


func _init():
    maxRange = 280
    
    circleRadius = maxRange
    var dynFont = DynamicFont.new()
    dynFont.font_data = load("res://fonts/vt323.regular.ttf")#Control.new().get_font("font")

    default_font = dynFont
    default_font.use_filter = true
    default_font.size = 12

func run()->void:
    pass

func _draw():
    #circles and dist text
    for radius in range(circleRadius/4, circleRadius +1, circleRadius/4):
        draw_arc(
            position,
            radius,
            0.0,
            2*PI,
            64,
            Color(0, 255, 0, 0.00001*radius)
            )
        draw_string(
            default_font,
            Vector2(
                position.x + radius - 1.2*default_font.get_string_size(str(radius)).x,
                position.y
                ),
            str(4*radius),
            Color(0, 255, 0, 0.004))
            
    
    #angles txt and lines
    var da = (2*PI)/8
    for i in range(0, 8):
        var angle = i * da
        var endLine = Vector2(
        position.x + int(0.75 * circleRadius) * sin(angle),
        position.y + int(0.75 * circleRadius) * cos(angle)
        )
        draw_line(Vector2(position.x, position.y), endLine, Color(0, 255, 0, 0.002))
        
        var text = str(rad2deg(angle)) + "°"
        var textSize = default_font.get_string_size(text)
        draw_string(
            default_font,
            Vector2(
                position.x + 1.02*(circleRadius+textSize.x/2) * sin(angle) - textSize.x/2,
                position.y + 1.02*(circleRadius+textSize.y/2) * cos(angle) + textSize.y/2
                ),
            text,
            Color(0, 255, 0, 0.004)
        )
    
    #text
    draw_string(
        default_font,
        Vector2(position.x +220, position.y +220),
        "T. Height: " + str(taltitude),
        Color(0, 255, 0, 0.004)
        )
    draw_string(
        default_font,
        Vector2(position.x +220, position.y +240),
        "Altitude: " + str(124 - taltitude),
        Color(0, 255, 0, 0.004)
        )
    
    
    #center circle
    draw_circle(Vector2.ZERO, 2, Color(0,255,0)) 

func searchForObjs()->void:
    pass

func updateDisplay(smAlt)->void:
    taltitude = smAlt
    update()
