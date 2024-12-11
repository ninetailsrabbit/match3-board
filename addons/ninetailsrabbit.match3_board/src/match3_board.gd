@tool
@icon("res://addons/match3_board/assets/board.svg")
class_name Match3Board extends Node2D

class FallMovement:
	var from_cell: GridCellUI
	var to_cell: GridCellUI
	var is_diagonal: bool = false
	
	func _init(_from_cell: GridCellUI, _to_cell: GridCellUI, _is_diagonal: bool = false) -> void:
		from_cell = _from_cell
		to_cell = _to_cell
		is_diagonal = _is_diagonal
		
const MinGridWidth: int = 3
const MinGridHeight: int = 3
const BoardGroupName: String = "match3-board"

signal swapped_pieces(from: PieceUI, to: PieceUI, matches: Array[Sequence])
signal swap_requested(from: PieceUI, to: PieceUI)
signal swap_failed(from: GridCellUI, to: GridCellUI)
signal swap_rejected(from: PieceUI, to: PieceUI)
signal consume_requested(sequence: Sequence)
signal consumed_sequence(sequence: Sequence)
signal consumed_sequences(sequence: Array[Sequence])
signal piece_selected(piece: PieceUI)
signal piece_unselected(piece: PieceUI)
signal piece_holded(piece: PieceUI)
signal piece_released(piece: PieceUI)
signal added_piece_to_line_connector(piece: PieceUI)
signal canceled_line_connector_match(selected_pieces: Array[PieceUI])
signal state_changed(from: BoardState, to: BoardState)
signal prepared_board
signal drawed_board
signal movement_consumed
signal finished_available_movements
signal locked
signal unlocked

enum BoardState {
	WaitForInput,
	Fill,
	Consume
}


@export_group("Editor Debug 🪲")
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

## When this enabled, a random color placeholder textures are created based on the number of 
## available pieces
@export var use_placeholder_textures: bool = true:
	set(value):
		if use_placeholder_textures != value:
			use_placeholder_textures = value
			draw_preview_grid()
@export var placeholder_textures_colors: Array[Color] = [
	Color.WHEAT,
	Color.NAVY_BLUE,
	Color.YELLOW_GREEN,
	Color.YELLOW,
	Color.BLACK,
	Color.PURPLE,
	Color.BLACK,
	Color.WHITE,
	Color.RED,
	Color.SADDLE_BROWN
]:
	set(value):
		if placeholder_textures_colors != value:
			placeholder_textures_colors = value
			draw_preview_grid()

@export var preview_pieces: Array[Texture2D]:
	set(value):
		if preview_pieces != value:
			preview_pieces = value
			draw_preview_grid()
@export var odd_cell_texture: Texture2D = Match3Preloader.OddCellTexture:
	set(value):
		if odd_cell_texture != value:
			odd_cell_texture = value
			draw_preview_grid()
@export var even_cell_texture: Texture2D = Match3Preloader.EvenCellTexture:
	set(value):
		if even_cell_texture != value:
			even_cell_texture = value
			draw_preview_grid()
@export var empty_cell_texture: Texture2D:
	set(value):
		if empty_cell_texture != value:
			empty_cell_texture = value
			draw_preview_grid()
@export_group("Size 🔲")
@export var grid_width: int = 8:
		set(value):
			if grid_width != value:
				grid_width = maxi(MinGridWidth, value)
				draw_preview_grid()
@export var grid_height: int = 7:
		set(value):
			if grid_height != value:
				grid_height = maxi(MinGridHeight, value)
				draw_preview_grid()
@export var cell_size: Vector2i = Vector2i(48, 48):
		set(value):
			if cell_size != value:
				cell_size = value
				draw_preview_grid()
@export var cell_offset: Vector2i = Vector2i(25, 25):
	set(value):
		if cell_offset != value:
			cell_offset = value
			draw_preview_grid()
@export var empty_cells: Array[Vector2] = []:
	set(value):
		if empty_cells != value:
			empty_cells = value
			draw_preview_grid()
@export var draw_background_texture_on_empty_cells: bool = true
@export_group("Configuration 💎")
@export var configuration: Match3Configuration

#region Components
var piece_weight_generator: PieceWeightGenerator
var piece_animator: PieceAnimator
var sequence_consumer: SequenceConsumer
var cell_highlighter: CellHighlighter
#endregion

var debug_preview_node: Node2D
var grid_cells: Array = [] # Multidimensional to access cells by column & row
var grid_cells_flattened: Array[GridCellUI] = []
var current_selected_piece: PieceUI
var line_connector: LineConnector
var is_locked: bool = false:
	set(value):
		if value != is_locked:
			is_locked = value
			
			if is_locked:
				locked.emit()
			else:
				unlocked.emit()

var current_state: BoardState = BoardState.WaitForInput:
	set(new_state):
		if new_state != current_state:
			var previous_state: BoardState = current_state
			current_state = new_state
			state_changed.emit(previous_state, current_state)
		
var current_available_moves: int = 0:
	set(value):
		if value != current_available_moves:
			if value < current_available_moves:
				movement_consumed.emit()
			
			elif value == 0:
				finished_available_movements.emit()
				
			current_available_moves = clamp(value, 0, configuration.available_moves_on_start)


