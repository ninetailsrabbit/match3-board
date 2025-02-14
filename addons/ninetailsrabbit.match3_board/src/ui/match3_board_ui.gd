class_name Match3BoardUI extends Node2D

const GroupName: StringName = &"match3-board"

signal state_changed(from: BoardState, to: BoardState)
signal swap_accepted(from: Match3GridCellUI, to: Match3GridCellUI)
signal swap_rejected(from: Match3GridCellUI, to: Match3GridCellUI)
signal consumed_sequence(sequence: Match3Sequence)
signal consumed_sequences(sequences: Array[Match3Sequence])
signal selected_piece(piece: Match3PieceUI)
signal unselected_piece(piece: Match3PieceUI)
signal piece_drag_started(piece: Match3PieceUI)
signal piece_drag_ended(piece: Match3PieceUI)
signal drawed_cells
signal drawed_pieces
signal locked
signal unlocked
signal movement_consumed
signal finished_available_movements

@export var configuration: Match3BoardConfiguration
@export var animator: Match3Animator
@export var highlighter: Match3Highlighter
@export var line_connector: Match3LineConnector

enum BoardState {
	WaitForInput,
	Consume,
	SpecialConsume,
	Fall,
	Fill
}
#
var grid_cells: Array = [] # Multidimensional to access cells by column & row
var grid_cells_flattened: Array[Match3GridCellUI] = []
var finder: Match3BoardFinder = Match3BoardFinder.new(self)
var fall_mover: Match3FallMover = Match3FallMover.new(self)
var filler: Match3Filler = Match3Filler.new(self)
var sequence_detector: Match3SequenceDetector = Match3SequenceDetector.new(self)
var sequence_consumer: Match3SequenceConsumer
var piece_generator: Match3PieceGenerator = Match3PieceGenerator.new()

var current_available_moves: int = 0:
	set(value):
		if value != current_available_moves:
			if value == -1:
				current_available_moves = value
				return
				
			var previous_moves: int = current_available_moves
			current_available_moves = clamp(value, 0, configuration.available_moves_on_start)
			
			if value < previous_moves:
				movement_consumed.emit()
			
			elif value == 0:
				finished_available_movements.emit()
			

var pending_special_pieces: Array[Match3PieceUI] = []
var current_selected_piece: Match3PieceUI:
	set(new_piece):
		if new_piece != current_selected_piece:
			var previous_piece := current_selected_piece
			current_selected_piece = new_piece
			
			if current_selected_piece == null:
				unselected_piece.emit(previous_piece)
			else:
				selected_piece.emit(current_selected_piece)
	
			
var current_state: BoardState = BoardState.WaitForInput:
	set(new_state):
		if new_state != current_state:
			var previous_state: BoardState = current_state
			current_state = new_state
			state_changed.emit(previous_state, current_state)

var is_locked: bool = false:
	set(value):
		if value != is_locked:
			is_locked = value
			
			if is_locked:
				locked.emit()
			else:
				unlocked.emit()


func _enter_tree() -> void:
	add_to_group(GroupName)
	child_entered_tree.connect(on_child_entered_tree)


func _ready() -> void:
	assert(configuration != null, "Match3BoardUI: This board needs a configuration")
	
	if configuration.swap_mode_is_connect_line():
		assert(line_connector != null, "Match3BoardUI: The swap mode ConnectLine needs a line connector in this board")
	
	sequence_consumer = Match3SequenceConsumer.new(self, configuration.sequence_rules)
	current_available_moves = configuration.available_moves_on_start
	
	add_pieces_to_generator(configuration.available_pieces)

	swap_accepted.connect(on_swap_accepted)
	swap_rejected.connect(on_swap_rejected)
	locked.connect(on_board_locked)
	unlocked.connect(on_board_unlocked)
	state_changed.connect(on_board_state_changed)
	drawed_pieces.connect(on_drawed_pieces)
	
	if line_connector:
		line_connector.canceled_match.connect(on_line_connector_canceled_match)
	
	if configuration.auto_start:
		draw_cells().draw_pieces()
		
		
	const special = preload("res://addons/ninetailsrabbit.match3_board/demo/pieces/special_blue_piece_configuration.tres")
	
	#for i in range(2):
	draw_piece_on_cell(finder.get_cell(2, 2), Match3PieceUI.from_configuration(special), true)
		#draw_piece_on_cell(finder.get_cell(2, 5), Match3PieceUI.from_configuration(special), true)


