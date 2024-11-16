class_name DemoSequenceConsumer extends SequenceConsumer

const SpecialCrossPieceScene: PackedScene = preload("res://addons/ninetailsrabbit.match3_board/demo/pieces/special/special_cross_piece.tscn")
const SpecialShapeConsumerPieceScene: PackedScene = preload("res://addons/ninetailsrabbit.match3_board/demo/pieces/special/special_shape_consumer_piece.tscn")

func consume_sequence(sequence: Sequence) -> void:
	consumed_sequence.emit(sequence)
	
	if sequence.is_special_shape():
		var special_piece = sequence.get_special_piece()
		special_piece.requested_piece_special_trigger.emit()
		await special_piece.finished_piece_special_trigger
		return
		
	var new_piece_to_spawn = detect_new_combined_piece(sequence)
	
	if new_piece_to_spawn is PieceUI:
		var target_cell_to_spawn: GridCellUI = sequence.middle_cell()
		
		await board.piece_animator.consume_sequence(sequence)
		sequence.consume()
		
		board.draw_piece_on_cell(target_cell_to_spawn, new_piece_to_spawn)
		await board.piece_animator.spawn_special_piece(target_cell_to_spawn, new_piece_to_spawn)
	else:
		await board.piece_animator.consume_sequence(sequence)
		sequence.consume()
		

func detect_new_combined_piece(sequence: Sequence):
	if sequence.all_pieces_are_of_type(PieceDefinitionResource.PieceType.Normal):
		var piece: PieceUI = sequence.pieces().front() as PieceUI
		
		if sequence.is_horizontal_or_vertical_shape():
			match sequence.size():
				4:
					var new_special_piece: SpecialCrossPiece = SpecialCrossPieceScene.instantiate() as SpecialCrossPiece
					return new_special_piece
				5:
					var new_special_piece: SpecialShapeConsumerPiece = SpecialShapeConsumerPieceScene.instantiate() as SpecialShapeConsumerPiece
					new_special_piece.shape_to_consume = piece.piece_definition.shape
					return new_special_piece
		
	return null 
