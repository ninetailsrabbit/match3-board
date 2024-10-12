class_name CrossPiece extends PieceUI

@onready var draggable_sprite: DraggableSprite2D = $DraggableSprite2D
@onready var detection_area: Area2D = $DraggableSprite2D/DetectionArea
@onready var piece_area: Area2D = $PieceArea
@onready var detection_area_collision: CollisionShape2D = $DraggableSprite2D/DetectionArea/CollisionShape2D
@onready var piece_area_collision: CollisionShape2D = $PieceArea/CollisionShape2D

var original_z_index: int = 0

func _ready() -> void:
	prepare_sprite(draggable_sprite)
	prepare_area_detectors()
	
	original_z_index = draggable_sprite.z_index
	
	draggable_sprite.drag_started.connect(on_drag_started)
	draggable_sprite.drag_ended.connect(on_drag_ended)
	board.locked.connect(on_board_locked)
	board.unlocked.connect(on_board_unlocked)
	

func prepare_area_detectors() -> void:
	piece_area.collision_layer = board.pieces_collision_layer
	piece_area.collision_mask = 0
	piece_area.monitoring = false
	piece_area.monitorable = true
	
	detection_area.collision_layer = 0
	detection_area.collision_mask = board.pieces_collision_layer
	detection_area.monitoring = true
	detection_area.monitorable = false
	
	piece_area_collision.shape.size = board.cell_size - Vector2i.ONE * (board.cell_size.x / 2)
	detection_area_collision.shape.size = board.cell_size / 2
	
	detection_area_collision.set_deferred("disabled", true)
	

#region Signal callbacks
func on_drag_started() -> void:
	draggable_sprite.z_index = original_z_index + 100
	z_as_relative = false
	
	is_selected = true
	
	piece_area_collision.set_deferred("disabled", true)
	detection_area_collision.set_deferred("disabled", false)


func on_drag_ended() -> void:
	draggable_sprite.z_index = original_z_index
	z_as_relative = true
	
	is_selected = false
	
	var piece_detected_areas: Array[Area2D] = detection_area.get_overlapping_areas()
	
	if piece_detected_areas.size() > 0:
		board.swap_requested.emit(self, piece_detected_areas.front().get_parent() as PieceUI)
		
	piece_area_collision.set_deferred("disabled", false)
	detection_area_collision.set_deferred("disabled", true)
	
	
func on_board_locked() -> void:
	process_mode = PROCESS_MODE_DISABLED
	

func on_board_unlocked() -> void:
	process_mode = PROCESS_MODE_INHERIT
	
#endregion
