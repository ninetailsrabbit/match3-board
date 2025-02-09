class_name Match3BoardUI extends Node2D

const GroupName: StringName = &"match3-board"

signal state_changed(from: BoardState, to: BoardState)
signal swap_accepted(from: Match3GridCellUI, to: Match3GridCellUI)
signal swap_rejected(from: Match3GridCellUI, to: Match3GridCellUI)
signal locked
signal unlocked

@export var configuration: Match3BoardConfiguration
@export var animator: Match3Animator

enum BoardState {
	WaitForInput,
	Fill,
	Consume
}

var board: Board
var grid_cells: Array = [] # Multidimensional to access cells by column & row
var grid_cells_flattened: Array[Match3GridCellUI] = []
var match3_mapper: Match3Mapper = Match3Mapper.new(self)

var current_selected_piece: Match3PieceUI
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
	prepare_animator()\
		.prepare_board()
	
	if configuration.auto_start:
		draw_cells().draw_pieces()
			
	swap_accepted.connect(on_swap_accepted)
	swap_rejected.connect(on_swap_rejected)
	locked.connect(on_board_locked)
	unlocked.connect(on_board_unlocked)
	state_changed.connect(on_board_state_changed)


func lock() -> void:
	is_locked = true


func unlock() -> void:
	is_locked = false


#region Modules
func change_animator(new_animator: Match3Animator) -> Match3BoardUI:
	if animator:
		animator.queue_free()
		animator = null
		
	animator = new_animator
	animator.board = self
	
	if not animator.is_inside_tree():
		add_child(animator)
	
	if not animator.animation_started.is_connected(on_animator_animation_started):
		animator.animation_started.connect(on_animator_animation_started)
		
		
	return self

#endregion

#region Draw
func prepare_animator() -> Match3BoardUI:
	if animator == null:
		animator = Match3BoardPluginUtilities.first_node_of_custom_class(self, Match3Animator)
		
		if animator:
			change_animator(animator)
	else:
		if not animator.is_inside_tree():
			animator.board = self
			add_child(animator)
	
	if not animator.animation_started.is_connected(on_animator_animation_started):
		animator.animation_started.connect(on_animator_animation_started)
	
	return self
	

func prepare_board() -> Match3BoardUI:
	assert(configuration != null, "Match3BoardUI: No configuration found, the board cannot be prepared")
	assert(configuration.available_pieces.size() > 2, "Match3BoardUI: There is less than 3 pieces in the configuration, the board cannot be prepared")
	
	if board == null:
		board = Board.new(
					configuration.min_match,
					configuration.max_match,
					configuration.grid_width,
					configuration.grid_height,
					configuration.available_moves_on_start,
					configuration.allow_matches_on_start
					)
		
	board.change_fill_mode(configuration.fill_mode)\
		.prepare_grid_cells()
	
	## We instantiate the piece scenes to create the core board piece with the information
	for piece_configuration: Match3PieceConfiguration in configuration.available_pieces:
		var board_piece: Match3Piece = Match3Piece.new(
				piece_configuration.id, 
				piece_configuration.shape, 
				piece_configuration.color, 
				piece_configuration.type)
				
		board.add_piece(board_piece, piece_configuration.weight)
		
	for piece_configuration: Match3PieceConfiguration in configuration.available_special_pieces:
		var board_piece: Match3Piece = Match3Piece.new(
				piece_configuration.id, 
				piece_configuration.shape, 
				piece_configuration.color, 
				piece_configuration.type)
				
		board.add_special_piece(board_piece)
	
	board.prepare_pieces()\
		.prepare_sequence_consumer(match3_mapper.sequence_rules_to_core_sequence_rules())
		
	if board.allow_matches_on_start:
		current_state = BoardState.Consume
	
	
	return self
	
	
func draw_cells() -> Match3BoardUI:
	if grid_cells.is_empty():
		
		for column in configuration.grid_width:
			grid_cells.append([])
			
			for row in configuration.grid_height:
				grid_cells[column].append(draw_cell(board.grid_cells[column][row]))
			
	return self


func draw_cell(cell: Match3GridCell) -> Match3GridCellUI:
	var cell_ui: Match3GridCellUI = configuration.grid_cell_scene.instantiate()
	cell_ui.size = configuration.cell_size
	cell_ui.cell = cell
	cell_ui.position = Vector2(configuration.cell_size.x * cell.column, configuration.cell_size.y * cell.row)
	
	add_child(cell_ui)
	
	grid_cells_flattened.append(cell_ui)

	return cell_ui