func distance() -> int:
	return configuration.grid_width + configuration.grid_height
	

func size() -> int:
	return configuration.grid_width * configuration.grid_height


func travel_to(new_state: BoardState) -> void:
	current_state = new_state


func lock() -> void:
	is_locked = true


func unlock() -> void:
	is_locked = false


#region Draw 
func draw_cells() -> Match3BoardUI:
	if grid_cells.is_empty():
		for column in configuration.grid_width:
			grid_cells.append([])
			
			for row in configuration.grid_height:
				draw_cell(column, row)
				
		grid_cells_flattened.append_array(Match3BoardPluginUtilities.flatten(grid_cells))
		_update_grid_cells_neighbours(grid_cells_flattened)
		
		drawed_cells.emit()
		
	return self


func draw_cell(column: int, row: int) -> void:
	if grid_cells_flattened.any(func(cell: Match3GridCellUI): cell.in_same_grid_position_as(Vector2(column, row))):
		return
		
	var cell: Match3GridCellUI =  configuration.grid_cell_scene.instantiate()
	cell.column = column
	cell.row = row
	cell.position = Vector2(configuration.cell_size.x * cell.column, configuration.cell_size.y * cell.row)
	grid_cells[column].append(cell)
	add_child(cell)


func draw_pieces() -> Match3BoardUI:
	assert(configuration.available_pieces.size() > 0, "Match3BoardUI: No available pieces are set for this board, the pieces cannot be drawed")
	
	for cell: Match3GridCellUI in grid_cells_flattened:
		draw_random_piece_on_cell(cell)
	
	drawed_pieces.emit()
	
	return self


func draw_piece_on_cell(cell: Match3GridCellUI, piece: Match3PieceUI, replace: bool = false) -> void:
	if cell.is_empty() or replace:
		piece.cell = cell
		piece.position = cell.position
		
		if replace and cell.has_piece():
			cell.remove_piece()
			
		cell.piece = piece
		
		if not piece.is_inside_tree():
			add_child(piece)


func draw_random_piece_on_cell(cell: Match3GridCellUI, replace: bool = false) -> Match3PieceUI:
	if cell.is_empty() or replace:
		var piece: Match3PieceUI = Match3PieceUI.from_configuration(piece_generator.roll())
		draw_piece_on_cell(cell, piece, replace)
		
		return piece
		
	return null
	
	
func _update_grid_cells_neighbours(grid_cells: Array[Match3GridCellUI] = grid_cells_flattened) -> void:
	for grid_cell: Match3GridCellUI in grid_cells:
		grid_cell.neighbour_up = finder.get_cell(grid_cell.column, grid_cell.row - 1)
		grid_cell.neighbour_bottom = finder.get_cell(grid_cell.column, grid_cell.row + 1)
		grid_cell.neighbour_right = finder.get_cell(grid_cell.column + 1, grid_cell.row )
		grid_cell.neighbour_left = finder.get_cell(grid_cell.column - 1, grid_cell.row)
		grid_cell.diagonal_neighbour_top_right = finder.get_cell(grid_cell.column + 1, grid_cell.row - 1)
		grid_cell.diagonal_neighbour_top_left = finder.get_cell(grid_cell.column - 1, grid_cell.row - 1)
		grid_cell.diagonal_neighbour_bottom_right = finder.get_cell(grid_cell.column + 1, grid_cell.row + 1)
		grid_cell.diagonal_neighbour_bottom_left = finder.get_cell(grid_cell.column - 1, grid_cell.row + 1)


func add_pieces_to_generator(pieces: Array[Match3PieceConfiguration]) -> Match3BoardUI:
	for piece_configuration: Match3PieceConfiguration in pieces:
		add_piece_to_generator(piece_configuration)
	
	return self


func add_piece_to_generator(piece_configuration: Match3PieceConfiguration) -> Match3BoardUI:
	assert(not piece_configuration.id.is_empty(), "Match3Board->add_piece: The ID of the piece to add is empty, the piece cannot be added")
	
	piece_generator.add_piece(piece_configuration)
	
	return self

#endregion


