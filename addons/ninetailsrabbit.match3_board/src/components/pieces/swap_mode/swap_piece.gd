class_name SwapPiece extends PieceUI

@onready var sprite: Sprite2D = $Sprite2D

var mouse_region: Button


func _ready() -> void:
	prepare_sprite(sprite)
	
	if mouse_region == null:
		mouse_region = Button.new()
		mouse_region.self_modulate.a8 = 100 ## TODO - CHANGE TO 0 WHEN FINISH DEBUG
		sprite.add_child(mouse_region)
		
	mouse_region.position = Vector2.ZERO
	mouse_region.anchors_preset = Control.PRESET_FULL_RECT
	mouse_region.pressed.connect(on_mouse_region_pressed)
	
	
func on_mouse_region_pressed() -> void:
	is_selected = !is_selected