func draw_pieces() -> Match3BoardUI:
	assert(configuration.available_pieces.size() > 0, "Match3BoardUI: No available pieces are set for this board, the pieces cannot be drawed")
	
	for cell: Match3GridCellUI in grid_cells_flattened:
		draw_piece(cell)
	
	return self


func draw_piece(cell_ui: Match3GridCellUI) -> Match3PieceUI:
	if cell_ui.cell.has_piece() and cell_ui.is_empty():
		var piece_ui: Match3PieceUI = match3_mapper.create_ui_piece_from_core_piece(cell_ui.cell.piece)
		piece_ui.position = cell_ui.position
		cell_ui.piece_ui = piece_ui
		add_child(piece_ui)
		
		return piece_ui
		
	return null

#endregion


#region Pieces
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
	
#endregion

#region Swap
func swap_pieces(from_piece: Match3PieceUI, to_piece: Match3PieceUI) -> void:
	var from_grid_cell: Match3GridCellUI = match3_mapper.grid_cell_ui_from_piece_ui(from_piece)
	var to_grid_cell: Match3GridCellUI = match3_mapper.grid_cell_ui_from_piece_ui(to_piece)
	
	if swap_movement_is_valid(from_grid_cell, to_grid_cell):
		if animator:
			await animator.swap_pieces(
				from_piece, 
				to_piece, 
				to_piece.position,
				from_piece.position
				)
		else:
			from_piece.position = to_piece.position
			to_piece.position = from_piece.position
			
		if from_grid_cell.swap_piece_with(to_grid_cell):
			swap_accepted.emit(from_grid_cell, to_grid_cell)
			
			await get_tree().process_frame
			
			var matches: Array[Match3Sequence] = board.sequence_finder.find_board_sequences()
					
			if matches.size() > 0:
				current_state = BoardState.Consume
			else:
				## Do another swap to return the pieces again
				from_grid_cell.swap_piece_with(to_grid_cell)
				
				if animator:
					## The pieces already come up swapped so we can use the updated original cell position to apply the visual change
					await animator.swap_rejected_pieces(
						from_piece, 
						to_piece, 
						from_piece.original_cell_position,
						to_piece.original_cell_position
						)
				else:
					from_piece.position = from_piece.original_cell_position
					to_piece.position = to_piece.original_cell_position
				
				swap_rejected.emit(from_grid_cell, to_grid_cell)
	else:
		swap_rejected.emit(from_grid_cell, to_grid_cell)
			

func swap_movement_is_valid(from_grid_cell: Match3GridCellUI, to_grid_cell: Match3GridCellUI) -> bool:
	if from_grid_cell.piece_ui.match_with(to_grid_cell.piece_ui):
		return false
		
	match configuration.swap_mode:
		Match3Configuration.BoardMovements.Adjacent:
			return from_grid_cell.cell.is_adjacent_to(to_grid_cell.cell)
			
		Match3Configuration.BoardMovements.AdjacentWithDiagonals:
			return from_grid_cell.cell.is_diagonal_adjacent_to(to_grid_cell.cell)
			
		Match3Configuration.BoardMovements.AdjacentOnlyDiagonals:
			return from_grid_cell.cell.in_diagonal_with(to_grid_cell.cell)
			
		Match3Configuration.BoardMovements.Free:
			return true
			
		Match3Configuration.BoardMovements.Row:
			return from_grid_cell.cell.in_same_row_as(to_grid_cell.cell)
			
		Match3Configuration.BoardMovements.Column:
			return from_grid_cell.cell.in_same_column_as(to_grid_cell.cell)
			
		Match3Configuration.BoardMovements.Cross:
			return board.cell_finder.cross_cells_from(from_grid_cell.cell).has(to_grid_cell.cell)
			
		Match3Configuration.BoardMovements.CrossDiagonal:
			return board.cell_finder.cross_diagonal_cells_from(from_grid_cell.cell).has(to_grid_cell.cell)
		_:
			return false
#endregion


#region Signal callbacks 
func on_board_locked() -> void:
	if is_inside_tree():
		lock_all_pieces()


func on_board_unlocked() -> void:
	if is_inside_tree():
		unlock_all_pieces()


func on_child_entered_tree(child: Node) -> void:
	if child is Match3PieceUI:
		if not child.selected.is_connected(on_selected_piece.bind(child)):
			child.selected.connect(on_selected_piece.bind(child))
		
		if not child.drag_started.is_connected(on_piece_drag_started.bind(child)):
			child.drag_started.connect(on_piece_drag_started.bind(child))
			
		if not child.drag_ended.is_connected(on_piece_drag_ended.bind(child)):
			child.drag_ended.connect(on_piece_drag_ended.bind(child))