#region Pieces
func remove_matches_from_board() -> void:
	var sequences: Array[Match3Sequence] = sequence_detector.find_board_sequences()
	
	while sequences.size() > 0:
		for sequence: Match3Sequence in sequences:
			var cells_to_change = sequence.cells.slice(0, (sequence.cells.size() / configuration.min_match) + 1)
			var piece_exceptions: Array[Match3PieceConfiguration] = []
			
			piece_exceptions.assign(Match3BoardPluginUtilities.remove_duplicates(
				cells_to_change.map(
					func(cell: Match3GridCellUI): 
						return configuration.available_pieces.filter(
							func(piece_conf: Match3PieceConfiguration): return cell.piece.id == piece_conf.id).front()
							)
					)
				)
			
			for current_cell: Match3GridCellUI in cells_to_change:
				current_cell.remove_piece()
	
				draw_piece_on_cell(current_cell, Match3PieceUI.from_configuration(piece_generator.roll(piece_exceptions)))
			
		sequences = sequence_detector.find_board_sequences()


func pieces() -> Array[Match3PieceUI]:
	var pieces: Array[Match3PieceUI] = []
	pieces.assign(get_tree().get_nodes_in_group(Match3PieceUI.GroupName))

	return pieces
	

func special_pieces() -> Array[Match3PieceUI]:
	var pieces: Array[Match3PieceUI] = []
	pieces.assign(get_tree().get_nodes_in_group(Match3PieceUI.SpecialGroupName))

	return pieces


func obstacle_pieces() -> Array[Match3PieceUI]:
	var pieces: Array[Match3PieceUI] = []
	pieces.assign(get_tree().get_nodes_in_group(Match3PieceUI.ObstacleGroupName))

	return pieces


func lock_all_pieces() -> void:
	for piece: Match3PieceUI in pieces():
		piece.lock()

	
func unlock_all_pieces() -> void:
	for piece: Match3PieceUI in pieces():
		piece.unlock()


func add_special_pieces_to_queue(pieces: Array[Match3PieceUI]) -> void:
	for piece in pieces:
		add_special_piece_to_queue(piece)


func add_special_piece_to_queue(piece: Match3PieceUI) -> void:
	if not pending_special_pieces.has(piece) \
		and is_instance_valid(piece) \
		and piece.is_special() \
		and not piece.on_queue \
		and not piece.is_queued_for_deletion():
			piece.on_queue = true
			pending_special_pieces.append(piece)
			

func consume_sequence(sequence: Match3Sequence) -> void:
	var pending_special_pieces: Array[Match3PieceUI] = []
	
	if sequence.contains_special_piece():
		for special_piece: Match3PieceUI in sequence.special_pieces():
			add_special_piece_to_queue(special_piece)
		
	if animator:
		await animator.consume_sequence(sequence)
	
	consumed_sequence.emit(sequence)
	sequence.consume()
	await get_tree().process_frame
	
	if pending_special_pieces.is_empty():
		travel_to(BoardState.Fall if (BoardState.Consume or BoardState.SpecialConsume) else BoardState.Consume)
	else:
		travel_to(BoardState.SpecialConsume)
		

func consume_sequences(sequences: Array[Match3Sequence]) -> void:
	var sequences_result: Array[Match3SequenceConsumer.Match3SequenceConsumeResult] = sequence_consumer.sequences_to_combo_rules(sequences)
					
	if animator:
		if configuration.sequence_animation_is_serial():
			for sequence_result in sequences_result:
				for combo: Match3SequenceConsumer.Match3SequenceConsumeCombo in sequence_result.combos:
					await animator.consume_sequence(combo.sequence)
					
		elif configuration.sequence_animation_is_parallel():
			await animator.consume_sequences(sequences_result)
		
	for sequence_result in sequences_result:
		for combo: Match3SequenceConsumer.Match3SequenceConsumeCombo in sequence_result.combos:
			if combo.sequence.contains_special_piece():
				add_special_pieces_to_queue(combo.sequence.special_pieces())
				
			consumed_sequence.emit(combo.sequence)
			combo.sequence.consume_normal_cells()
			await get_tree().process_frame
			
			if combo.special_piece_to_spawn: ## TODO - TEMPORARY DRAW ON THE MIDDLE CELL
				draw_piece_on_cell(combo.sequence.middle_cell(), Match3PieceUI.from_configuration(combo.special_piece_to_spawn))
			
	consumed_sequences.emit(sequences)
	
	await get_tree().process_frame
	
	if pending_special_pieces.is_empty():
		travel_to(BoardState.Fall if (BoardState.Consume or BoardState.SpecialConsume) else BoardState.Consume)
	else:
		travel_to(BoardState.SpecialConsume)


