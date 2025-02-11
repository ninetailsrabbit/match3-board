class_name Match3Highlighter extends Node

## TODO - LEAVE THIS CLASS TO OVERRIDE THE METHODS
const highlight_texture = preload("res://addons/ninetailsrabbit.match3_board/src/debug_ui/preview_cells/highlighted.png")

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
	current_highlighted_cells = cells
	
	for cell in current_highlighted_cells:
		highlight_cell(cell)
		
		
	return self


func highlight_cell(cell: Match3GridCellUI) -> Match3Highlighter:
	cell.sprite_2d.texture = highlight_texture
	
	return self


func remove_highlight() -> void:
	for cell in current_highlighted_cells:
		cell.sprite_2d.texture = cell.original_texture
		
	current_highlighted_cells.clear()

	for piece in current_highlighted_pieces:
		pass
		
	current_highlighted_pieces.clear()


func on_selected_piece(piece: Match3PieceUI) -> void:
	var cell: Match3GridCellUI = piece.cell
	var neighbours: Dictionary = cell.usable_neighbours()
	var target_cells: Array[Match3GridCellUI] = []
	
	match board.configuration.swap_mode:
		Match3Configuration.BoardMovements.Adjacent:
			target_cells.assign(Match3BoardPluginUtilities.remove_falsy_values([neighbours.up, neighbours.bottom, neighbours.left, neighbours.right]))
			
		Match3Configuration.BoardMovements.AdjacentWithDiagonals:
			target_cells.assign(Match3BoardPluginUtilities.remove_falsy_values([
				neighbours.up, neighbours.bottom, neighbours.left, neighbours.right,
				neighbours.diagonal_bottom_right, neighbours.diagonal_bottom_left, neighbours.diagonal_top_left, neighbours.diagonal_top_right
				]))
			
		Match3Configuration.BoardMovements.AdjacentOnlyDiagonals:
			target_cells.assign(Match3BoardPluginUtilities.remove_falsy_values([
				neighbours.diagonal_bottom_right, neighbours.diagonal_bottom_left, neighbours.diagonal_top_left, neighbours.diagonal_top_right
			]))
			
		Match3Configuration.BoardMovements.Free:
			target_cells.append(cell)
			
		Match3Configuration.BoardMovements.Row:
			target_cells.append_array(board.finder.grid_cells_from_row(cell.row, true))
			
		Match3Configuration.BoardMovements.Column:
			target_cells.append_array(board.finder.grid_cells_from_column(cell.column, true))
			
		Match3Configuration.BoardMovements.Cross:
			target_cells.append_array(board.finder.cross_cells_from(cell, true))
			
		Match3Configuration.BoardMovements.CrossDiagonal:
			target_cells.append_array(board.finder.cross_diagonal_cells_from(cell, true))
			
	highlight_cells(target_cells)
	

func on_unselected_piece(_piece: Match3PieceUI) -> void:
	remove_highlight()
