class_name LineConnectorPiece extends PieceUI

@onready var sprite: Sprite2D = $Sprite2D
@onready var piece_area: Area2D = $PieceArea

var mouse_region: Button
var line_connector: LineConnector

func _ready() -> void:
	prepare_sprite(sprite)
	
	piece_area.collision_layer = board.pieces_collision_layer
	piece_area.collision_mask = 0
	piece_area.monitorable = true
	piece_area.monitoring = false
	
	if mouse_region == null:
		mouse_region = Button.new()
		mouse_region.self_modulate.a8 = 100 ## TODO - CHANGE TO 0 WHEN FINISH DEBUG
		sprite.add_child(mouse_region)
		
			
	mouse_region.position = Vector2.ZERO
	mouse_region.anchors_preset = Control.PRESET_FULL_RECT
	mouse_region.button_down.connect(on_mouse_region_pressed)
	mouse_region.button_up.connect(on_mouse_region_released)
	
	
func on_mouse_region_pressed() -> void:
	if board.is_locked:
		return
		
	is_selected = true
	
	line_connector = LineConnector.new()
	get_tree().root.add_child(line_connector)
	line_connector.add_piece(self)


func on_mouse_region_released() -> void:
	is_selected = false
	
	if line_connector and not line_connector.is_queued_for_deletion():
		line_connector.queue_free()
		
	line_connector = null
