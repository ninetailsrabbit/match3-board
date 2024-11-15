class_name DemoSequenceConsumer extends SequenceConsumer

const SpecialCrossPieceScene: PackedScene = preload("res://addons/ninetailsrabbit.match3_board/demo/pieces/special/special_cross_piece.tscn")
const SpecialShapeConsumerPieceScene: PackedScene = preload("res://addons/ninetailsrabbit.match3_board/demo/pieces/special/special_shape_consumer_piece.tscn")

func consume_sequence(sequence: Sequence) -> void:
	consumed_sequence.emit(sequence)
	
	var new_piece = detect_new_combined_piece(sequence)
	
	if new_piece is PieceUI:
		sequence.consume_cell(sequence.middle_cell())
		board.draw_piece_on_cell(sequence.middle_cell(), new_piece)
		await board.piece_animator.spawn_special_piece(sequence, new_piece)
		sequence.consume([sequence.middle_cell()])
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
