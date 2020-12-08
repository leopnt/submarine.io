# a class that defines a terrain from a noiseImage
# the size of the base texture is set with terrainPixelSize
# this can't be something else than a square because it is
# seamless
# In the draw function, you define where you draw the
# 'duplicates' of the calculated image

# It means that you can calculate a small noise texture
# and place it as a grid to get a big (repetitive) map

# the larger the image size, the BIGGER the loading time because of CPU
# calculations, but also the more randomness...
# the larger the terrain, the bigger the loading time
# because of texture placement calculations.

#the terrain is displayed via a shader so the GPU do the work

extends Sprite
class_name Terrain

var noise:OpenSimplexNoise
var noiseImage:Image

var terrainPixelSize:int


func _init():
	texture = NoiseTexture.new()
	texture.seamless = true
	texture.width = 1024
	texture.height = texture.width #must be a SQUARE
	
	region_enabled = true
	region_rect = Rect2(0, 0, texture.width * 4, texture.height * 4)
	
	noise = OpenSimplexNoise.new()
	noise.seed = randi()
	
	#noise parameters
	noise.octaves = 4
	noise.period = 300
	noise.persistence = 0.5
	noise.lacunarity = 3
	
	texture.noise = noise
	
	noiseImage = noise.get_seamless_image(texture.width) #must be square texture
	noiseImage.lock()
	
	
	var l = 60 #number of contour height plan
	
	
	material = ShaderMaterial.new()
	material.shader = load("res://shaders/terrain.shader")
	material.set_shader_param("terrainDisplay", Global.terrainDisplay)
	material.set_shader_param("width", texture.width)
	material.set_shader_param("height", texture.height)
	material.set_shader_param("tex", texture)
	material.set_shader_param("l", l)
	

func getHeightAt(location:Vector2)->int:
	#get the terrain altitude (where 0 is black value of
	#noise i.e. min value) at a given location.
	
	#as the location can be outside of the seamless image,
	#we need a virtualPos, which is 'mapped' to the
	#noiseImage size
	
	var virtualPos = Vector2(
		int(location.x) % int(noiseImage.get_size().x),
		int(location.y) % int(noiseImage.get_size().y)
		)
	if virtualPos.x < 0:
		virtualPos.x = noiseImage.get_size().x + virtualPos.x
	if virtualPos.y < 0:
		virtualPos.y = noiseImage.get_size().y + virtualPos.y
	
	#return a comprehensible-for-the-player height:
	return int(200 * 5 * pow(noiseImage.get_pixel(virtualPos.x, virtualPos.y).r, 5))


func updateDisplay(playerPos:Vector2)->void:
	# update tiles according to player position
	# DEPRECATED : USE BIGGER MAP INSTEAD
	var texGridPos = Vector2(
		int(playerPos.x / texture.width),
		int(playerPos.y / texture.height)
		)
	
	offset = texGridPos * texture.get_size()
