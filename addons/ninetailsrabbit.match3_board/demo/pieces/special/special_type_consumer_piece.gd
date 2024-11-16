class_name SpecialShapeConsumerPiece extends PieceUI

## Initialized when a new special piece spawn after a sequence combination consumed
@export var shape_to_consume: String = ""


func _ready() -> void:
	super._ready()
	set_process(false)
	
	
func _process(delta: float) -> void:
	rotation += 25 * delta
	scale += scale * delta


func on_requested_piece_special_trigger() -> void:
	if not triggered and not shape_to_consume.is_empty():
		triggered = true
		
		var target_pieces: Array[PieceUI] = board.pieces_of_shape(shape_to_consume)
		target_pieces.append(self)
		
		var sequence: Sequence = Sequence.new(board.grid_cells_from_pieces(target_pieces), Sequence.Shapes.Special)

		set_process(true)
		
		var tween: Tween = create_tween().set_parallel(true)
		
		for piece: PieceUI in target_pieces:
			if piece != self:
				tween.tween_property(piece, "scale", Vector2(piece.scale.x * 1.2, piece.scale.y * 1.5), 1.0)\
					.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		
		await get_tree().create_timer(0.7).timeout
		
		finished_piece_special_trigger.emit()
		board.consume_requested.emit(sequence)
