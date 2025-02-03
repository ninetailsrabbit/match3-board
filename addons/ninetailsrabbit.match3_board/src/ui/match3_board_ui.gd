class_name Match3BoardUI extends Node2D

signal state_changed(from: BoardState, to: BoardState)
signal swap_accepted(from: Match3GridCellUI, to: Match3GridCellUI)
signal swap_rejected(from: Match3GridCellUI, to: Match3GridCellUI)
signal locked
signal unlocked

@export var configuration: Match3BoardConfiguration


enum BoardState {
	WaitForInput,
	Fill,
	Consume
}

var board: Board
var grid_cells: Array = [] # Multidimensional to access cells by column & row
var grid_cells_flattened: Array[Match3GridCellUI] = []

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
	child_entered_tree.connect(on_child_entered_tree)


func _ready() -> void:
	prepare_board()
	
	if configuration.auto_start:
		draw_cells().draw_pieces()
		
	locked.connect(on_board_locked)
	unlocked.connect(on_board_unlocked)

		
#region Draw
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
	
	board.prepare_pieces()
	
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
	if cell_ui.cell.has_piece() and cell_ui.piece_ui == null:
			var piece_ui: Match3PieceUI = _core_piece_to_ui_piece(cell_ui.cell.piece)
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
			

func swap_pieces(from_piece: Match3PieceUI, to_piece: Match3PieceUI) -> void:
	var from_grid_cell: Match3GridCellUI = _grid_cell_ui_from_piece_ui(from_piece)
	var to_grid_cell: Match3GridCellUI = _grid_cell_ui_from_piece_ui(to_piece)
			
	if from_grid_cell.swap_piece_with(to_grid_cell):
		## TODO - THIS SHOULD BE DOING WITH THE ANIMATOR AND WAIT THE ANIMATION FINISHED SIGNAL
		
		## The swap updates the original cell position so we can use them to do the change visually
		from_grid_cell.piece_ui.position = from_grid_cell.piece_ui.original_cell_position
		to_grid_cell.piece_ui.position = to_grid_cell.piece_ui.original_cell_position
	
		swap_accepted.emit(from_grid_cell, to_grid_cell)
	else:
		swap_rejected.emit(from_grid_cell, to_grid_cell)
			

func on_piece_drag_started(piece_ui: Match3PieceUI) -> void:
	if configuration.click_mode_is_drag():
		current_selected_piece = piece_ui
		current_selected_piece.enable_drag()


func on_piece_drag_ended(piece_ui: Match3PieceUI) -> void:
	if configuration.click_mode_is_drag() and current_selected_piece:
		current_selected_piece.disable_drag()

#endregion


#region Private functions
func _core_piece_to_ui_piece(piece: Match3Piece) -> Match3PieceUI:
	var pieces = configuration.available_pieces.filter(
		func(configuration: Match3PieceConfiguration): return configuration.id == piece.id)
	
	if pieces.is_empty():
		return null
		
	var piece_ui: Match3PieceUI = pieces.front().scene.instantiate()
	piece_ui.piece = piece
	
	return piece_ui


func _core_cell_to_ui_cell(cell: Match3GridCell) -> Match3GridCellUI:
	var cells = grid_cells_flattened.filter(
		func(cell_ui: Match3GridCellUI): return cell_ui.cell == cell)
	
	if cell.is_empty():
		return null
		
	return cells.front()


func _grid_cell_ui_from_piece_ui(piece_ui: Match3PieceUI) -> Match3GridCellUI:
	var cells: Array[Match3GridCellUI] = grid_cells_flattened.filter(func(cell: Match3GridCellUI): return cell.piece_ui == piece_ui)
	
	if cells.is_empty():
		return null
		
	return cells.front()
	
#endregion
