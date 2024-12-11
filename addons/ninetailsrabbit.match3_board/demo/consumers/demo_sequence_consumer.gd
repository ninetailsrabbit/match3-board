class_name DemoSequenceConsumer extends SequenceConsumer

const SpecialCrossPieceScene: PackedScene = preload("res://addons/ninetailsrabbit.match3_board/demo/pieces/special/special_cross_piece.tscn")
const SpecialShapeConsumerPieceScene: PackedScene = preload("res://addons/ninetailsrabbit.match3_board/demo/pieces/special/special_shape_consumer_piece.tscn")


func preprocess_sequence(sequence: Sequence) -> void:
	if sequence.all_pieces_are_same_shape():
		var shape: String = sequence.pieces().front().piece_definition.shape
		if sequence.size() == 4:
			sequence.after_consumed = create_special_cross_piece.bind(sequence)
		if sequence.size() >= 5:
			sequence.after_consumed = create_special_shape_consumer_piece.bind(sequence, shape)


func create_special_cross_piece(sequence: Sequence) -> void:
	var cell: GridCellUI = sequence.middle_cell()
	var piece: PieceUI = SpecialCrossPieceScene.instantiate()
	board.draw_piece_on_cell(cell, piece)
	await board.piece_animator.spawn_piece(cell, piece)


func create_special_shape_consumer_piece(sequence: Sequence, shape: String) -> void:
	var cell: GridCellUI = sequence.middle_cell()
	var piece: PieceUI = SpecialShapeConsumerPieceScene.instantiate()
	piece.shape_to_consume = shape
	board.draw_piece_on_cell(cell, piece)
	await board.piece_animator.spawn_piece(cell, piece)
