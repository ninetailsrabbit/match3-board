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
	var cells: Array[Match3GridCell] = board.finder.grid_cells_from_column(column)
	var movements: Array[FallMovement] = []
	
	var from_cell: Match3GridCell = board.finder.first_fallable_cell_with_piece_on_column(column)
	var to_cell: Match3GridCell = board.finder.last_empty_cell_on_column(column)
	
	if from_cell and from_cell.has_piece() and to_cell.is_empty():
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
