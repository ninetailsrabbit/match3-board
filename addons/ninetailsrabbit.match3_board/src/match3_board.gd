@tool
class_name Match3Board extends Node2D

signal swapped_pieces(from: PieceUI, to: PieceUI, matches: Array[Sequence])
signal swap_requested(from: PieceUI, to: PieceUI)
signal swap_failed(from: GridCellUI, to: GridCellUI)
signal swap_rejected(from: PieceUI, to: PieceUI)
signal consume_requested(sequence: Sequence)
signal piece_selected(piece: PieceUI)
signal piece_unselected(piece: PieceUI)
signal state_changed(from: Match3Preloader.BoardState, to: Match3Preloader.BoardState)
signal prepared_board
signal locked
signal unlocked

@export_group("Debug")
@export var preview_grid_in_editor: bool = false:
	set(value):
		if value != preview_grid_in_editor:
			preview_grid_in_editor = value
			
			if preview_grid_in_editor:
				draw_preview_grid()
			else:
				remove_preview_sprites()

## Tool button to clean the current grid preview
@export var clean_current_preview: bool = false:
	get: 
		return false
	set(value):
		remove_preview_sprites()

@export var preview_pieces: Array[Texture2D] = [
	Match3Preloader.BlueGem,
	Match3Preloader.GreenGem,
	Match3Preloader.YellowGem,
	Match3Preloader.PurpleGem
]

@export var odd_cell_texture: Texture2D = Match3Preloader.OddCellTexture
@export var even_cell_texture: Texture2D = Match3Preloader.EvenCellTexture
@export var empty_cells: Array[Vector2] = []:
	set(value):
		if empty_cells != value:
			empty_cells = value
			draw_preview_grid()
			
@export_group("Size")
@export var grid_width: int = 8:
	set(value):
		if grid_width != value:
			grid_width = max(MinGridWidth, value)
			draw_preview_grid()
@export var grid_height: int = 7:
	set(value):
		if grid_height != value:
			grid_height = max(MinGridHeight, value)
			draw_preview_grid()
			
@export var cell_size: Vector2i = Vector2i(48, 48):
	set(value):
		if value != cell_size:
			cell_size = value
			draw_preview_grid()
@export var cell_offset: Vector2i = Vector2i(5, 10):
	set(value):
		if value != cell_offset:
			cell_offset = value
			draw_preview_grid()

@export_group("Matches")
@export var pieces_collision_layer: int = 1
@export var swap_mode: Match3Preloader.BoardMovements = Match3Preloader.BoardMovements.Adjacent
@export var fill_mode =  Match3Preloader.BoardFillModes.FallDown
@export var available_pieces: Array[PieceDefinitionResource] = []
@export var available_moves_on_start: int = 25
@export var allow_matches_on_start: bool = false
@export var horizontal_shape: bool = true
@export var vertical_shape: bool = true
@export var tshape: bool = true
@export var lshape: bool = true
@export var min_match: int = 3:
	set(value):
		min_match = max(3, value)
@export var max_match: int  = 5:
	set(value):
		max_match = max(min_match, value)
@export var min_special_match: int = 2:
	set(value):
		min_special_match = max(2, value)
@export var max_special_match: int = 2:
	set(value):
		max_special_match = max(min_special_match, value)


const MinGridWidth: int = 3
const MinGridHeight: int = 3


var pieces_by_swap_mode: Dictionary = {
	Match3Preloader.BoardMovements.Adjacent: Match3Preloader.SwapPieceScene,
	Match3Preloader.BoardMovements.Free: Match3Preloader.SwapPieceScene,
	Match3Preloader.BoardMovements.Cross: Match3Preloader.CrossPieceScene,
	Match3Preloader.BoardMovements.CrossDiagonal: Match3Preloader.CrossPieceScene,
	Match3Preloader.BoardMovements.ConnectLine: Match3Preloader.LineConnectorPieceScene
}

#region Features
var piece_weight_generator: PieceWeightGenerator
var piece_animator: PieceAnimator
var sequence_consumer: SequenceConsumer
var cell_highlighter: CellHighlighter
#endregion

var debug_preview_node: Node2D
var grid_cells: Array = [] # Multidimensional to access cells by column & row
var grid_cells_flattened: Array[GridCellUI] = []
var current_selected_piece: PieceUI
var is_locked: bool = false:
	set(value):
		if value != is_locked:
			is_locked = value
			
			if is_locked:
				locked.emit()
			else:
				unlocked.emit()

