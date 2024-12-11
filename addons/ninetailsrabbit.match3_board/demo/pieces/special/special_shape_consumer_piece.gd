class_name SpecialShapeConsumerPiece extends PieceUI

## Initialized when a new special piece spawn after a sequence combination consumed
@export var shape_to_consume: String = ""


func _ready() -> void:
	super._ready()
	set_process(false)
	
	
func _process(delta: float) -> void:
	rotation += 25 * delta
	scale += scale * delta


func consume(sequence: Sequence) -> bool:
	if not triggered:
		triggered = true
		board.lock()
		var target_pieces: Array[PieceUI] = board.pieces_of_shape(shape_to_consume)

		if target_pieces.is_empty():
			return super.consume(sequence)

		var new_pieces = board.grid_cells_from_pieces(target_pieces).map(func(cell: GridCellUI) -> PieceUI: return cell.current_piece)
		set_process(true)
		
		var tween: Tween = create_tween().set_parallel(true)
		
		for piece: PieceUI in target_pieces:
			tween.tween_property(piece, "scale", Vector2(piece.scale.x * 1.1, piece.scale.y * 1.3), 1.0)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)


		await tween.finished
		board.sequence_consumer.add_pieces_to_queue(new_pieces, true)

	return super.consume(sequence)
