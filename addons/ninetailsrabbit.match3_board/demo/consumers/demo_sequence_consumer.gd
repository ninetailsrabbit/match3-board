class_name DemoSequenceConsumer extends SequenceConsumer

const SpecialCrossPieceScene: PackedScene = preload("res://addons/ninetailsrabbit.match3_board/demo/pieces/special/special_cross_piece.tscn")
const SpecialShapeConsumerPieceScene: PackedScene = preload("res://addons/ninetailsrabbit.match3_board/demo/pieces/special/special_shape_consumer_piece.tscn")


func detect_new_combined_piece(sequence: Sequence):
	if sequence.all_pieces_are_of_type(PieceDefinitionResource.PieceType.Normal):
		var piece: PieceUI = sequence.pieces().front()
		print("first piece from detected sequence", piece.name, piece.piece_definition.shape)
		if sequence.is_horizontal_or_vertical_shape():
			match sequence.size():
				5:
					var new_special_piece: SpecialCrossPiece = SpecialCrossPieceScene.instantiate() as SpecialCrossPiece
					return new_special_piece
				4:
					var new_special_piece: SpecialShapeConsumerPiece = SpecialShapeConsumerPieceScene.instantiate() as SpecialShapeConsumerPiece
					var pieces = sequence.pieces()
					print(",".join(pieces))
					print(",".join(pieces.map(func(piece): return piece.piece_definition.shape)))
					new_special_piece.shape_to_consume = sequence.pieces().front().piece_definition.shape
					return new_special_piece
		
	return null 