var current_state: Match3Preloader.BoardState = Match3Preloader.BoardState.WaitForInput:
	set(new_state):
		if new_state != current_state:
			state_changed.emit(current_state, new_state)
			current_state = new_state
			
var pending_sequences: Array[Sequence] = []


func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		add_to_group(Match3Preloader.BoardGroupName)
		remove_preview_sprites()
		
		prepared_board.connect(on_prepared_board)
		piece_selected.connect(on_piece_selected)
		piece_unselected.connect(on_piece_unselected)
		swap_requested.connect(on_swap_requested)
		swap_failed.connect(on_swap_failed)
		swap_rejected.connect(on_swap_rejected)
		swapped_pieces.connect(on_swapped_pieces)
		consume_requested.connect(on_consume_requested)
		state_changed.connect(on_state_changed)
		
		if piece_weight_generator == null:
			piece_weight_generator = PieceWeightGenerator.new()
			
		if cell_highlighter == null:
			cell_highlighter = CellHighlighter.new()
			
		if piece_animator == null:
			piece_animator = PieceAnimator.new()
			
		if sequence_consumer == null:
			sequence_consumer = SequenceConsumer.new()
		
		add_child(cell_highlighter)
		add_child(piece_animator)
		add_child(sequence_consumer)
			

func _ready() -> void:
	if not Engine.is_editor_hint():
		prepare_board()

#region Board
## Only prepares the grid cells based on width and height
func prepare_board():
	if not Engine.is_editor_hint() and grid_cells.is_empty():
		
		for column in grid_width:
			grid_cells.append([])
			
			for row in grid_height:
				var grid_cell: GridCellUI = GridCellUI.new(row, column)
				grid_cell.cell_size = cell_size
				
				grid_cells[column].append(grid_cell)
		
		grid_cells_flattened.append_array(PluginUtilities.flatten(grid_cells))
		
		add_pieces(available_pieces)
		
		prepared_board.emit()
		
	return self


func add_pieces(new_pieces: Array[PieceDefinitionResource]) -> void:
	piece_weight_generator.add_available_pieces(new_pieces)


func generate_new_piece(selected_swap_mode: Match3Preloader.BoardMovements = swap_mode) -> PieceUI:
	return pieces_by_swap_mode[selected_swap_mode].instantiate() as PieceUI


func draw_board():
	for grid_cell: GridCellUI in grid_cells_flattened:
		draw_grid_cell(grid_cell)
		draw_random_piece_on_cell(grid_cell)
		
	if not allow_matches_on_start:
		remove_matches_from_board()
	
	return self
	

func remove_matches_from_board() -> void:
	var sequences: Array[Sequence] = find_board_sequences()
	
	while sequences.size() > 0:
		for sequence: Sequence in sequences:
			var cells_to_change = sequence.cells.slice(0, (sequence.cells.size() / min_match) + 1)
			var piece_exceptions: Array[PieceDefinitionResource] = []
			piece_exceptions.assign(cells_to_change.map(func(cell: GridCellUI): return cell.current_piece.piece_definition))
			
			for current_cell: GridCellUI in cells_to_change:
				var removed_piece = current_cell.remove_piece()
				removed_piece.free()
				draw_random_piece_on_cell(current_cell, piece_exceptions)
			
		sequences = find_board_sequences()
	

func draw_grid_cell(grid_cell: GridCellUI) -> void:
	if not grid_cell.is_inside_tree():
		add_child(grid_cell)
		grid_cell.position = Vector2(grid_cell.cell_size.x * grid_cell.column + cell_offset.x, grid_cell.cell_size.y * grid_cell.row + cell_offset.y)


func draw_random_piece_on_cell(grid_cell: GridCellUI, except: Array[PieceDefinitionResource] = []) -> void:
	var new_piece: PieceUI = generate_new_piece()
	new_piece.piece_definition = piece_weight_generator.roll(except)
	draw_piece_on_cell(grid_cell, new_piece)
	

func draw_piece_on_cell(grid_cell: GridCellUI, new_piece: PieceUI) -> void:
	if grid_cell.can_contain_piece:
		new_piece.cell_size = cell_size
		new_piece.board = self

		add_child(new_piece)
		new_piece.position = grid_cell.position

		grid_cell.remove_piece()
		grid_cell.assign_piece(new_piece)

#endregion

#region Cells
func get_cell_or_null(column: int, row: int):
	if not grid_cells.is_empty() and column >= 0 and row >= 0:
		if column <= grid_cells.size() - 1 and row <= grid_cells[0].size() - 1:
			return grid_cells[column][row]
			
	return null
	
	
