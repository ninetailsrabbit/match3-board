class_name Board extends RefCounted

const MinGridWidth: int = 3
const MinGridHeight: int = 3

signal state_changed(from: BoardState, to: BoardState)
signal movement_consumed
signal finished_available_movements
signal locked
signal unlocked


enum BoardState {
	WaitForInput,
	Fill,
	Consume
}


var min_match: int = 3:
	set(value):
		min_match = max(3, value)
		
## The maximum amount of pieces a match can have.
var max_match: int  = 5:
	set(value):
		max_match = max(min_match, value)


var grid_width: int = 8:
		set(value):
			if grid_width != value:
				grid_width = maxi(MinGridWidth, value)
var grid_height: int = 7:
		set(value):
			if grid_height != value:
				grid_height = maxi(MinGridHeight, value)

# Multidimensional Array to access cells by column & row
var grid_cells: Array = [] 
var grid_cells_flattened: Array[Match3GridCell] = []


var available_moves_on_start: int = 25
var allow_matches_on_start: bool = false
var horizontal_shape: bool = true
## When enabled, vertical matchs between pieces are allowed
var vertical_shape: bool = true
## When enabled, TShape matchs between pieces are allowed
var tshape: bool = true
## When enabled, LShape  matchs between pieces are allowed
var lshape: bool = true

var current_state: BoardState = BoardState.WaitForInput:
	set(new_state):
		if new_state != current_state:
			var previous_state: BoardState = current_state
			current_state = new_state
			state_changed.emit(previous_state, current_state)

## Set to -1 for infinite moves in the board
var current_available_moves: int = 0:
	set(value):
		if value != current_available_moves:
			if value == -1:
				current_available_moves = value
				return
				
			var previous_moves: int = current_available_moves
			current_available_moves = clamp(value, 0, available_moves_on_start)
			
			
			if value < previous_moves:
				movement_consumed.emit()
			
			elif value == 0:
				finished_available_movements.emit()
				

var is_locked: bool = false:
	set(value):
		if value != is_locked:
			is_locked = value
			
			if is_locked:
				locked.emit()
			else:
				unlocked.emit()

#region Modules
var piece_generator: Match3PieceGenerator = Match3PieceGenerator.new()
var cell_finder: Match3BoardCellFinder = Match3BoardCellFinder.new(self)
var sequence_finder: Match3SequenceFinder = Match3SequenceFinder.new(self)
#endregion


func _init(width: int, height: int, moves_on_start: int = 25, _allow_matches_on_start: bool = false) -> void:
	grid_width = width
	grid_height = height
	available_moves_on_start = moves_on_start
	allow_matches_on_start = _allow_matches_on_start
	

#region Grid cells
func prepare_grid_cells() -> Board:
	if grid_cells.is_empty():
		for column in grid_width:
			grid_cells.append([])
			
			for row in grid_height:
				var grid_cell: Match3GridCell = Match3GridCell.new(row, column)
				grid_cells[column].append(grid_cell)
		
		grid_cells_flattened.append_array(Match3BoardPluginUtilities.flatten(grid_cells))
		_update_grid_cells_neighbours(grid_cells_flattened)
		
	return self


func _update_grid_cells_neighbours(grid_cells: Array[Match3GridCell]) -> void:
	if not grid_cells.is_empty():
		for grid_cell: Match3GridCell in grid_cells:
			grid_cell.neighbour_up = cell_finder.get_cell(grid_cell.column, grid_cell.row - 1)
			grid_cell.neighbour_bottom = cell_finder.get_cell(grid_cell.column, grid_cell.row + 1)
			grid_cell.neighbour_right = cell_finder.get_cell(grid_cell.column + 1, grid_cell.row )
			grid_cell.neighbour_left = cell_finder.get_cell(grid_cell.column - 1, grid_cell.row)
			grid_cell.diagonal_neighbour_top_right = cell_finder.get_cell(grid_cell.column + 1, grid_cell.row - 1)
			grid_cell.diagonal_neighbour_top_left = cell_finder.get_cell(grid_cell.column - 1, grid_cell.row - 1)
			grid_cell.diagonal_neighbour_bottom_right = cell_finder.get_cell(grid_cell.column + 1, grid_cell.row + 1)
			grid_cell.diagonal_neighbour_bottom_left = cell_finder.get_cell(grid_cell.column - 1, grid_cell.row + 1)
#endregion

#region Piece generator
func generate_random_piece() -> Match3Piece:
	return piece_generator.roll()

#endregion