var pending_sequences: Array[Sequence] = []
var prepared: bool = false
var drawed: bool = false


func _input(event: InputEvent) -> void:
	if is_locked:
		return
		
	handle_line_connector_input(event)
	
	
func _enter_tree() -> void:
	remove_preview_sprites()
	
	if not Engine.is_editor_hint():
		add_to_group(BoardGroupName)
		
		current_available_moves = configuration.available_moves_on_start
		
		if piece_weight_generator == null:
			piece_weight_generator = PieceWeightGenerator.new()
			
		if cell_highlighter == null:
			change_cell_highlighter(CellHighlighter.new())
			
		if piece_animator == null:
			change_piece_animator(PieceAnimator.new())
			
		if sequence_consumer == null:
			change_sequence_consumer(SequenceConsumer.new())
			
		prepared_board.connect(on_prepared_board)
		
		piece_selected.connect(on_piece_selected)
		piece_unselected.connect(on_piece_unselected)
		piece_holded.connect(on_piece_holded)
		piece_released.connect(on_piece_released)
		
		swap_requested.connect(on_swap_requested)
		swap_failed.connect(on_swap_failed)
		swap_rejected.connect(on_swap_rejected)
		swapped_pieces.connect(on_swapped_pieces)
		
		consume_requested.connect(on_consume_requested)
		
		state_changed.connect(on_state_changed)
	

func _ready() -> void:
	assert(configuration is Match3Configuration, "Match3Board: This board needs a valid Match3Configuration resource to be drawed in the scene")
	
	if not Engine.is_editor_hint():
		if not InputMap.has_action(configuration.input_action_consume_line_connector):
			push_warning("Match3Board: The input action %s to consume a line connection does not exist, it will not be possible to consume a line connector manually" % configuration.input_action_consume_line_connector)

		if not InputMap.has_action(configuration.input_action_cancel_line_connector):
			push_warning("Match3Board: The input action %s to cancel a line connection does not exist, it will not be possible to cancel a line connector manually" % configuration.input_action_cancel_line_connector)

		if configuration.auto_start:
			prepare_board()
	

func distance() -> int:
	return grid_width + grid_height
	

func size() -> int:
	return grid_width * grid_height

#region Component setters
func change_piece_animator(animator: PieceAnimator) -> Match3Board:
	if piece_animator != null and piece_animator.is_inside_tree():
		piece_animator.free()
		
	piece_animator = animator
	
	if piece_animator is PieceAnimator:
		piece_animator.animation_started.connect(on_animation_started)
		piece_animator.animation_finished.connect(on_animation_finished)
	
	add_child(piece_animator)
	
	return self
	

func change_cell_highlighter(highlighter: CellHighlighter) -> Match3Board:
	if cell_highlighter != null and cell_highlighter.is_inside_tree():
		cell_highlighter.free()
		
	cell_highlighter = highlighter
	
	add_child(cell_highlighter)
	
	return self
	

func change_sequence_consumer(consumer: SequenceConsumer) -> Match3Board:
	if sequence_consumer != null and sequence_consumer.is_inside_tree():
		sequence_consumer.free()
		
	sequence_consumer = consumer
	
	add_child(sequence_consumer)
	
	sequence_consumer.consumed_sequence.connect(on_consumed_sequence)
	sequence_consumer.consumed_sequences.connect(on_consumed_sequences)
	
	return self
#endregion

#region Board
## Only prepares the grid cells based on width and height configuration parameters
func prepare_board():
	if not prepared and grid_cells.is_empty():
		for column in grid_width:
			grid_cells.append([])
			
			for row in grid_height:
				var grid_cell: GridCellUI = GridCellUI.new(row, column)
				grid_cell.cell_size = cell_size
				grid_cells[column].append(grid_cell)
		
		grid_cells_flattened.append_array(Match3BoardPluginUtilities.flatten(grid_cells))
		
		add_pieces(configuration.available_pieces)
		
		prepared = true
		prepared_board.emit()
		
	return self


func add_pieces(new_pieces: Array[PieceWeight]) -> void:
	piece_weight_generator.add_available_pieces(new_pieces)


func draw_board():
	if drawed:
		return
		
	for grid_cell: GridCellUI in grid_cells_flattened:
		draw_grid_cell(grid_cell)
		draw_random_piece_on_cell(grid_cell)
		
	if configuration.allow_matches_on_start:
		current_state = BoardState.Consume
	else:
		remove_matches_from_board()
	
	drawed = true
	drawed_board.emit()
	
	return self


func remove_matches_from_board() -> void:
	var sequences: Array[Sequence] = find_board_sequences()
	
	while sequences.size() > 0:
		for sequence: Sequence in sequences:
			var cells_to_change = sequence.cells.slice(0, (sequence.cells.size() / configuration.min_match) + 1)
			var piece_exceptions: Array[PieceWeight] = []
			var piece_id_exceptions: Array[StringName] = []
			piece_id_exceptions.assign(Match3BoardPluginUtilities.remove_duplicates(cells_to_change.map(func(cell: GridCellUI): return cell.current_piece.piece_definition.id)))
			
			for id: StringName in piece_id_exceptions:
				piece_exceptions.append(piece_weight_generator.piece_id_mapper[id])
			
			for current_cell: GridCellUI in cells_to_change:
				var removed_piece = current_cell.remove_piece()
				removed_piece.free()
				draw_random_piece_on_cell(current_cell, piece_exceptions)
		
		sequences = find_board_sequences()