func cross_cells_from(origin_cell: GridCellUI) -> Array[GridCellUI]:
	var cross_cells: Array[GridCellUI] = []
	cross_cells.assign(PluginUtilities.remove_duplicates(
		grid_cells_from_row(origin_cell.row) + grid_cells_from_column(origin_cell.column))
	)
	
	return cross_cells


func cross_diagonal_cells_from(origin_cell: GridCellUI) -> Array[GridCellUI]:
	var distance: int = grid_width + grid_height
	var cross_diagonal_cells: Array[GridCellUI] = []
	
	cross_diagonal_cells.assign(PluginUtilities.remove_falsy_values(PluginUtilities.remove_duplicates(
	  	diagonal_top_left_cells_from(origin_cell, distance)\
	 	+ diagonal_top_right_cells_from(origin_cell, distance)\
		+ diagonal_bottom_left_cells_from(origin_cell, distance)\
	 	+ diagonal_bottom_right_cells_from(origin_cell, distance)\
	)))
	
	return cross_diagonal_cells
	

func diagonal_top_right_cells_from(cell: GridCellUI, distance: int) -> Array[GridCellUI]:
	var diagonal_cells: Array[GridCellUI] = []
	
	distance = clamp(distance, 0, grid_width)
	var current_cell = cell.diagonal_neighbour_top_right
	
	if distance > 0 and current_cell is GridCellUI:
		diagonal_cells.append_array(([current_cell] as Array[GridCellUI]) + diagonal_top_right_cells_from(current_cell, distance - 1))
	
	return diagonal_cells


func diagonal_top_left_cells_from(cell: GridCellUI, distance: int) -> Array[GridCellUI]:
	var diagonal_cells: Array[GridCellUI] = []
	
	distance = clamp(distance, 0, grid_width)
	var current_cell = cell.diagonal_neighbour_top_left
	
	if distance > 0 and current_cell is GridCellUI:
		diagonal_cells.append_array(([current_cell] as Array[GridCellUI]) + diagonal_top_left_cells_from(current_cell, distance - 1))
	
	return diagonal_cells


func diagonal_bottom_left_cells_from(cell: GridCellUI, distance: int) -> Array[GridCellUI]:
	var diagonal_cells: Array[GridCellUI] = []
	
	distance = clamp(distance, 0, grid_width)
	var current_cell = cell.diagonal_neighbour_bottom_left
	
	if distance > 0 and current_cell is GridCellUI:
		diagonal_cells.append_array(([current_cell] as Array[GridCellUI]) + diagonal_bottom_left_cells_from(current_cell, distance - 1))
	
	return diagonal_cells


func diagonal_bottom_right_cells_from(cell: GridCellUI, distance: int) -> Array[GridCellUI]:
	var diagonal_cells: Array[GridCellUI] = []
	
	distance = clamp(distance, 0, grid_width)
	var current_cell = cell.diagonal_neighbour_bottom_right
	
	if distance > 0 and current_cell is GridCellUI:
		diagonal_cells.append_array(([current_cell] as Array[GridCellUI]) + diagonal_bottom_right_cells_from(current_cell, distance - 1))
	
	return diagonal_cells


func update_grid_cells_neighbours() -> void:
	if not grid_cells.is_empty():
		for grid_cell: GridCellUI in grid_cells_flattened:
			grid_cell.neighbour_up = get_cell_or_null(grid_cell.column, grid_cell.row - 1)
			grid_cell.neighbour_bottom = get_cell_or_null(grid_cell.column, grid_cell.row + 1)
			grid_cell.neighbour_right = get_cell_or_null(grid_cell.column + 1, grid_cell.row )
			grid_cell.neighbour_left = get_cell_or_null(grid_cell.column - 1, grid_cell.row)
			grid_cell.diagonal_neighbour_top_right = get_cell_or_null(grid_cell.column + 1, grid_cell.row - 1)
			grid_cell.diagonal_neighbour_top_left = get_cell_or_null(grid_cell.column - 1, grid_cell.row - 1)
			grid_cell.diagonal_neighbour_bottom_right = get_cell_or_null(grid_cell.column + 1, grid_cell.row + 1)
			grid_cell.diagonal_neighbour_bottom_left = get_cell_or_null(grid_cell.column - 1, grid_cell.row + 1)
		
func grid_cell_from_piece(piece: PieceUI):
	var found_pieces = grid_cells_flattened.filter(
		func(cell: GridCellUI): return cell.has_piece() and cell.current_piece == piece
	)
	
	if found_pieces.size() == 1:
		return found_pieces.front()