func on_selected_piece(piece_ui: Match3PieceUI) -> void:
	if configuration.click_mode_is_selection():
		
		if current_selected_piece == null:
			current_selected_piece = piece_ui
		
		elif current_selected_piece == piece_ui:
			current_selected_piece = null
			
		elif current_selected_piece != piece_ui:
			swap_pieces(current_selected_piece, piece_ui)
			current_selected_piece = null
		

func on_piece_drag_started(piece_ui: Match3PieceUI) -> void:
	if configuration.click_mode_is_drag():
		current_selected_piece = piece_ui
		current_selected_piece.enable_drag()


func on_piece_drag_ended(piece_ui: Match3PieceUI) -> void:
	if configuration.click_mode_is_drag() and current_selected_piece:
		current_selected_piece.disable_drag()


func on_swap_accepted(_from: Match3GridCellUI, _to: Match3GridCellUI) -> void:
	lock()


func on_swap_rejected(_from: Match3GridCellUI, _to: Match3GridCellUI) -> void:
	unlock()
	

	
func consume_sequences() -> void:
	## TODO - IT MISS THE LOGIC TO SPAWN AND TRIGGER SPECIAL PIECES
	var sequences_result: Array[Match3SequenceConsumer.Match3SequenceConsumeResult] = board.sequences_to_combo_rules()
	
	if animator:
		var animations_finished: Array[bool] = []
		
		for sequence_result in sequences_result:
			for combo: Match3SequenceConsumer.Match3SequenceConsumeCombo in sequence_result.combos:
				
				animator.animation_finished.connect(func(anim_name: StringName):
					if anim_name == animator.ConsumeSequenceAnimation:
						animations_finished.append(true)
						combo.sequence.consume()
						
						if animations_finished.size() == sequences_result.size():
							current_state = BoardState.Fill
					, CONNECT_ONE_SHOT)
						
				animator.consume_sequence(combo.sequence)
	else:
		for sequence_result in sequences_result:
			for combo: Match3SequenceConsumer.Match3SequenceConsumeCombo in sequence_result.combos:
				combo.sequence.consume()
			
		current_state = BoardState.Fill
			
			
func fall_pieces() -> void:
	while board.grid_cells_flattened.any(func(cell: Match3GridCell):
		return cell.has_piece() \
			and cell.piece.can_be_moved \
			and (cell.neighbour_bottom and cell.neighbour_bottom.can_contain_piece and cell.neighbour_bottom.is_empty())
		):
			
		var fall_movements: Array[Match3FallMover.FallMovement] = board.fall_mover.fall_pieces()
			
		for movement in fall_movements:
			var cell_ui = match3_mapper.core_cell_to_ui_cell(movement.to_cell)
			cell_ui.piece_ui = match3_mapper.ui_piece_from_core_piece(movement.piece)
		
		if animator:
			#animator.animation_finished.connect(func(anim_name: StringName): 
				#if anim_name == Match3Animator.FallPiecesAnimation:
					#if board.sequence_finder.find_board_sequences().is_empty():
						#current_state = BoardState.WaitForInput
					#else:
						#current_state = BoardState.Consume
					#, CONNECT_ONE_SHOT)
			#
			animator.fall_pieces(fall_movements)
			
			#var filled_cells : Array[Match3GridCell] = board.fill_empty_cells()
			#var filled_cells_ui: Array[Match3GridCellUI] = match3_mapper.core_cells_to_ui_cells(filled_cells)
			#
			## TODO - FILL ANIMATIONS
			
		else:
			for movement in fall_movements:
				var piece_ui: Match3PieceUI = match3_mapper.ui_piece_from_core_piece(movement.piece)
				piece_ui.position = piece_ui.original_cell_position
				
			var filled_cells : Array[Match3GridCell] = board.fill_empty_cells()
			var filled_cells_ui: Array[Match3GridCellUI] = match3_mapper.core_cells_to_ui_cells(filled_cells)

			for cell_ui: Match3GridCellUI in filled_cells_ui:
				draw_piece(cell_ui)
		
		if board.sequence_finder.find_board_sequences().is_empty():
			current_state = BoardState.WaitForInput
		else:
			current_state = BoardState.Consume


func on_board_state_changed(_from: BoardState, to: BoardState) -> void:
	match to:
		BoardState.WaitForInput:
			await get_tree().process_frame
			unlock()
		BoardState.Consume:
			lock()
			await get_tree().process_frame
			consume_sequences()
			
		BoardState.Fill:
			lock()
			await get_tree().process_frame
			fall_pieces()
			
					
func on_animator_animation_started(_animation_name: StringName) -> void:
	lock()
	
#endregion
