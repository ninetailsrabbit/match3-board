### THIS CLASS MAPS THE CORE ELEMENTS TO UI ELEMENTS ###
class_name Match3Mapper extends RefCounted

var match3_board_ui: Match3BoardUI


func _init(board: Match3BoardUI) -> void:
	match3_board_ui = board


func create_ui_piece_from_core_piece(piece: Match3Piece) -> Match3PieceUI:
	var pieces = match3_board_ui.configuration.available_pieces.filter(
		func(configuration: Match3PieceConfiguration): return configuration.id == piece.id)
	
	if pieces.is_empty():
		return null
		
	var piece_ui: Match3PieceUI = pieces.front().scene.instantiate()
	piece_ui.piece = piece
	
	return piece_ui


func create_ui_pieces_from_core_pieces(pieces: Array[Match3Piece]) -> Array[Match3PieceUI]:
	var pieces_ui: Array[Match3PieceUI] = []
	pieces_ui.assign(pieces.map(create_ui_piece_from_core_piece))
	pieces_ui.assign(Match3BoardPluginUtilities.remove_falsy_values(pieces_ui))
	
	return pieces_ui


func ui_pieces_from_core_pieces(pieces: Array[Match3Piece]) -> Array[Match3PieceUI]:
	var pieces_ui: Array[Match3PieceUI] = []
	pieces_ui.assign(pieces.map(func(piece: Match3Piece): return ui_piece_from_core_piece(piece)))
	pieces_ui.assign(Match3BoardPluginUtilities.remove_falsy_values(pieces_ui))
	
	return pieces_ui


func ui_piece_from_core_piece(piece: Match3Piece) -> Match3PieceUI:
	var cell_ui: Match3GridCellUI = core_cell_to_ui_cell(match3_board_ui.board.cell_finder.grid_cell_from_piece(piece))
	
	return cell_ui.piece_ui
	

func ui_pieces_from_sequence(sequence: Match3Sequence) -> Array[Match3PieceUI]:
	var cells: Array[Match3GridCellUI] = core_cells_to_ui_cells(sequence.cells)
	var pieces: Array[Match3PieceUI] = []
	pieces.assign(cells.map(func(cell: Match3GridCellUI): return cell.piece_ui))

	return pieces


func core_cell_to_ui_cell(cell: Match3GridCell) -> Match3GridCellUI:
	var cells: Array[Match3GridCellUI] = match3_board_ui.grid_cells_flattened.filter(
		func(cell_ui: Match3GridCellUI): return cell_ui.cell == cell
		)
	
	if cells.is_empty():
		return null
		
	return cells.front()


func core_cells_to_ui_cells(cells: Array[Match3GridCell]) -> Array[Match3GridCellUI]:
	var cells_ui: Array[Match3GridCellUI] = []
	cells_ui.assign(cells.map(core_cell_to_ui_cell))
	cells_ui.assign(Match3BoardPluginUtilities.remove_falsy_values(cells_ui))
	
	return cells_ui


func grid_cell_ui_from_piece_ui(piece_ui: Match3PieceUI) -> Match3GridCellUI:
	var cells: Array[Match3GridCellUI] = match3_board_ui.grid_cells_flattened.filter(func(cell: Match3GridCellUI): return cell.piece_ui == piece_ui)
	
	if cells.is_empty():
		return null
		
	return cells.front()
	
	
func sequence_rules_to_core_sequence_rules() -> Array[Match3SequenceConsumeRule]:
	var rules: Array[Match3SequenceConsumeRule] = []

	for sequence_rule: SequenceConsumeRule in match3_board_ui.configuration.sequence_rules:
		var pieces: Array[Match3Piece] = []
		pieces.assign(
			sequence_rule.target_pieces.map(
				func(piece: Match3PieceConfiguration): return match3_board_ui.board.available_pieces[piece.id].piece)
			)
	
		rules.append(
				Match3SequenceConsumeRule.new(
				sequence_rule.id, 
				sequence_rule.shapes,
				pieces,
				match3_board_ui.board.available_special_pieces[sequence_rule.piece_to_spawn.id].piece
				)
			)
	
	return rules