func grid_cells_from_row(row: int) -> Array[GridCellUI]:
	var cells: Array[GridCellUI] = []
	
	if grid_cells.size() > 0 and PluginUtilities.value_is_between(row, 0, grid_height - 1):
		for column in grid_width:
			cells.append(grid_cells[column][row])
	
	return cells
	

func grid_cells_from_column(column: int) -> Array[GridCellUI]:
	var cells: Array[GridCellUI] = []
		
	if grid_cells.size() > 0 and PluginUtilities.value_is_between(column, 0, grid_width - 1):
		for row in grid_height:
			cells.append(grid_cells[column][row])
	
	return cells


func adjacent_cells_from(origin_cell: GridCellUI) -> Array[GridCellUI]:
	return origin_cell.available_neighbours(false)
	
	
func first_movable_cell_on_column(column: int):
	var cells: Array[GridCellUI] = grid_cells_from_column(column)
	cells.reverse()
	
	var movable_cells = cells.filter(
		func(cell: GridCellUI): 
			return cell.has_piece() and cell.current_piece.can_be_moved() and (cell.neighbour_bottom and cell.neighbour_bottom.is_empty())
			)
	
	if movable_cells.size() > 0:
		return movable_cells.front()
	
	return null
	
	
func last_empty_cell_on_column(column: int):
	var cells: Array[GridCellUI] = grid_cells_from_column(column)
	cells.reverse()
	
	var current_empty_cells = cells.filter(func(cell: GridCellUI): return cell.can_contain_piece and cell.is_empty())
	
	if current_empty_cells.size() > 0:
		return current_empty_cells.front()
	
	return null


func pending_empty_cells_to_fill() -> Array[GridCellUI]:
	return grid_cells_flattened.filter(func(cell: GridCellUI): return cell.is_empty() and cell.can_contain_piece)
#endregion

#region Sequence finder
@warning_ignore("unassigned_variable")
func find_horizontal_sequences(cells: Array[GridCellUI]) -> Array[Sequence]:
	var sequences: Array[Sequence] = []
	var current_matches: Array[GridCellUI] = []
	
	if horizontal_shape:
		var valid_cells = cells.filter(func(cell: GridCellUI): return cell.has_piece())
		var previous_cell: GridCellUI
		
		for current_cell: GridCellUI in valid_cells:
			
			if current_matches.is_empty() \
				or (previous_cell is GridCellUI and previous_cell.is_row_neighbour_of(current_cell) and current_cell.current_piece.match_with(previous_cell.current_piece)):
				current_matches.append(current_cell)
				
				if current_matches.size() == max_match:
					sequences.append(Sequence.new(current_matches, Sequence.Shapes.Horizontal))
					current_matches.clear()
			else:
				if PluginUtilities.value_is_between(current_matches.size(), min_match, max_match):
					sequences.append(Sequence.new(current_matches, Sequence.Shapes.Horizontal))
				
				current_matches.clear()
				current_matches.append(current_cell)
			
			if current_cell == valid_cells.back() and PluginUtilities.value_is_between(current_matches.size(), min_match, max_match):
				sequences.append(Sequence.new(current_matches, Sequence.Shapes.Horizontal))
				
			previous_cell = current_cell
			
	sequences.sort_custom(_sort_by_size_descending)

	return sequences
	

@warning_ignore("unassigned_variable")
func find_vertical_sequences(cells: Array[GridCellUI]) -> Array[Sequence]:
	var sequences: Array[Sequence] = []
	var current_matches: Array[GridCellUI] = []
	
	if vertical_shape:
		var valid_cells = cells.filter(func(cell: GridCellUI): return cell.has_piece())
		var previous_cell: GridCellUI
		
		for current_cell: GridCellUI in valid_cells:
			
			if current_matches.is_empty() \
				or (previous_cell is GridCellUI and previous_cell.is_column_neighbour_of(current_cell) and current_cell.current_piece.match_with(previous_cell.current_piece)):
				current_matches.append(current_cell)
				
				if current_matches.size() == max_match:
					sequences.append(Sequence.new(current_matches, Sequence.Shapes.Vertical))
					current_matches.clear()
			else:
				if PluginUtilities.value_is_between(current_matches.size(), min_match, max_match):
					sequences.append(Sequence.new(current_matches, Sequence.Shapes.Vertical))
					
				current_matches.clear()
				current_matches.append(current_cell)
			
			if current_cell.in_same_grid_position_as(valid_cells.back().board_position()) and PluginUtilities.value_is_between(current_matches.size(), min_match, max_match):
				sequences.append(Sequence.new(current_matches, Sequence.Shapes.Vertical))
				
			previous_cell = current_cell
	
	
	sequences.sort_custom(_sort_by_size_descending)
	
	return sequences
	
	