func fall_pieces() -> void:
	var fall_movements: Array[Match3FallMover.FallMovement] = fall_mover.fall_pieces()
	
	for movement in fall_movements:
		movement.to_cell.piece = movement.piece
	
	if animator:
		if configuration.fall_animation_is_serial():
			for movement in fall_movements:
				await animator.fall_piece(movement)
		elif configuration.fall_animation_is_parallel():
			await animator.fall_pieces(fall_movements)
	else:
		for movement in fall_movements:
			movement.to_cell.piece.position = movement.to_cell.position
	
			
func fill_pieces() -> void:
	var filled_cells : Array[Match3GridCellUI] = filler.fill_empty_cells()
		
	if animator:
		if configuration.fill_animation_is_serial():
			for filled_cell in filled_cells:
				await animator.spawn_piece(filled_cell)
		elif configuration.fill_animation_is_parallel():
			await animator.spawn_pieces(filled_cells)
	
#endregion

#region Swap
func swap_pieces(from_piece: Match3PieceUI, to_piece: Match3PieceUI) -> void:
	if configuration.swap_mode_is_connect_line():
		return
		
	var from_cell: Match3GridCellUI = from_piece.cell
	var to_cell: Match3GridCellUI = to_piece.cell
	
	if swap_movement_is_valid(from_cell, to_cell):
		lock_all_pieces()

		if animator:
			await animator.swap_pieces(
				from_piece, 
				to_piece, 
				to_cell.position,
				from_cell.position
				)
		else:
			from_piece.position = to_cell.position
			to_piece.position = from_cell.position
			
		if from_cell.swap_piece_with_cell(to_cell):
			swap_accepted.emit(from_cell, to_cell)
			current_available_moves -= 1
			
			await get_tree().process_frame
			
			var matches: Array[Match3Sequence] = sequence_detector.find_board_sequences()
					
			if matches.size() > 0:
				travel_to(BoardState.Consume)
			else:
				## Do another swap to return the pieces again
				from_cell.swap_piece_with_cell(to_cell)
				
				if animator:
					## The pieces already come up swapped so we can use the updated original cell position to apply the visual change
					await animator.swap_rejected_pieces(
						from_piece, 
						to_piece, 
						from_cell.position,
						to_cell.position
						)
				else:
					from_piece.position = from_cell.position
					to_piece.position = to_cell.position
				
				swap_rejected.emit(from_cell, to_cell)
	else:
		swap_rejected.emit(from_cell, to_cell)
			

func swap_movement_is_valid(from_cell: Match3GridCellUI, to_cell: Match3GridCellUI) -> bool:
	if from_cell.piece.match_with(to_cell.piece):
		return false
		
	match configuration.swap_mode:
		Match3Configuration.BoardMovements.Adjacent:
			return from_cell.is_adjacent_to(to_cell)
			
		Match3Configuration.BoardMovements.AdjacentWithDiagonals:
			return from_cell.is_diagonal_adjacent_to(to_cell)
			
		Match3Configuration.BoardMovements.AdjacentOnlyDiagonals:
			return from_cell.in_diagonal_with(to_cell)
			
		Match3Configuration.BoardMovements.Free:
			return true
			
		Match3Configuration.BoardMovements.Row:
			return from_cell.in_same_row_as(to_cell)
			
		Match3Configuration.BoardMovements.Column:
			return from_cell.in_same_column_as(to_cell)
			
		Match3Configuration.BoardMovements.Cross:
			return finder.cross_cells_from(from_cell).has(to_cell)
			
		Match3Configuration.BoardMovements.CrossDiagonal:
			return finder.cross_diagonal_cells_from(from_cell).has(to_cell)
		_:
			return false
#endregion
#
#
#region Signal callbacks 
func on_child_entered_tree(child: Node) -> void:
	if child is Match3PieceUI:
		if not child.selected.is_connected(on_selected_piece.bind(child)):
			child.selected.connect(on_selected_piece.bind(child))
		
		if not child.drag_started.is_connected(on_piece_drag_started.bind(child)):
			child.drag_started.connect(on_piece_drag_started.bind(child))
			
		if not child.drag_ended.is_connected(on_piece_drag_ended.bind(child)):
			child.drag_ended.connect(on_piece_drag_ended.bind(child))
			

