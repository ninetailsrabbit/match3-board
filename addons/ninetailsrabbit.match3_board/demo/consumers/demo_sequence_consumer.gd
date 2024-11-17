class_name DemoSequenceConsumer extends SequenceConsumer

const SpecialCrossPieceScene: PackedScene = preload("res://addons/ninetailsrabbit.match3_board/demo/pieces/special/special_cross_piece.tscn")
const SpecialShapeConsumerPieceScene: PackedScene = preload("res://addons/ninetailsrabbit.match3_board/demo/pieces/special/special_shape_consumer_piece.tscn")


func detect_new_combined_piece(sequence: Sequence):
	if sequence.all_pieces_are_of_type(PieceDefinitionResource.PieceType.Normal):
		
		if sequence.is_horizontal_or_vertical_shape():
			match sequence.size():
				4:
					var new_special_piece: SpecialCrossPiece = SpecialCrossPieceScene.instantiate() as SpecialCrossPiece
					return new_special_piece
				5:
					var new_special_piece: SpecialShapeConsumerPiece = SpecialShapeConsumerPieceScene.instantiate() as SpecialShapeConsumerPiece
					var pieces = sequence.pieces()
				
					new_special_piece.shape_to_consume = sequence.pieces().front().piece_definition.shape
					return new_special_piece
		
	return null 