func find_tshape_sequence(sequence_a: Sequence, sequence_b: Sequence):
	if tshape and sequence_a != sequence_b and  sequence_a.is_horizontal_or_vertical_shape() and sequence_b.is_horizontal_or_vertical_shape():
		var horizontal_sequence: Sequence = sequence_a if sequence_a.is_horizontal_shape() else sequence_b
		var vertical_sequence: Sequence = sequence_a if sequence_a.is_vertical_shape() else sequence_b
		
		if horizontal_sequence.is_horizontal_shape() and vertical_sequence.is_vertical_shape():
			var left_edge_cell: GridCellUI = horizontal_sequence.left_edge_cell()
			var right_edge_cell: GridCellUI = horizontal_sequence.right_edge_cell()
			var top_edge_cell: GridCellUI = vertical_sequence.top_edge_cell()
			var bottom_edge_cell: GridCellUI = vertical_sequence.bottom_edge_cell()
			var horizontal_middle_cell: GridCellUI = horizontal_sequence.middle_cell()
			var vertical_middle_cell: GridCellUI = vertical_sequence.middle_cell()
			
			if horizontal_middle_cell.in_same_position_as(top_edge_cell) \
				or horizontal_middle_cell.in_same_position_as(bottom_edge_cell) \
				or vertical_middle_cell.in_same_position_as(left_edge_cell) or vertical_middle_cell.in_same_position_as(right_edge_cell):
				
				var cells: Array[GridCellUI] = []
				
				## We need to iterate manually to be able append the item type on the array
				for cell: GridCellUI in PluginUtilities.remove_duplicates(horizontal_sequence.cells + vertical_sequence.cells):
					cells.append(cell)
								
				return Sequence.new(cells, Sequence.Shapes.TShape)
				
	return null


func find_lshape_sequence(sequence_a: Sequence, sequence_b: Sequence):
	if tshape and sequence_a != sequence_b and  sequence_a.is_horizontal_or_vertical_shape() and sequence_b.is_horizontal_or_vertical_shape():
		var horizontal_sequence: Sequence = sequence_a if sequence_a.is_horizontal_shape() else sequence_b
		var vertical_sequence: Sequence = sequence_a if sequence_a.is_vertical_shape() else sequence_b
		
		if horizontal_sequence.is_horizontal_shape() and vertical_sequence.is_vertical_shape():
			var left_edge_cell: GridCellUI = horizontal_sequence.left_edge_cell()
			var right_edge_cell: GridCellUI = horizontal_sequence.right_edge_cell()
			var top_edge_cell: GridCellUI = vertical_sequence.top_edge_cell()
			var bottom_edge_cell: GridCellUI = vertical_sequence.bottom_edge_cell()
		#
			if left_edge_cell.in_same_position_as(top_edge_cell) \
				or left_edge_cell.in_same_position_as(bottom_edge_cell) \
				or right_edge_cell.in_same_position_as(top_edge_cell) or right_edge_cell.in_same_position_as(bottom_edge_cell):
				
				var cells: Array[GridCellUI] = []
				
				## We need to iterate manually to be able append the item type on the array
				for cell: GridCellUI in PluginUtilities.remove_duplicates(horizontal_sequence.cells + vertical_sequence.cells):
					cells.append(cell)
				
				return Sequence.new(cells, Sequence.Shapes.LShape)
				
	return null

	
func find_horizontal_board_sequences() -> Array[Sequence]:
	var horizontal_sequences: Array[Sequence] = []
	
	for row in grid_height:
		horizontal_sequences.append_array(find_horizontal_sequences(grid_cells_from_row(row)))
	
	return horizontal_sequences


func find_vertical_board_sequences() -> Array[Sequence]:
	var vertical_sequences: Array[Sequence] = []
	
	for column in grid_width:
		vertical_sequences.append_array(find_vertical_sequences(grid_cells_from_column(column)))
	
	return vertical_sequences
	
	