func on_drawed_pieces() -> void:
	if configuration.allow_matches_on_start:
		travel_to(BoardState.Consume)
	else:
		remove_matches_from_board()
		
		
func on_board_locked() -> void:
	if is_inside_tree():
		lock_all_pieces()


func on_board_unlocked() -> void:
	if is_inside_tree():
		unlock_all_pieces()


func on_line_connector_canceled_match(_pieces: Array[Match3PieceUI]) -> void:
	current_selected_piece = null
	unlock()


func on_selected_piece(piece: Match3PieceUI) -> void:
	if piece.is_special() and piece.can_be_triggered:
		add_special_piece_to_queue(piece)
		travel_to(BoardState.SpecialConsume)
		
	elif configuration.swap_mode_is_connect_line():
		current_selected_piece = piece
		
		if configuration.click_mode_is_drag():
			current_selected_piece.drag_started.emit()
			
		lock()
	
	elif configuration.click_mode_is_selection() and not is_locked:
		if current_selected_piece == null:
			current_selected_piece = piece
		
		elif current_selected_piece == piece:
			current_selected_piece = null
			
		elif current_selected_piece and current_selected_piece != piece:
			swap_pieces(current_selected_piece, piece)
			current_selected_piece = null
		

func on_piece_drag_started(piece: Match3PieceUI) -> void:
	if piece.is_special() and piece.can_be_triggered:
		add_special_piece_to_queue(piece)
		travel_to(BoardState.SpecialConsume)
		
	elif configuration.swap_mode_is_connect_line():
		current_selected_piece = piece
		
		if configuration.click_mode_is_drag():
			piece_drag_started.emit(current_selected_piece)
			
		lock()
		
	elif configuration.click_mode_is_drag() and not is_locked:
		current_selected_piece = piece
		current_selected_piece.enable_drag()
			
		piece_drag_started.emit(current_selected_piece)


func on_piece_drag_ended(piece: Match3PieceUI) -> void:
	if configuration.swap_mode_is_connect_line():
		if configuration.click_mode_is_drag():
			piece_drag_ended.emit(current_selected_piece)
			current_selected_piece = null

	elif configuration.click_mode_is_drag() and current_selected_piece == piece:
		var other_piece = current_selected_piece.detect_near_piece()
		
		if other_piece:
			swap_pieces(current_selected_piece, other_piece)
		
		current_selected_piece.disable_drag()
		piece_drag_ended.emit(current_selected_piece)
		current_selected_piece = null
		

func on_swap_accepted(_from: Match3GridCellUI, _to: Match3GridCellUI) -> void:
	lock()


func on_swap_rejected(_from: Match3GridCellUI, _to: Match3GridCellUI) -> void:
	unlock()
	

func on_board_state_changed(_from: BoardState, to: BoardState) -> void:
	match to:
		BoardState.WaitForInput:
			unlock()
			
		BoardState.Consume:
			lock()
			await consume_sequences(sequence_detector.find_board_sequences())
		BoardState.SpecialConsume:
			lock()
			if pending_special_pieces.is_empty():
				travel_to(BoardState.Fall)
			else:
				if animator:
					var special_animation_callback = func(anim_name: StringName, piece: Match3PieceUI):
						if anim_name == Match3Animator.TriggerSpecialPieceAnimation:
							pending_special_pieces.erase(piece)
							consume_sequences(piece.trigger(self))
							piece.cell.remove_piece(true)
					
					for piece in pending_special_pieces:
						animator.animation_finished.connect(special_animation_callback.bind(piece), CONNECT_ONE_SHOT)
						animator.trigger_special_piece(piece)
				else:
					for piece in pending_special_pieces:
						pending_special_pieces.erase(piece)
						consume_sequences(piece.trigger(self))
						piece.cell.remove_piece(true)
			
		BoardState.Fall:
			lock()
			await fall_pieces()
			await get_tree().process_frame
			
			travel_to(BoardState.Fill)
			
		BoardState.Fill:
			lock()
			await fill_pieces()
			await get_tree().process_frame
			
			if sequence_detector.find_board_sequences().is_empty():
				travel_to(BoardState.WaitForInput)
			else:
				travel_to(BoardState.Consume)
		
					
func on_animator_animation_started(_animation_name: StringName) -> void:
	lock()

#endregion
