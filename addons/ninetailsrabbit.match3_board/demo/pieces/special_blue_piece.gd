class_name SpecialBluePiece extends Match3PieceUI


func trigger(board: Match3BoardUI) -> Array[Match3Sequence]:
	super.trigger(board)
	
	var sequence: Match3Sequence = Match3Sequence.new(board.finder.cross_cells_from(cell, true), Match3Sequence.Shapes.Special)
	sequence.origin_special_piece = board.configuration.special_piece_configuration_by_id(id)
	
	return [sequence]
