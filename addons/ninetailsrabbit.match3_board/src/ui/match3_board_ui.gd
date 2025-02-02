class_name Match3BoardUI extends Node2D

signal state_changed(from: BoardState, to: BoardState)

@export var configuration: Match3BoardConfiguration


enum BoardState {
	WaitForInput,
	Fill,
	Consume
}

var board: Board
var grid_cells: Array = [] # Multidimensional to access cells by column & row
var grid_cells_flattened: Array[Match3GridCellUI] = []

var current_state: BoardState = BoardState.WaitForInput:
	set(new_state):
		if new_state != current_state:
			var previous_state: BoardState = current_state
			current_state = new_state
			state_changed.emit(previous_state, current_state)


func _ready() -> void:
	prepare_board()
	
	if configuration.auto_start:
		draw_cells().draw_pieces()
		
#region Preparation
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
		
	board.prepare_grid_cells()
	
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
	
	for cell: Match3GridCell in board.grid_cells_flattened:
		if cell.has_piece():
			var piece: Match3PieceUI = _core_piece_to_ui_piece(cell.piece)
			add_child(piece)
	
	return self

#endregion

func _core_piece_to_ui_piece(piece: Match3Piece) -> Match3PieceUI:
	var pieces = configuration.available_pieces.filter(
		func(configuration: Match3PieceConfiguration): return configuration.id == piece.id)
	
	if pieces.is_empty():
		return null
		
	var piece_ui: Match3PieceUI = pieces.front().scene.instantiate()
	piece_ui.piece = piece
	
	return piece_ui


func _core_cell_to_ui_cell(cell: Match3GridCell) -> Match3GridCellUI:
	var cells = grid_cells_flattened.filter(func(cell_ui: Match3GridCellUI): return cell_ui.cell == cell)
	
	if cell.is_empty():
		return null
		
	return cells.front()