func draw_grid_cell(grid_cell: GridCellUI) -> void:
	if not grid_cell.is_inside_tree():
		add_child(grid_cell)
		grid_cell.position = Vector2(grid_cell.cell_size.x * grid_cell.column + cell_offset.x, grid_cell.cell_size.y * grid_cell.row + cell_offset.y)
		grid_cell.can_contain_piece = not grid_cell.board_position() in empty_cells
		

func draw_random_piece_on_cell(grid_cell: GridCellUI, except: Array[PieceWeight] = []) -> void:
	if grid_cell.can_contain_piece:
		var new_piece: PieceUI =  piece_weight_generator.roll(configuration.not_disabled_pieces())
		draw_piece_on_cell(grid_cell, new_piece)


func draw_piece_on_position(column: int, row: int, new_piece: PieceUI, animate: bool = true) -> void:
	var grid_cell: GridCellUI = get_cell_or_null(column, row)
	draw_piece_on_cell(grid_cell, new_piece)
	if animate:
		await piece_animator.spawn_piece(grid_cell, new_piece)


func draw_piece_on_cell(grid_cell: GridCellUI, new_piece: PieceUI) -> void:
	if grid_cell.can_contain_piece:
		new_piece.board = self
		new_piece.position = grid_cell.position
		
		add_child(new_piece)
		var old_piece: PieceUI = grid_cell.replace_piece(new_piece)
		if old_piece:
			old_piece.queue_free()
#endregion

#region Line Connector
func handle_line_connector_input(event: InputEvent) -> void:
	if is_swap_mode_connect_line() and is_click_mode_selection() and line_connector != null:
		if InputMap.has_action(configuration.input_action_consume_line_connector) and Input.is_action_just_pressed(configuration.input_action_consume_line_connector) \
			or event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			line_connector.consume_matches()
	
		elif InputMap.has_action(configuration.input_action_cancel_line_connector) and Input.is_action_just_pressed(configuration.input_action_cancel_line_connector) \
			or event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			line_connector.cancel()
				
			
func draw_line_connector(origin_piece: PieceUI) -> void:
	if is_swap_mode_connect_line() and line_connector == null and not origin_piece.can_be("triggered"):
		line_connector = LineConnector.new()
		line_connector.board = self
		get_tree().root.add_child(line_connector)
		line_connector.tree_exited.connect(remove_line_connector)
		line_connector.add_piece(origin_piece)
		line_connector.added_piece.connect(func(piece: PieceUI): added_piece_to_line_connector.emit(piece))
		line_connector.canceled_match.connect(func(pieces: Array[PieceUI]): canceled_line_connector_match.emit(pieces))
		

func remove_line_connector() -> void:
	line_connector = null
#endregion

#region Cells
func get_cell_or_null(column: int, row: int):
	if not grid_cells.is_empty() and column >= 0 and row >= 0:
		if column <= grid_cells.size() - 1 and row <= grid_cells[0].size() - 1:
			return grid_cells[column][row]
			
	return null
	
	
func cross_cells_from(origin_cell: GridCellUI) -> Array[GridCellUI]:
	var cross_cells: Array[GridCellUI] = []
	cross_cells.assign(Match3BoardPluginUtilities.remove_duplicates(
		grid_cells_from_row(origin_cell.row) + grid_cells_from_column(origin_cell.column))
	)
	
	return cross_cells


