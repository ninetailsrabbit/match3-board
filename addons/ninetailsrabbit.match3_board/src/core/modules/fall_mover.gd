class_name Match3FallMover extends RefCounted


var board: Match3BoardUI


func _init(_board: Match3BoardUI) -> void:
	board = _board


func fall_pieces() -> Array[FallMovement]:
	var movements: Array[FallMovement] = []
	
	while pieces_can_fall():
		for column in board.configuration.grid_width:
			movements.append_array(calculate_fall_movements_on_column(column))
	
	return movements


func calculate_fall_movements_on_column(column: int) -> Array[FallMovement]:
	var column_cells: Array[Match3GridCellUI] = board.finder.grid_cells_from_column(column)
	var movements: Array[FallMovement] = []
	
	var from_cell: Match3GridCellUI
	var to_cell: Match3GridCellUI
	
	for cell: Match3GridCellUI in column_cells:
		if cell.has_piece():
			if cell.piece.can_be_moved and not cell.is_bottom_border() and cell.neighbour_bottom.is_empty():
				from_cell = cell
				to_cell = cell.neighbour_bottom
				break
				
			if cell.neighbour_bottom and cell.neighbour_bottom.has_piece() and board.configuration.fill_mode_is_side():
				if cell.diagonal_neighbour_bottom_left and cell.diagonal_neighbour_bottom_left.is_empty():
					to_cell = cell.diagonal_neighbour_bottom_left
					
				elif cell.diagonal_neighbour_bottom_right and cell.diagonal_neighbour_bottom_right.is_empty():
					to_cell = cell.diagonal_neighbour_bottom_right

	if from_cell and to_cell:
		var next_cell: Match3GridCellUI = to_cell.neighbour_bottom
		
		while next_cell != null:
			if next_cell.has_piece():
				break
				
			if next_cell.is_empty():
				to_cell = next_cell
			
			next_cell = next_cell.neighbour_bottom
			
	if from_cell and to_cell and from_cell.has_piece() and to_cell.is_empty():
		movements.append(FallMovement.new(from_cell, to_cell, from_cell.piece))
		
		to_cell.piece = from_cell.piece
		from_cell.piece = null
	
	return movements
	
	
func pieces_can_fall() -> bool:
	return board.grid_cells_flattened.filter(func(cell: Match3GridCellUI): return cell.has_piece() and cell.piece.can_be_moved)\
		.any(func(cell: Match3GridCellUI): return cell.neighbour_bottom and cell.neighbour_bottom.can_contain_piece and cell.neighbour_bottom.is_empty()
		)


class FallMovement:
	var from_cell: Match3GridCellUI
	var to_cell: Match3GridCellUI
	var piece: Match3PieceUI
	
	func _init(_from_cell: Match3GridCellUI, _to_cell: Match3GridCellUI, falling_piece: Match3PieceUI) -> void:
		from_cell = _from_cell
		to_cell = _to_cell
		piece = falling_piece
	
	
	func is_diagonal() -> bool:
		return from_cell.in_diagonal_with(to_cell)
