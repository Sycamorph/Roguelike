extends Node2D


const LightTexture = preload("res://Sprites/UI/Light.png")

@onready var fog = $Fog

var display_width = ProjectSettings.get("display/window/size/viewport_width")
var display_height = ProjectSettings.get("display/window/size/viewport_height")

var fog_image = Image.new()
var fog_texture = ImageTexture.new()
var light_image = LightTexture.get_image()
var light_offset = Vector2(LightTexture.get_width()/2, LightTexture.get_height()/2)

func _ready():
	var fog_image_width = display_width/World.GRID_SIZE
	var fog_image_height = display_height/World.GRID_SIZE
	fog_image.create(fog_image_width, fog_image_height, false, Image.FORMAT_RGBAH)
	fog_image.fill(Color.BLACK)
	light_image.convert(Image.FORMAT_RGBAH)
	fog.scale *= World.GRID_SIZE
	
func update_fog(new_grid_position):
#	fog_image.lock()
#	light_image.lock()
	
	var light_rect = Rect2(Vector2.ZERO, Vector2(light_image.get_width(), light_image.get_height()))
	fog_image.blend_rect(light_image, light_rect, new_grid_position - light_offset)
	
#	fog_image.unlock()
#	light_image.unlock()
	update_fog_image_texture()
	
func update_fog_image_texture():
	fog_texture.create_from_image(fog_image)
	fog.texture = fog_texture
	
func _input(event):
	update_fog(get_local_mouse_position()/World.GRID_SIZE)
	
