#############################################
### This class represents a board grid cell
### The only responsibility it has is to give information on its position and to exchange pieces with other cells.
#############################################
class_name Match3GridCell extends RefCounted

signal assigned_new_piece(piece: Match3Piece)
signal replaced_piece(previous_piece: Match3Piece, piece: Match3Piece)
signal removed_piece(piece: Match3Piece)


var column: int
var row: int
var can_contain_piece: bool = true
var piece: Match3Piece

#region Cached neighbours
## The Match3Board assign this values when preparing the cell so that they are always available as a cache.
var neighbour_up: Match3GridCell
var neighbour_bottom: Match3GridCell
var neighbour_right: Match3GridCell
var neighbour_left: Match3GridCell
var diagonal_neighbour_top_right: Match3GridCell
var diagonal_neighbour_top_left: Match3GridCell
var diagonal_neighbour_bottom_right: Match3GridCell
var diagonal_neighbour_bottom_left: Match3GridCell
#endregion

func _init(_column: int, _row: int, _can_contain_piece: bool = true) -> void:
	column = _column
	row = _row
	can_contain_piece = _can_contain_piece
	

#region Pieces
func has_piece() -> bool:
	return piece != null


func is_empty() -> bool:
	return piece == null
		

func assign_piece(new_piece: Match3Piece, replace: bool = false) -> void:
	if not has_piece():
		piece = new_piece
		assigned_new_piece.emit(piece)
		
	elif replace and new_piece != piece:
		replaced_piece.emit(piece, new_piece)
		piece = new_piece


func remove_piece() -> Match3Piece:
	if has_piece():
		var removed_piece: Match3Piece = piece
		
		removed_piece.emit(piece)
		piece = null
		
		return removed_piece
		
	return null

	
func swap_piece_with_cell(other_cell: Match3GridCell) -> bool:
	if can_swap_piece_with_cell(other_cell):
		var current_piece: Match3Piece = piece
		assign_piece(other_cell.piece, true)
		other_cell.assign_piece(current_piece, true)
		
		return true
		
	return false


func can_swap_piece_with_cell(other_cell: Match3GridCell) -> bool:
	return other_cell != self \
		and has_piece() \
		and other_cell.has_piece() \
		and piece != other_cell.piece \
		and not piece.is_locked \
		and not other_cell.piece.is_locked

#endregion

#region Grid position
func board_position() -> Vector2:
	return Vector2(row, column)


func in_same_row_as(other_cell: Match3GridCell) -> bool:
	return row == other_cell.row


func in_same_column_as(other_cell: Match3GridCell) -> bool:
	return column == other_cell.column


func in_same_position_as(other_cell: Match3GridCell) -> bool:
	return in_same_column_as(other_cell) and in_same_row_as(other_cell)


func in_same_grid_position_as(grid_position: Vector2) -> bool:
	return grid_position.x == row and grid_position.y == column

#endregion

#region Neighbours
func is_row_neighbour_of(other_cell: Match3GridCell) -> bool:
	var left_column: int = column - 1
	var right_column: int = column + 1
	
	return in_same_row_as(other_cell) \
		and [left_column, right_column].any(func(near_column: int): 
			return other_cell.column == near_column)


func is_column_neighbour_of(other_cell: Match3GridCell) -> bool:
	var upper_row: int = row - 1
	var bottom_row: int = row + 1

	return in_same_column_as(other_cell) \
		and [upper_row, bottom_row].any(func(near_row: int): return other_cell.row == near_row)


func in_diagonal_with(other_cell: Match3GridCell) -> bool:
	var diagonal_top_right: Vector2 = Vector2(row - 1, column + 1)
	var diagonal_top_left: Vector2 = Vector2(row - 1, column - 1)
	var diagonal_bottom_right: Vector2 = Vector2(row + 1, column + 1)
	var diagonal_bottom_left: Vector2 = Vector2(row + 1, column - 1)

	return other_cell.in_same_grid_position_as(diagonal_top_right) \
		or other_cell.in_same_grid_position_as(diagonal_top_left) \
		or other_cell.in_same_grid_position_as(diagonal_bottom_right) \
		or other_cell.in_same_grid_position_as(diagonal_bottom_left)


func neighbours() -> Dictionary:
	return {
		"up": neighbour_up,
		"bottom": neighbour_bottom,
		"right": neighbour_right,
		"left": neighbour_left,
		"diagonal_top_right": diagonal_neighbour_top_right,
		"diagonal_top_left": diagonal_neighbour_top_left,
		"diagonal_bottom_right": diagonal_neighbour_bottom_right,
		"diagonal_bottom_left": diagonal_neighbour_bottom_left,
	}
	

func is_top_left_corner() -> bool:
	return neighbour_up == null and neighbour_left == null \
		and neighbour_bottom is Match3GridCell and neighbour_right is Match3GridCell
		

func is_top_right_corner() -> bool:
	return neighbour_up == null and neighbour_right == null \
		and neighbour_bottom is Match3GridCell and neighbour_left is Match3GridCell
		

func is_bottom_left_corner() -> bool:
	return neighbour_bottom == null and neighbour_left == null \
		and neighbour_up is Match3GridCell and neighbour_right is Match3GridCell
		

func is_bottom_right_corner() -> bool:
	return neighbour_bottom == null and neighbour_right == null \
		and neighbour_up is Match3GridCell and neighbour_left is Match3GridCell


func is_top_border() -> bool:
	return (is_top_left_corner() or is_top_right_corner()) \
		or (neighbour_up == null and neighbour_bottom is Match3GridCell and neighbour_right is Match3GridCell and neighbour_left is Match3GridCell)
		

func is_bottom_border() -> bool:
	return (is_bottom_left_corner() or is_bottom_right_corner()) \
	or (neighbour_bottom == null and neighbour_up is Match3GridCell and neighbour_right is Match3GridCell and neighbour_left is Match3GridCell)
		

func is_right_border() -> bool:
	return (is_top_right_corner() or is_bottom_right_corner()) \
		or (neighbour_right == null and neighbour_up is Match3GridCell and neighbour_bottom is Match3GridCell and neighbour_left is Match3GridCell)
					
	
func is_left_border() -> bool:
	return (is_top_left_corner() or is_bottom_left_corner()) \
		or (neighbour_left == null and neighbour_up is Match3GridCell and neighbour_bottom is Match3GridCell and neighbour_right is Match3GridCell)
#endregion