func find_board_sequences() -> Array[Sequence]:
	var horizontal_sequences: Array[Sequence] = find_horizontal_board_sequences()
	var vertical_sequences: Array[Sequence] = find_vertical_board_sequences()
	
	var valid_horizontal_sequences: Array[Sequence] = []
	var valid_vertical_sequences: Array[Sequence] = []
	var tshape_sequences: Array[Sequence] = []
	var lshape_sequences: Array[Sequence] = []
	
	if vertical_sequences.is_empty() and not horizontal_sequences.is_empty():
		valid_horizontal_sequences.append_array(horizontal_sequences)
	elif horizontal_sequences.is_empty() and not vertical_sequences.is_empty():
		valid_vertical_sequences.append_array(vertical_sequences)
	else:
		for horizontal_sequence: Sequence in horizontal_sequences:
			var add_horizontal_sequence: bool = true
		
			for vertical_sequence: Sequence in vertical_sequences:
				var lshape_sequence = find_lshape_sequence(horizontal_sequence, vertical_sequence)
				
				if lshape_sequence is Sequence:
					lshape_sequences.append(lshape_sequence)
					add_horizontal_sequence = false
				else:
					var tshape_sequence = find_tshape_sequence(horizontal_sequence, vertical_sequence)
				
					if tshape_sequence is Sequence:
						tshape_sequences.append(tshape_sequence)
						add_horizontal_sequence = false
				
				if add_horizontal_sequence:
					valid_vertical_sequences.append(vertical_sequence)
				
			if add_horizontal_sequence:
				valid_horizontal_sequences.append(horizontal_sequence)
			
	return valid_horizontal_sequences + valid_vertical_sequences + tshape_sequences + lshape_sequences
	

func find_match_from_cell(cell: GridCellUI):
	if cell.has_piece():
		var horizontal_sequences: Array[Sequence] = find_horizontal_board_sequences()
		var vertical_sequences: Array[Sequence] = find_vertical_board_sequences()
		
		var horizontal = horizontal_sequences.filter(func(sequence: Sequence): return sequence.cells.has(cell))
		var vertical = vertical_sequences.filter(func(sequence: Sequence): return sequence.cells.has(cell))
		
		if not horizontal.is_empty() and not vertical.is_empty():
			var tshape_sequence = find_tshape_sequence(horizontal.front(), vertical.front())
			
			if tshape_sequence:
				return tshape_sequence
			
			var lshape_sequence = find_lshape_sequence(horizontal.front(), vertical.front())
			
			if lshape_sequence:
				return lshape_sequence
		else:
			if horizontal:
				return horizontal.front()
			
			if vertical:
				return vertical.front()
	
	return null


func _sort_by_size_descending(a: Sequence, b: Sequence):
	return a.size() > b.size()
#endregion

#region Movements
## TODO - INTEGRATE THE DIAGONAL SIDE DOWN FEATURE ON THIS CALCULATION
func calculate_fall_movements_on_column(column: int) -> Array[Match3Preloader.FallMovement]:
	var cells: Array[GridCellUI] = grid_cells_from_column(column)
	var movements: Array[Match3Preloader.FallMovement] = []
	
	while cells.any(
		func(cell: GridCellUI): 
			return cell.has_piece() and cell.current_piece.can_be_moved() and (cell.neighbour_bottom and cell.neighbour_bottom.can_contain_piece and cell.neighbour_bottom.is_empty())
			):
		
		var from_cell = first_movable_cell_on_column(column)
		var to_cell = last_empty_cell_on_column(column)
		
		if from_cell is GridCellUI and to_cell is GridCellUI:
			# The pieces needs to be assign here to detect the new empty cells in the while loop
			to_cell.assign_piece(from_cell.current_piece, true)
			from_cell.remove_piece()
			movements.append(Match3Preloader.FallMovement.new(from_cell, to_cell))
		
	return movements


func calculate_all_fall_movements() -> Array[Match3Preloader.FallMovement]:
	var movements: Array[Match3Preloader.FallMovement] = []
	
	for column in grid_width:
		movements.append_array(calculate_fall_movements_on_column(column))
	
	return movements
	
#endregion

