class_name Board extends RefCounted

const MinGridWidth: int = 3
const MinGridHeight: int = 3

signal added_piece(piece: Match3Piece)
signal added_consume_rule(rule: Match3SequenceConsumeRule)
signal swap_accepted(from_cell: Match3GridCell, to_cell: Match3GridCell)
signal swap_rejected(from_cell: Match3GridCell, to_cell: Match3GridCell)
signal movement_consumed
signal finished_available_movements
signal locked
signal unlocked

enum FillModes {
	## Pieces fall down to fill the empty cells
	FallDown,
	## Pieces still fall down but the empty cell sides are taking into account
	Side,
	## Pieces appears in the same place they were removed
	InPlace
}

var min_match: int = 3:
	set(value):
		min_match = maxi(3, value)
		
## The maximum amount of pieces a match can have.
var max_match: int = 5:
	set(value):
		max_match = maxi(min_match, value)

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
## Using the Match3Piece.ID as key with the value being a dictionary with the structure { "piece": Match3Piece, "weight": Match3PieceWeight }
var available_pieces: Dictionary = {}
var available_special_pieces: Dictionary = {}

var available_moves_on_start: int = 25
var allow_matches_on_start: bool = false
var fill_mode: FillModes = FillModes.FallDown


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
var sequence_consumer: Match3SequenceConsumer
#endregion


func _init(_min_match: int, _max_match: int, width: int, height: int, moves_on_start: int = 25, _allow_matches_on_start: bool = false) -> void:
	min_match = _min_match
	max_match = _max_match
	grid_width = width
	grid_height = height
	available_moves_on_start = moves_on_start
	allow_matches_on_start = _allow_matches_on_start
	
	current_available_moves = available_moves_on_start


func distance() -> int:
	return grid_width + grid_height
	

func size() -> int:
	return grid_width * grid_height


func change_fill_mode(new_mode: FillModes) -> Board:
	fill_mode = new_mode
	
	return self


#region Pieces
func add_pieces(pieces: Array[Dictionary]) -> Board:
	for piece_data: Dictionary in pieces:
		if piece_data.has("piece") and piece_data.has("weight"):
			add_piece(piece_data.piece as Match3Piece, float(piece_data.weight))
	
	return self
	
	
func add_piece(piece: Match3Piece, weight: float = 1.0) -> Board:
	assert(not piece.id.is_empty(), "Match3Board->add_piece: The ID of the piece to add is empty, the piece cannot be added")
	
	var result: Dictionary = available_pieces.get_or_add(piece.id, {"piece": piece, "weight": Match3PieceWeight.new(piece, weight)})
	piece_generator.add_piece(result.weight)
	
	added_piece.emit(piece)
	
	return self

## The special pieces are not added into the piece generator, they need to be spawned from consuming sequences
func add_special_piece(piece: Match3Piece) -> Board:
	assert(not piece.id.is_empty(), "Match3Board->add_special_piece: The ID of the special piece to add is empty, the piece cannot be added")
	assert(piece.is_special(), "Match3Board->add_special_piece: The piece is not of type special, the piece cannot be added")
	
	available_special_pieces.get_or_add(piece.id, {"piece": piece, "weight": null})
	
	added_piece.emit(piece)
	
	return self


func swap_pieces(from_grid_cell: Match3GridCell, to_grid_cell: Match3GridCell) -> bool:
	var swapped: bool =  from_grid_cell.swap_piece_with_cell(to_grid_cell)
	
	if swapped:
		swap_accepted.emit(from_grid_cell, to_grid_cell)
	else:
		swap_rejected.emit(from_grid_cell, to_grid_cell)
	
	return swapped


func fall_pieces() -> void:
	pass


func fill_empty_cells() -> Array[Match3GridCell]:
	var empty_cells: Array[Match3GridCell] = cell_finder.empty_cells()
	
	for cell: Match3GridCell in empty_cells:
		assign_random_piece_on_cell(cell)
	
	return empty_cells

#endregion

#region Grid cells
func prepare_grid_cells() -> Board:
	if grid_cells.is_empty():
		for column in grid_width:
			grid_cells.append([])
			
			for row in grid_height:
				var grid_cell: Match3GridCell = Match3GridCell.new(column, row)
				grid_cells[column].append(grid_cell)
		
		grid_cells_flattened.append_array(Match3BoardPluginUtilities.flatten(grid_cells))
		_update_grid_cells_neighbours(grid_cells_flattened)
		
	return self


func assign_random_piece_on_cell(cell: Match3GridCell, overwrite: bool = false) -> void:
	cell.assign_piece(generate_random_normal_piece(), overwrite)
	

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

#region Pieces
func prepare_pieces() -> Board:
	assert(available_pieces.size() > 0, "Match3Board->prepare_pieces(): There is no available pieces to prepare in this board, aborting operation...")
	
	for cell in grid_cells_flattened.filter(_filter_cells_that_allow_pieces):
		cell.assign_piece(generate_random_normal_piece())
	
	if not allow_matches_on_start:
		remove_matches_from_board()

	return self


func remove_matches_from_board() -> void:
	var sequences: Array[Match3Sequence] = sequence_finder.find_board_sequences()
	
	while sequences.size() > 0:
		for sequence: Match3Sequence in sequences:
			var cells_to_change = sequence.cells.slice(0, (sequence.cells.size() / min_match) + 1)
			var piece_exceptions: Array[Match3PieceWeight] = []
			
			piece_exceptions.assign(Match3BoardPluginUtilities.remove_duplicates(
				cells_to_change.map(
					func(cell: Match3GridCell): return available_pieces[cell.piece.id].weight))
					)
	
			for current_cell: Match3GridCell in cells_to_change:
				var removed_piece = current_cell.remove_piece()
				current_cell.assign_piece(generate_random_normal_piece(piece_exceptions), true)
			
		sequences = sequence_finder.find_board_sequences()


func generate_random_normal_piece(piece_exceptions: Array[Match3PieceWeight] = []) -> Match3Piece:
	return piece_generator.roll(piece_exceptions)

#endregion

#region Sequences
func prepare_sequence_consumer(rules: Array[Match3SequenceConsumeRule]) -> Board:
	if sequence_consumer == null:
		var sequence_consumer_rules: Dictionary = {}
		
		for rule: Match3SequenceConsumeRule in rules:
			sequence_consumer_rules.get_or_add(rule.id, rule)
			
		sequence_consumer = Match3SequenceConsumer.new(self, sequence_consumer_rules)
	else:
		sequence_consumer.add_sequence_consume_rules(rules)
	
	return self
	
	
func sequences_to_combo_rules() -> Array[Match3SequenceConsumer.Match3SequenceConsumeResult]:
	var matches: Array[Match3Sequence] = sequence_finder.find_board_sequences()
	
	if matches.is_empty():
		return []
	
	var combos: Array[Match3SequenceConsumer.Match3SequenceConsumeResult] = []
	
	for sequence: Match3Sequence in matches:
		combos.append(sequence_consumer.consume_sequence(sequence))
		
	return combos
	
#endregion


func _filter_cells_that_allow_pieces(cell: Match3GridCell) -> bool:
	return cell.can_contain_piece
