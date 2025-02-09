class_name FallMover extends RefCounted


var board: Board


func _init(_board: Board) -> void:
	board = _board



func calculate_fall_movements_on_column(column: int) -> Array[FallMovement]:
	var cells: Array[Match3GridCell] = board.cell_finder.grid_cells_from_column(column)
	var movements: Array[FallMovement] = []
	
	var from_cell: Match3GridCell = board.cell_finder.first_movable_cell_on_column(column)
	var to_cell: Match3GridCell = board.cell_finder.last_empty_cell_on_column(column)
	
	if from_cell and from_cell.has_piece() and to_cell:
		to_cell.assign_piece(from_cell.piece, true)
		from_cell.unlink_piece()
		movements.append(FallMovement.new(from_cell, to_cell))
	
	return movements
	


class FallMovement:
	var from_cell: Match3GridCell
	var to_cell: Match3GridCell
	var is_diagonal: bool = false
	
	func _init(_from_cell: Match3GridCell, _to_cell: Match3GridCell, _is_diagonal: bool = false) -> void:
		from_cell = _from_cell
		to_cell = _to_cell
		is_diagonal = _is_diagonal
