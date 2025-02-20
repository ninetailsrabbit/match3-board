class_name Match3FallMover extends RefCounted


var board: Match3Board


func _init(_board: Match3Board) -> void:
	board = _board


func fall_pieces() -> Array[FallMovement]:
	var movements: Array[FallMovement] = []
	
	if board.configuration.fill_mode_is_in_place():
		return movements
	
	for column in board.configuration.grid_width:
		movements.append_array(calculate_fall_movements_on_column(column))

	return movements


func calculate_fall_movements_on_column(column: int) -> Array:
	var column_cells: Array[Match3GridCell] = board.finder.cells_from_column(column)
	var column_movements: Array[FallMovement] = [] 
	
	while pieces_can_fall_in_column(column):
		## Linked by index, from_cells[0] -> to_cells[0]
		var from_cells: Array[Match3GridCell] = []
		var to_cells: Array[Match3GridCell] = []
		
		for cell: Match3GridCell in column_cells:
			if not cell.is_bottom_border() and cell.can_contain_piece and cell.has_piece() and cell.piece.can_be_moved:
				if cell.neighbour_bottom.is_empty():
					from_cells.append(cell)
					var to_cell: Match3GridCell = cell.neighbour_bottom
					
					while to_cell.neighbour_bottom and to_cell.neighbour_bottom.is_empty():
						to_cell = to_cell.neighbour_bottom
					
					to_cells.append(cell.neighbour_bottom)
					
				elif from_cells.size() > 0 and board.configuration.fill_mode_is_side():
					if cell.neighbour_right_has_piece() \
						and cell.diagonal_neighbour_bottom_right_is_empty() \
						and cell.diagonal_neighbour_bottom_right.can_contain_piece:
							
						to_cells.append(cell.diagonal_neighbour_bottom_right)
						
					elif cell.neighbour_left_has_piece() \
						and cell.diagonal_neighbour_bottom_left_is_empty()\
						and cell.diagonal_neighbour_bottom_left.can_contain_piece:
							
						to_cells.append(cell.diagonal_neighbour_bottom_left)
						

		if from_cells.size() > 0 and to_cells.size() > 0:
			for from_cell_index in from_cells.size():
				if from_cell_index < to_cells.size():
					var from_cell: Match3GridCell = from_cells[from_cell_index]
					var to_cell: Match3GridCell = to_cells[from_cell_index]
				
					if from_cell != to_cell and from_cell.has_piece() and to_cell.is_empty():
						column_movements.append(FallMovement.new(from_cell, to_cell, from_cell.piece))
						to_cell.piece = from_cell.piece
						from_cell.piece = null
	
	## We revert to the original state to return the column_movements without altering the board
	## This is because the pieces_can_fall_in_column() uses the updated board with the fall column_movements applied
	for movement: FallMovement in column_movements:
		movement.from_cell.piece = movement.piece
		movement.to_cell.piece = null
		
	return column_movements
	
		
func pieces_can_fall_in_column(column: int) -> bool:
	var column_cells: Array[Match3GridCell] = board.finder.cells_from_column(column)
	
	return column_cells.filter(_piece_can_fall).size() > 0
	
	
func _piece_can_fall(cell: Match3GridCell) -> bool:
	return cell.has_piece() \
		and cell.piece.can_be_moved \
		and cell.neighbour_bottom \
		and cell.neighbour_bottom.can_contain_piece \
		and cell.neighbour_bottom.is_empty()
	

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