func cross_diagonal_cells_from(origin_cell: GridCellUI) -> Array[GridCellUI]:
	var distance: int = distance()
	var cross_diagonal_cells: Array[GridCellUI] = []
	
	cross_diagonal_cells.assign(Match3BoardPluginUtilities.remove_falsy_values(Match3BoardPluginUtilities.remove_duplicates(
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


func grid_cells_from_sequences(sequences: Array[Sequence]) -> Array[GridCellUI]:
	var cells: Array[GridCellUI] = []
	cells.assign(Match3BoardPluginUtilities.remove_duplicates(
		Match3BoardPluginUtilities.flatten(pending_sequences.map(func(sequence: Sequence): return sequence.cells)))
	)
	
	return cells
	
	
func grid_cell_from_piece(piece: PieceUI):
	var found_pieces = grid_cells_flattened.filter(
		func(cell: GridCellUI): return cell.has_piece() and cell.current_piece == piece
	)
	
	if found_pieces.size() == 1:
		return found_pieces.front()
	
	return null
	

func grid_cells_from_pieces(pieces: Array[PieceUI]) -> Array[GridCellUI]:
	var cells: Array[GridCellUI] = []
	cells.assign(Match3BoardPluginUtilities.remove_falsy_values(pieces.map(func(piece: PieceUI): return piece.cell())))
	
	return cells
	
	
func grid_cells_from_row(row: int) -> Array[GridCellUI]:
	var cells: Array[GridCellUI] = []
	
	if grid_cells.size() > 0 and Match3BoardPluginUtilities.value_is_between(row, 0, grid_height - 1):
		for column: int in grid_width:
			cells.append(grid_cells[column][row])
	
	return cells
	

func grid_cells_from_column(column: int) -> Array[GridCellUI]:
	var cells: Array[GridCellUI] = []
		
	if grid_cells.size() > 0 and Match3BoardPluginUtilities.value_is_between(column, 0, grid_width - 1):
		for row: int in grid_height:
			cells.append(grid_cells[column][row])
	
	return cells


func adjacent_cells_from(origin_cell: GridCellUI) -> Array[GridCellUI]:
	return origin_cell.available_neighbours(false)
	
	
func first_movable_cell_on_column(column: int):
	var cells: Array[GridCellUI] = grid_cells_from_column(column)
	cells.reverse()
	
	var movable_cells = cells.filter(
		func(cell: GridCellUI): 
			return cell.has_piece() and cell.current_piece.can_be("moved") and (cell.neighbour_bottom and cell.neighbour_bottom.is_empty())
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
func start_consume_sequence_pipeline() -> void:
	if pending_sequences.is_empty():
		pending_sequences = find_board_sequences()
		
		if pending_sequences.is_empty():
			current_state = BoardState.Fill
			return

	sequence_consumer.consume_sequences(pending_sequences)

@warning_ignore("unassigned_variable")
func find_horizontal_sequences(cells: Array[GridCellUI]) -> Array[Sequence]:
	var sequences: Array[Sequence] = []
	var current_matches: Array[GridCellUI] = []
	
	if configuration.horizontal_shape:
		var valid_cells = cells.filter(func(cell: GridCellUI): return cell.has_piece())
		var previous_cell: GridCellUI
		
		for current_cell: GridCellUI in valid_cells:
			
			if current_matches.is_empty() \
				or (previous_cell is GridCellUI and previous_cell.is_row_neighbour_of(current_cell) and current_cell.current_piece.match_with(previous_cell.current_piece)):
				current_matches.append(current_cell)
				
				if current_matches.size() == configuration.max_match:
					sequences.append(Sequence.new(current_matches, Sequence.Shapes.Horizontal))
					current_matches.clear()
			else:
				if Match3BoardPluginUtilities.value_is_between(current_matches.size(), configuration.min_match, configuration.max_match):
					sequences.append(Sequence.new(current_matches, Sequence.Shapes.Horizontal))
				
				current_matches.clear()
				current_matches.append(current_cell)
			
			if current_cell == valid_cells.back() and Match3BoardPluginUtilities.value_is_between(current_matches.size(), configuration.min_match, configuration.max_match):
				sequences.append(Sequence.new(current_matches, Sequence.Shapes.Horizontal))
				
			previous_cell = current_cell
			
	sequences.sort_custom(_sort_by_size_descending)

	return sequences
	

@warning_ignore("unassigned_variable")
func find_vertical_sequences(cells: Array[GridCellUI]) -> Array[Sequence]:
	var sequences: Array[Sequence] = []
	var current_matches: Array[GridCellUI] = []
	
	if configuration.vertical_shape:
		var valid_cells = cells.filter(func(cell: GridCellUI): return cell.has_piece())
		var previous_cell: GridCellUI
		
		for current_cell: GridCellUI in valid_cells:
			
			if current_matches.is_empty() \
				or (previous_cell is GridCellUI and previous_cell.is_column_neighbour_of(current_cell) and current_cell.current_piece.match_with(previous_cell.current_piece)):
				current_matches.append(current_cell)
				
				if current_matches.size() == configuration.max_match:
					sequences.append(Sequence.new(current_matches, Sequence.Shapes.Vertical))
					current_matches.clear()
			else:
				if Match3BoardPluginUtilities.value_is_between(current_matches.size(), configuration.min_match, configuration.max_match):
					sequences.append(Sequence.new(current_matches, Sequence.Shapes.Vertical))
					
				current_matches.clear()
				current_matches.append(current_cell)
			
			if current_cell.in_same_grid_position_as(valid_cells.back().board_position()) and Match3BoardPluginUtilities.value_is_between(current_matches.size(), configuration.min_match, configuration.max_match):
				sequences.append(Sequence.new(current_matches, Sequence.Shapes.Vertical))
				
			previous_cell = current_cell
	
	
	sequences.sort_custom(_sort_by_size_descending)
	
	return sequences
	
	
func find_tshape_sequence(sequence_a: Sequence, sequence_b: Sequence):
	if configuration.tshape and sequence_a != sequence_b and  sequence_a.is_horizontal_or_vertical_shape() and sequence_b.is_horizontal_or_vertical_shape():
		var horizontal_sequence: Sequence = sequence_a if sequence_a.is_horizontal_shape() else sequence_b
		var vertical_sequence: Sequence = sequence_a if sequence_a.is_vertical_shape() else sequence_b
		
		if horizontal_sequence.is_horizontal_shape() and vertical_sequence.is_vertical_shape():
			var left_edge_cell: GridCellUI = horizontal_sequence.left_edge_cell()
			var right_edge_cell: GridCellUI = horizontal_sequence.right_edge_cell()
			var top_edge_cell: GridCellUI = vertical_sequence.top_edge_cell()
			var bottom_edge_cell: GridCellUI = vertical_sequence.bottom_edge_cell()
			var horizontal_middle_cell: GridCellUI = horizontal_sequence.middle_cell()
			var vertical_middle_cell: GridCellUI = vertical_sequence.middle_cell()

			var intersection_cell: GridCellUI = get_cell_or_null(vertical_middle_cell.column, horizontal_middle_cell.row)
			if intersection_cell in horizontal_sequence.cells and intersection_cell in vertical_sequence.cells and not (
				(left_edge_cell.in_same_position_as(intersection_cell) and top_edge_cell.in_same_position_as(intersection_cell)) \
				or (left_edge_cell.in_same_position_as(intersection_cell) and bottom_edge_cell.in_same_position_as(intersection_cell)) \
				or (right_edge_cell.in_same_position_as(intersection_cell) and top_edge_cell.in_same_position_as(intersection_cell)) \
				or (right_edge_cell.in_same_position_as(intersection_cell) and bottom_edge_cell.in_same_position_as(intersection_cell))
			):			
				var cells: Array[GridCellUI] = []
				
				## We need to iterate manually to be able append the item type on the array
				for cell: GridCellUI in Match3BoardPluginUtilities.remove_duplicates(horizontal_sequence.cells + vertical_sequence.cells):
					cells.append(cell)
								
				return Sequence.new(cells, Sequence.Shapes.TShape)
				
	return null


func find_lshape_sequence(sequence_a: Sequence, sequence_b: Sequence):
	if configuration.lshape and sequence_a != sequence_b and  sequence_a.is_horizontal_or_vertical_shape() and sequence_b.is_horizontal_or_vertical_shape():
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
				for cell: GridCellUI in Match3BoardPluginUtilities.remove_duplicates(horizontal_sequence.cells + vertical_sequence.cells):
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
			
	var result: Array[Sequence] = valid_horizontal_sequences + valid_vertical_sequences + tshape_sequences + lshape_sequences

	return clean_sequences(result)
	


func find_matches_from_swap(from_cell: GridCellUI, to_cell: GridCellUI) -> Array[Sequence]:
	var matches: Array[Sequence] = []
		
	var sequence_from: Sequence = find_match_from_cell(from_cell)
	var sequence_to: Sequence = find_match_from_cell(to_cell)

	matches.assign(Match3BoardPluginUtilities.remove_falsy_values([sequence_from, sequence_to]))
	
	return clean_sequences(matches)


func clean_sequences(sequences: Array[Sequence]) -> Array[Sequence]:
	var cleaned_result: Array[Sequence] = []

	sequences.sort_custom(func(a: Sequence, b: Sequence): return a.size() < b.size())

	for idx in sequences.size():
		var sequence = sequences[idx]
		var should_add = true
		for cell in sequence.cells:
			if not should_add:
				break
			for sub_idx in range(idx + 1, sequences.size()):
				if sequences[sub_idx].cells.has(cell):
					should_add = false
					break
		
		if should_add:
			cleaned_result.append(sequence)

	return cleaned_result


func find_matches_from_swapped_pieces(from: PieceUI, to: PieceUI) -> Array[Sequence]:
	return find_matches_from_swap(grid_cell_from_piece(from), grid_cell_from_piece(to))


func find_match_from_piece(piece: PieceUI):
	return find_match_from_cell(grid_cell_from_piece(piece))
	
	
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
func calculate_fall_movements_on_column(column: int) -> Array[FallMovement]:
	var cells: Array[GridCellUI] = grid_cells_from_column(column)
	var movements: Array[FallMovement] = []
	
	var from_cell: GridCellUI = first_movable_cell_on_column(column)
	var to_cell: GridCellUI = last_empty_cell_on_column(column)
	
	if from_cell and from_cell.has_piece() and to_cell:
		to_cell.replace_piece(from_cell.current_piece)
		from_cell.remove_piece()
		movements.append(FallMovement.new(from_cell, to_cell))
	
	return movements


func calculate_current_fall_movements() -> Array[FallMovement]:
	var movements: Array[FallMovement] = []
	
	for column in grid_width:
		movements.append_array(calculate_fall_movements_on_column(column))
	
	return movements
#endregion

#region Swap
func swap_pieces_request(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:
	match configuration.swap_mode:
		Match3Configuration.BoardMovements.Adjacent:
			swap_adjacent(from_grid_cell, to_grid_cell)
		Match3Configuration.BoardMovements.AdjacentWithDiagonals:
			swap_adjacent_with_diagonals(from_grid_cell, to_grid_cell)
		Match3Configuration.BoardMovements.AdjacentOnlyDiagonals:
			swap_adjacent_only_diagonals(from_grid_cell, to_grid_cell)
		Match3Configuration.BoardMovements.Free:
			swap_free(from_grid_cell, to_grid_cell)
		Match3Configuration.BoardMovements.Row:
			swap_row(from_grid_cell, to_grid_cell)
		Match3Configuration.BoardMovements.Column:
			swap_column(from_grid_cell, to_grid_cell)
		Match3Configuration.BoardMovements.Cross:
			swap_cross(from_grid_cell, to_grid_cell)
		Match3Configuration.BoardMovements.CrossDiagonal:
			swap_cross_diagonal(from_grid_cell, to_grid_cell)
		_:
			unlock()


func swap_adjacent(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:
	if from_grid_cell.is_adjacent_to(to_grid_cell) && from_grid_cell.swap_piece_with(to_grid_cell):
		swap_pieces(from_grid_cell, to_grid_cell)
	else:
		swap_rejected.emit(from_grid_cell.current_piece as PieceUI, to_grid_cell.current_piece as PieceUI)
	

func swap_adjacent_with_diagonals(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:
	if from_grid_cell.is_adjacent_to(to_grid_cell, true) && from_grid_cell.swap_piece_with(to_grid_cell):
		swap_pieces(from_grid_cell, to_grid_cell)
	else:
		swap_rejected.emit(from_grid_cell.current_piece as PieceUI, to_grid_cell.current_piece as PieceUI)
	
	
func swap_adjacent_only_diagonals(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:
	if from_grid_cell.in_diagonal_with(to_grid_cell) && from_grid_cell.swap_piece_with(to_grid_cell):
		swap_pieces(from_grid_cell, to_grid_cell)
	else:
		swap_rejected.emit(from_grid_cell.current_piece as PieceUI, to_grid_cell.current_piece as PieceUI)
	

func swap_free(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:
	if from_grid_cell.swap_piece_with(to_grid_cell):
		swap_pieces(from_grid_cell, to_grid_cell)
	else:
		swap_rejected.emit(from_grid_cell.current_piece as PieceUI, to_grid_cell.current_piece as PieceUI)


func swap_row(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:
	if from_grid_cell.in_same_row_as(to_grid_cell) and from_grid_cell.swap_piece_with(to_grid_cell):
		swap_pieces(from_grid_cell, to_grid_cell)
	else:
		swap_rejected.emit(from_grid_cell.current_piece as PieceUI, to_grid_cell.current_piece as PieceUI)
		

func swap_column(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:
	if from_grid_cell.in_same_column_as(to_grid_cell) and from_grid_cell.swap_piece_with(to_grid_cell):
		swap_pieces(from_grid_cell, to_grid_cell)
	else:
		swap_rejected.emit(from_grid_cell.current_piece as PieceUI, to_grid_cell.current_piece as PieceUI)
		

func swap_cross(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:
	if (from_grid_cell.in_same_column_as(to_grid_cell) or from_grid_cell.in_same_row_as(to_grid_cell)) and from_grid_cell.swap_piece_with(to_grid_cell):
		swap_pieces(from_grid_cell, to_grid_cell)
	else:
		swap_rejected.emit(from_grid_cell.current_piece as PieceUI, to_grid_cell.current_piece as PieceUI)
		
		
func swap_cross_diagonal(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:
	if cross_diagonal_cells_from(from_grid_cell).has(to_grid_cell) and from_grid_cell.swap_piece_with(to_grid_cell):
		swap_pieces(from_grid_cell, to_grid_cell)
	else:
		swap_rejected.emit(from_grid_cell.current_piece as PieceUI, to_grid_cell.current_piece as PieceUI)
	
	
func swap_pieces(from_grid_cell: GridCellUI, to_grid_cell: GridCellUI) -> void:
	if from_grid_cell.can_swap_piece_with(to_grid_cell):
		var matches: Array[Sequence] = []
		
		from_grid_cell.current_piece.combined_with = to_grid_cell.current_piece
		to_grid_cell.current_piece.combined_with = from_grid_cell.current_piece
		
		var sequence_from = from_grid_cell.current_piece.on_swap_with(to_grid_cell.current_piece)
		var sequence_to = to_grid_cell.current_piece.on_swap_with(from_grid_cell.current_piece)
		
		if sequence_from:
			matches.append(sequence_from)
		elif sequence_to:
			matches.append(sequence_to)
		else:
			matches = find_matches_from_swap(from_grid_cell, to_grid_cell)

		await piece_animator.swap_pieces(from_grid_cell.current_piece, to_grid_cell.current_piece)
		
		if matches.size() > 0:
			swapped_pieces.emit(from_grid_cell.current_piece, to_grid_cell.current_piece, matches)
		else:
			if configuration.reset_position_on_swap_failed:
				await piece_animator.swap_pieces(from_grid_cell.current_piece, to_grid_cell.current_piece)
				
				from_grid_cell.swap_piece_with(to_grid_cell)
				swap_rejected.emit(from_grid_cell.current_piece as PieceUI, to_grid_cell.current_piece as PieceUI)
	else:
		swap_failed.emit(from_grid_cell, to_grid_cell)
#endregion

#region Lock related
func lock() -> void:
	#if current_selected_piece != null and is_instance_valid(current_selected_piece) and current_selected_piece.is_selected:
		#current_selected_piece.is_selected = false
		#current_selected_piece.reset_position()
	#
	is_locked = true
	current_selected_piece = null
	
	unselect_all_pieces()
	

func unlock() -> void:
	is_locked = false
	

func unselect_all_pieces() -> void:
	for piece: PieceUI in pieces():
		piece.is_selected = false


func reset_all_pieces_positions() -> void:
	for piece: PieceUI in pieces():
		piece.reset_position()

#endregion

#region Pieces
func pieces() -> Array[PieceUI]:
	var pieces: Array[PieceUI] = []
	pieces.assign(get_tree().get_nodes_in_group(PieceUI.GroupName))
	
	return pieces.filter(func(piece: PieceUI): return is_instance_valid(piece))


func pieces_of_shape(shape: String) -> Array[PieceUI]:
	print("pieces_of_shape: ", shape)
	var pieces: Array[PieceUI] = []
	pieces.assign(pieces().filter(func(piece: PieceUI): return piece.piece_definition.shape == shape))
	
	return pieces


func fall_pieces() -> void:
	var fall_movements: Array[FallMovement] = []
	
	while grid_cells_flattened.any(
		func(cell: GridCellUI): 
			return cell.has_piece() and cell.current_piece.can_be("moved") and (cell.neighbour_bottom and cell.neighbour_bottom.can_contain_piece and cell.neighbour_bottom.is_empty())
			):
				fall_movements = calculate_current_fall_movements()
				await piece_animator.fall_down_pieces(fall_movements)


func fill_pieces() -> void:
	var empty_cells = pending_empty_cells_to_fill()
	
	if empty_cells.size() > 0:
		for empty_cell: GridCellUI in empty_cells:
			draw_random_piece_on_cell(empty_cell)
			
		var new_pieces: Array[PieceUI] = []
		new_pieces.assign(empty_cells.map(func(cell: GridCellUI): return cell.current_piece))
		
		await piece_animator.spawn_pieces(new_pieces)


func remove_orphan_pieces() -> void:
	for orphan_piece: PieceUI in get_tree().get_nodes_in_group(PieceUI.GroupName).filter(func(node: Node): return node.cell() == null):
		orphan_piece.queue_free()
#endregion

#region Information & States
func state_is_wait_for_input() -> bool:
	return current_state == BoardState.WaitForInput


func state_is_consume() -> bool:
	return current_state == BoardState.Consume


func state_is_fill() -> bool:
	return current_state == BoardState.Fill


func is_click_mode_selection() -> bool:
	return configuration.is_click_mode_selection()
	

func is_click_mode_drag() -> bool:
	return configuration.is_click_mode_drag()
	

func is_swap_mode_adjacent() -> bool:
	return configuration.is_swap_mode_adjacent()
	
	
func is_swap_mode_adjacent_with_diagonals() -> bool:
	return configuration.is_swap_mode_adjacent_with_diagonals()
	
	
func is_swap_mode_adjacent_only_diagonals() -> bool:
	return configuration.is_swap_mode_adjacent_only_diagonals()
	

func is_swap_mode_free() -> bool:
	return configuration.is_swap_mode_free()


func is_swap_mode_cross() -> bool:
	return configuration.is_swap_mode_cross()
	
	
func is_swap_mode_cross_diagonal() -> bool:
	return configuration.is_swap_mode_cross_diagonal()
	
	
func is_swap_mode_connect_line() -> bool:
	return configuration.is_swap_mode_connect_line()
#endregion

#region Debug
func draw_preview_grid() -> void:
	if Engine.is_editor_hint() and preview_grid_in_editor and is_inside_tree():
		remove_preview_sprites()
		
		if debug_preview_node == null:
			debug_preview_node = Node2D.new()
			debug_preview_node.name = "BoardEditorPreview"
			add_child(debug_preview_node)
			Match3BoardPluginUtilities.set_owner_to_edited_scene_root(debug_preview_node)
			
		for column in grid_width:
			for row in grid_height:
		
				var current_cell_sprite: Sprite2D = Sprite2D.new()
				current_cell_sprite.name = "Cell_Column%d_Row%d" % [column, row]
				
				if use_placeholder_textures:
					current_cell_sprite.texture = PlaceholderTexture2D.new()
					current_cell_sprite.texture.size = cell_size
					
					if not placeholder_textures_colors.is_empty():
						current_cell_sprite.self_modulate = placeholder_textures_colors.pick_random()
				else:
					if empty_cells.has(Vector2(row, column)):
						current_cell_sprite.texture = empty_cell_texture
					elif even_cell_texture and odd_cell_texture:
						current_cell_sprite.texture = even_cell_texture if (column + row) % 2 == 0 else odd_cell_texture
					else:
						current_cell_sprite.texture = even_cell_texture if even_cell_texture else odd_cell_texture
						
				current_cell_sprite.position = Vector2(cell_size.x * column + cell_offset.x, cell_size.y * row + cell_offset.y)
				
				debug_preview_node.add_child(current_cell_sprite)
				Match3BoardPluginUtilities.set_owner_to_edited_scene_root(current_cell_sprite)
				
				if current_cell_sprite.texture:
					var cell_texture_size = current_cell_sprite.texture.get_size()
					current_cell_sprite.scale = Vector2(cell_size.x / cell_texture_size.x, cell_size.y / cell_texture_size.y)
				
				var available_preview_pieces = Match3BoardPluginUtilities.remove_falsy_values(preview_pieces)
				
				if available_preview_pieces.size() > 0 and not use_placeholder_textures:
					var current_piece_sprite: Sprite2D = Sprite2D.new()
					current_piece_sprite.name = "Piece_Column%d_Row%d" % [column, row]
					current_piece_sprite.texture = available_preview_pieces.pick_random()
					current_piece_sprite.position = current_cell_sprite.position
					
					debug_preview_node.add_child(current_piece_sprite)
					Match3BoardPluginUtilities.set_owner_to_edited_scene_root(current_piece_sprite)
					
					if current_piece_sprite.texture:
						var piece_texture_size = current_piece_sprite.texture.get_size()
						## The 0.85 value it's to adjust the piece inside the cell reducing the scale size
						current_piece_sprite.scale = Vector2(cell_size.x / piece_texture_size.x, cell_size.y / piece_texture_size.y) * 0.85
						
					

func remove_preview_sprites() -> void:
	if Engine.is_editor_hint():
		if debug_preview_node:
			debug_preview_node.free()
			debug_preview_node = null
	
	for child: Node in get_children():
		child.free()
#endregion


#region Signal callbacks
func on_prepared_board() -> void:
	draw_board()
	update_grid_cells_neighbours()


func on_state_changed(from: BoardState, to: BoardState) -> void:
	match to:
		BoardState.WaitForInput:
			current_available_moves -= 1
			remove_orphan_pieces()
			unselect_all_pieces()
			reset_all_pieces_positions()
			await get_tree().create_timer(0.15).timeout
			unlock()
		BoardState.Consume:
			lock()
			start_consume_sequence_pipeline()
		BoardState.Fill:
			if pending_empty_cells_to_fill().is_empty():
				current_state = BoardState.WaitForInput
			else:
				lock()
				remove_orphan_pieces()
				
				await fall_pieces()
				await get_tree().process_frame
				await fill_pieces()

				pending_sequences += find_board_sequences() 
				current_state = BoardState.WaitForInput if pending_sequences.is_empty() else BoardState.Consume
		
	
func on_swap_requested(from_piece: PieceUI, to_piece: PieceUI) -> void:
	if current_selected_piece != null and is_instance_valid(current_selected_piece):
		current_selected_piece.is_selected = false
		current_selected_piece = null
	
	unselect_all_pieces()
	
	if is_locked:
		return
		
	var from_grid_cell: GridCellUI = grid_cell_from_piece(from_piece)
	var to_grid_cell: GridCellUI = grid_cell_from_piece(to_piece)
	
	if from_grid_cell and to_grid_cell and from_grid_cell.can_swap_piece_with(to_grid_cell):
		swap_pieces_request(from_grid_cell, to_grid_cell)

	
func on_swapped_pieces(from: PieceUI, to: PieceUI, matches: Array[Sequence] = []) -> void:
	if matches.is_empty():
		matches = find_matches_from_swapped_pieces(from, to)
	
	pending_sequences = matches
	
	current_state = BoardState.Consume
	

func on_swap_failed(_from: PieceUI, _to: PieceUI) -> void:
	unlock()
	
	
func on_swap_rejected(_from: PieceUI, _to: PieceUI) -> void:
	unlock()


func on_consume_requested(sequence: Sequence) -> void:
	pending_sequences.append(sequence)
	
	if state_is_consume():
		start_consume_sequence_pipeline()
	else:
		current_state = BoardState.Consume


func on_consumed_sequence(sequence: Sequence) -> void:
	pending_sequences.erase(sequence)


func on_consumed_sequences(sequences: Array[Sequence]) -> void:
	pending_sequences.clear()
	current_state = BoardState.Fill


func on_piece_selected(piece: PieceUI) -> void:
	if is_locked or is_click_mode_drag() or piece.can_be("triggered"):
		return
	
	draw_line_connector(piece)

	if current_selected_piece and current_selected_piece != piece:
		swap_requested.emit(current_selected_piece as PieceUI, piece as PieceUI)
		current_selected_piece = null
		cell_highlighter.remove_current_highlighters()
		return
	
	current_selected_piece = piece
	cell_highlighter.highlight_cells_from_origin_cell(grid_cell_from_piece(current_selected_piece), configuration.swap_mode)
	

func on_piece_unselected(_piece: PieceUI) -> void:
	if is_locked:
		return
	
	current_selected_piece = null
	cell_highlighter.remove_current_highlighters()
	
	
func on_piece_holded(piece: PieceUI) -> void:
	if is_locked or is_click_mode_selection() or current_selected_piece != null or piece.can_be("triggered"):
		return
	
	draw_line_connector(piece)
	
	current_selected_piece = piece
	cell_highlighter.highlight_cells_from_origin_cell(grid_cell_from_piece(current_selected_piece), configuration.swap_mode)
	

func on_piece_released(piece: PieceUI) -> void:
	if is_locked or is_click_mode_selection():
		return
	
	current_selected_piece = null
	
	if is_swap_mode_connect_line():
		if line_connector != null:
			line_connector.consume_matches()
	else:
		var other_piece = piece.detect_near_piece()
		
		if other_piece is PieceUI:
			swap_requested.emit(piece, other_piece)
			
			
func on_animation_started() -> void:
	lock()


func on_animation_finished() -> void:
	await get_tree().create_timer(0.15).timeout
	
	if state_is_wait_for_input() and is_locked:
		unlock()
	
#endregion
