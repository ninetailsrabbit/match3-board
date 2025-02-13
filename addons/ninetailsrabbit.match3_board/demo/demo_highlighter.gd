class_name Match3DemoHighlighter extends Match3Highlighter

const highlight_texture = preload("res://addons/ninetailsrabbit.match3_board/src/debug_ui/preview_cells/highlighted.png")


func highlight_cells(cells: Array[Match3GridCellUI]) -> Match3Highlighter:
	current_highlighted_cells = cells
	
	for cell in current_highlighted_cells:
		highlight_cell(cell)
		
	return self


func highlight_cell(cell: Match3GridCellUI) -> Match3Highlighter:
	cell.sprite_2d.texture = highlight_texture
	
	return self


func remove_highlight() -> Match3Highlighter:
	for cell in current_highlighted_cells:
		if cell.sprite_2d and cell.sprite_2d is Sprite2D:
			cell.sprite_2d.texture = cell.original_texture
		
	current_highlighted_cells.clear()

	for piece in current_highlighted_pieces:
		pass
		
	current_highlighted_pieces.clear()
	
	return self


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
			
		Match3Configuration.BoardMovements.ConnectLine:
			pass ## This swap mode is handled on the on_connected_piece signal callback
			
	highlight_cells(target_cells)


func on_connected_piece(piece: Match3PieceUI) -> void:
	if board.configuration.swap_mode_is_connect_line():
		remove_highlight()
		
		if board.line_connector.can_connect_more_pieces():
			var valid_cells: Array[Match3GridCellUI] = board.line_connector.matches_from_piece(piece)
			highlight_cells(valid_cells)
			current_highlighted_cells.append_array(valid_cells)
