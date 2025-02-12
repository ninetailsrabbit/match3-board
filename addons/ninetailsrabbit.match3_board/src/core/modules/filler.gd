class_name Match3Filler extends RefCounted


var board: Match3BoardUI


func _init(_board: Match3BoardUI) -> void:
	board = _board


func fill_empty_cells() -> Array[Match3GridCellUI]:
	var empty_cells: Array[Match3GridCellUI] = board.finder.empty_cells()
	var last_pieces: Array[Match3PieceUI] = []
	
	for cell: Match3GridCellUI in empty_cells:
		board.draw_random_piece_on_cell(cell)
		last_pieces.append(cell.piece)
		
		if last_pieces.size() >= board.configuration.min_match:
			while last_pieces.all(func(piece: Match3PieceUI): return piece.match_with(cell.piece)):
				board.draw_random_piece_on_cell(cell, true)
			
			last_pieces.clear()
			
	return empty_cells
