class_name Match3FallMover extends RefCounted


var board: Board


func _init(_board: Board) -> void:
	board = _board


func fall_pieces() -> Array[FallMovement]:
	var movements: Array[FallMovement] = []
	
	while board.pieces_can_fall():
		for column in board.grid_width:
			movements.append_array(calculate_fall_movements_on_column(column))
	
	return movements


func calculate_fall_movements_on_column(column: int) -> Array[FallMovement]:
	var column_cells: Array[Match3GridCell] = board.finder.grid_cells_from_column(column)
	var movements: Array[FallMovement] = []
	
	var from_cell: Match3GridCell 
	var to_cell: Match3GridCell
	
	for cell: Match3GridCell in column_cells:
		if cell.has_piece():
			if cell.piece.can_be_moved and not cell.is_bottom_border() and cell.neighbour_bottom.is_empty():
				from_cell = cell
				to_cell = cell.neighbour_bottom
				break

	if from_cell and to_cell:
		var next_cell: Match3GridCell = to_cell.neighbour_bottom
		
		while next_cell != null:
			if next_cell.has_piece():
				break
				
			if next_cell.is_empty():
				to_cell = next_cell
			
			next_cell = next_cell.neighbour_bottom
			
	
	if from_cell and to_cell and from_cell.has_piece() and to_cell.is_empty():
		movements.append(FallMovement.new(from_cell, to_cell, from_cell.piece))
		
		to_cell.assign_piece(from_cell.piece)
		from_cell.unlink_piece()
	
	return movements
	

class FallMovement:
	var from_cell: Match3GridCell
	var to_cell: Match3GridCell
	var piece: Match3Piece
	
	func _init(_from_cell: Match3GridCell, _to_cell: Match3GridCell, falling_piece: Match3Piece) -> void:
		from_cell = _from_cell
		to_cell = _to_cell
		piece = falling_piece
	
	
	func is_diagonal() -> bool:
		return from_cell.in_diagonal_with(to_cell)
