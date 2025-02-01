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


var piece_generator: Match3PieceGenerator = Match3PieceGenerator.new()


func _init(width: int, height: int, moves_on_start: int = 25, _allow_matches_on_start: bool = false) -> void:
	grid_width = width
	grid_height = height
	available_moves_on_start = moves_on_start
	allow_matches_on_start = _allow_matches_on_start
	
	
func prepare_grid_cells() -> Board:
	if grid_cells.is_empty():
		for column in grid_width:
			grid_cells.append([])
			
			for row in grid_height:
				var grid_cell: Match3GridCell = Match3GridCell.new(row, column)
				grid_cells[column].append(grid_cell)
		
		grid_cells_flattened.append_array(Match3BoardPluginUtilities.flatten(grid_cells))
	
	return self


func generate_random_piece() -> Match3Piece:
	return piece_generator.roll()