#region Swap
func swap_pieces_request(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:
	match swap_mode:
		Match3Preloader.BoardMovements.Adjacent:
			swap_adjacent(from_grid_cell, to_grid_cell)
		Match3Preloader.BoardMovements.Free:
			swap_free(from_grid_cell, to_grid_cell)
		Match3Preloader.BoardMovements.Cross:
			swap_cross(from_grid_cell, to_grid_cell)
		Match3Preloader.BoardMovements.CrossDiagonal:
			swap_cross_diagonal(from_grid_cell, to_grid_cell)
		_:
			unlock()


func swap_adjacent(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:
	if from_grid_cell.is_adjacent_to(to_grid_cell) && from_grid_cell.swap_piece_with(to_grid_cell):
		swap_pieces(from_grid_cell, to_grid_cell)
	else:
		swap_rejected.emit(from_grid_cell.current_piece as PieceUI, to_grid_cell.current_piece as PieceUI)
	
	
func swap_free(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:
	if from_grid_cell.swap_piece_with(to_grid_cell):
		swap_pieces(from_grid_cell, to_grid_cell)
	else:
		swap_rejected.emit(from_grid_cell.current_piece as PieceUI, to_grid_cell.current_piece as PieceUI)
		

func swap_cross(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:
	if (from_grid_cell.in_same_column_as(to_grid_cell) or from_grid_cell.in_same_row_as(to_grid_cell)) and from_grid_cell.swap_piece_with(to_grid_cell):
		swap_pieces(from_grid_cell, to_grid_cell)
	else:
		swap_rejected.emit(from_grid_cell.current_piece as PieceUI, to_grid_cell.current_piece as PieceUI)
		
		
func swap_cross_diagonal(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:	
	if cross_diagonal_cells_from(from_grid_cell).has(to_grid_cell):
		swap_pieces(from_grid_cell, to_grid_cell)
	else:
		swap_rejected.emit(from_grid_cell.current_piece as PieceUI, to_grid_cell.current_piece as PieceUI)
	
	
func swap_pieces(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:
	if from_grid_cell.can_swap_piece_with(to_grid_cell):
		var matches: Array[Sequence] = []
		
		for sequence: Sequence in PluginUtilities.remove_falsy_values([
			find_match_from_cell(from_grid_cell), 
			find_match_from_cell(to_grid_cell)
		]):
			matches.append(sequence)

		await piece_animator.swap_pieces(from_grid_cell.current_piece, to_grid_cell.current_piece)
		
		if matches.size() > 0:
			swapped_pieces.emit(from_grid_cell.current_piece, to_grid_cell.current_piece, matches)
		else:
			await piece_animator.swap_pieces(from_grid_cell.current_piece, to_grid_cell.current_piece)
			
			from_grid_cell.swap_piece_with(to_grid_cell)
			swap_rejected.emit(from_grid_cell.current_piece as PieceUI, to_grid_cell.current_piece as PieceUI)
		
		return
	
	swap_failed.emit(from_grid_cell, to_grid_cell)
	
#endregion

#region Lock related
func lock() -> void:
	is_locked = true
	
	lock_all_pieces()
	unselect_all_pieces()


func unlock() -> void:
	is_locked = false
	
	unlock_all_pieces()


func fall_pieces() -> void:
	await piece_animator.fall_down_pieces(calculate_all_fall_movements())

	
func fill_pieces() -> void:
	var empty_cells = pending_empty_cells_to_fill()
	
	if empty_cells.size() > 0:
		for empty_cell: GridCellUI in empty_cells:
			draw_random_piece_on_cell(empty_cell)
			
		var new_pieces: Array[PieceUI] = []
		new_pieces.assign(empty_cells.map(func(cell: GridCellUI): return cell.current_piece))
		
		await piece_animator.spawn_pieces(new_pieces)
		

func lock_all_pieces() -> void:
	for piece: PieceUI in PluginUtilities.find_nodes_of_custom_class(self, PieceUI):
		piece.lock()


func unlock_all_pieces() -> void:
	for piece: PieceUI in PluginUtilities.find_nodes_of_custom_class(self, PieceUI):
		piece.unlock()


func unselect_all_pieces() -> void:
	for piece: PieceUI in get_tree().get_nodes_in_group(PieceUI.GroupName):
		piece.is_selected = false

#endregion

#region Debug
func draw_preview_grid() -> void:
	if Engine.is_editor_hint() and preview_grid_in_editor:
		remove_preview_sprites()
		
		if debug_preview_node == null:
			debug_preview_node = Node2D.new()
			debug_preview_node.name = "BoardEditorPreview"
			add_child(debug_preview_node)
			PluginUtilities.set_owner_to_edited_scene_root(debug_preview_node)
			
		for column in grid_width:
			for row in grid_height:
				
				if empty_cells.has(Vector2(row, column)):
					continue
					
				var current_cell_sprite: Sprite2D = Sprite2D.new()
				current_cell_sprite.name = "Cell_Column%d_Row%d" % [column, row]
				current_cell_sprite.texture = even_cell_texture if (column + row) % 2 == 0 else odd_cell_texture
				current_cell_sprite.position = Vector2(cell_size.x * column + cell_offset.x, cell_size.y * row + cell_offset.y)
				
				debug_preview_node.add_child(current_cell_sprite)
				PluginUtilities.set_owner_to_edited_scene_root(current_cell_sprite)
				
				if current_cell_sprite.texture:
					var cell_texture_size = current_cell_sprite.texture.get_size()
					current_cell_sprite.scale = Vector2(cell_size.x / cell_texture_size.x, cell_size.y / cell_texture_size.y)
						
				if preview_pieces.size():
					var current_piece_sprite: Sprite2D = Sprite2D.new()
					current_piece_sprite.name = "Piece_Column%d_Row%d" % [column, row]
					current_piece_sprite.texture = preview_pieces.pick_random()
					current_piece_sprite.position = current_cell_sprite.position
					
					debug_preview_node.add_child(current_piece_sprite)
					PluginUtilities.set_owner_to_edited_scene_root(current_piece_sprite)
					
					if current_piece_sprite.texture:
						var piece_texture_size = current_piece_sprite.texture.get_size()
						## The 0.85 value it's to adjust the piece inside the cell reducing the scale size
						current_piece_sprite.scale = Vector2(cell_size.x / piece_texture_size.x, cell_size.y / piece_texture_size.y) * 0.85
						
					

func remove_preview_sprites() -> void:
	if Engine.is_editor_hint():
		if debug_preview_node:
			debug_preview_node.free()
			debug_preview_node = null
	
		for child: Node2D in get_children(true).filter(func(node: Node): return node is Node2D):
			child.free()
#endregion

#region Signal callbacks
func on_prepared_board() -> void:
	draw_board()
	update_grid_cells_neighbours()


func on_state_changed(from: Match3Preloader.BoardState, to: Match3Preloader.BoardState) -> void:
	match to:
		Match3Preloader.BoardState.WaitForInput:
			unlock()
		Match3Preloader.BoardState.Consume:
			lock()
			if pending_sequences.is_empty():
				pending_sequences = find_board_sequences()
			
			await sequence_consumer.consume_sequences(pending_sequences)
			await get_tree().process_frame
		
			current_state = Match3Preloader.BoardState.Fill
		Match3Preloader.BoardState.Fill:
			lock()
			pending_sequences.clear()
			await fall_pieces()
			await get_tree().process_frame
			await fill_pieces()
			
			pending_sequences = find_board_sequences()
			
			current_state = Match3Preloader.BoardState.WaitForInput if pending_sequences.is_empty() else Match3Preloader.BoardState.Consume
		

func on_swap_requested(from_piece: PieceUI, to_piece: PieceUI) -> void:
	current_selected_piece = null
	
	unselect_all_pieces()
	
	if not is_locked:
		var from_grid_cell: GridCellUI = grid_cell_from_piece(from_piece)
		var to_grid_cell: GridCellUI = grid_cell_from_piece(to_piece)
	
		if from_grid_cell and to_grid_cell and from_grid_cell.can_swap_piece_with(to_grid_cell):
			swap_pieces_request(from_grid_cell, to_grid_cell)
	
	
func on_swapped_pieces(_from: PieceUI, _to: PieceUI, matches: Array[Sequence]) -> void:
	pending_sequences = matches
	current_state = Match3Preloader.BoardState.Consume
	

func on_swap_failed(_from: PieceUI, _to: PieceUI) -> void:
	unlock()
	
	
func on_swap_rejected(_from: PieceUI, _to: PieceUI) -> void:
	unlock()


func on_consume_requested(sequence: Sequence) -> void:
	if is_locked:
		return
		
	if swap_mode == Match3Preloader.BoardMovements.ConnectLine:
		
		if sequence.size() >= min_match:
			pending_sequences = [sequence] as Array[Sequence]
			current_state = Match3Preloader.BoardState.Consume
	

func on_piece_selected(piece: PieceUI) -> void:
	if is_locked:
		return
	
	if current_selected_piece and current_selected_piece != piece:
		swap_requested.emit(current_selected_piece as PieceUI, piece as PieceUI)
		current_selected_piece = null
		cell_highlighter.remove_current_highlighters()
		return

		
	current_selected_piece = piece
	cell_highlighter.highlight_cells(grid_cell_from_piece(current_selected_piece), swap_mode)


func on_piece_unselected(_piece: PieceUI) -> void:
	if is_locked:
		return
		
	current_selected_piece = null
	cell_highlighter.remove_current_highlighters()
	
#endregion
