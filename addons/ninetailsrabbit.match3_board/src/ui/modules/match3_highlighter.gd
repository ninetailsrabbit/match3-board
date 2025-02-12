class_name Match3Highlighter extends Node

@export var board: Match3BoardUI

var current_highlighted_cells: Array[Match3GridCellUI] = []
var current_highlighted_pieces: Array[Match3PieceUI] = []


func _ready() -> void:
	if board == null:
		board = get_tree().get_first_node_in_group(Match3BoardUI.GroupName)
	
	board.selected_piece.connect(on_selected_piece)
	board.unselected_piece.connect(on_unselected_piece)
	board.piece_drag_started.connect(on_selected_piece)
	board.piece_drag_ended.connect(on_unselected_piece)


func highlight_cells(cells: Array[Match3GridCellUI]) -> Match3Highlighter:
	return self


func highlight_cell(cell: Match3GridCellUI) -> Match3Highlighter:
	return self


func remove_highlight() -> Match3Highlighter:
	return self


func on_selected_piece(piece: Match3PieceUI) -> void:
	pass
	

func on_unselected_piece(_piece: Match3PieceUI) -> void:
	remove_highlight()
