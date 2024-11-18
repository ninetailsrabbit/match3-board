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
		
		board.lock()
		
		if combined_with != null:
			shape_to_consume = combined_with.piece_definition.shape
			
		var target_pieces: Array[PieceUI] = board.pieces_of_shape(shape_to_consume)
		
		var sequence: Sequence = Sequence.new(board.grid_cells_from_pieces(target_pieces), Sequence.Shapes.Irregular)

		set_process(true)
		
		var tween: Tween = create_tween().set_parallel(true)
		
		for piece: PieceUI in target_pieces:
			tween.tween_property(piece, "scale", Vector2(piece.scale.x * 1.1, piece.scale.y * 1.3), 1.0)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		
		sequence.add_cell(cell())
		
		await tween.finished
		
		board.sequence_consumer.add_action_to_queue(board.sequence_consumer.create_normal_sequence_action(sequence), true)
		finished_piece_special_trigger.emit()
