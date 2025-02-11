class_name Match3BoardFinder extends RefCounted


var board: Match3BoardUI


func _init(_board: Match3BoardUI) -> void:
	board = _board


#region Cells
func get_cell(column: int, row: int) -> Match3GridCellUI:
	if not board.grid_cells.is_empty() and column >= 0 and row >= 0:
		if column <= board.grid_cells.size() - 1 and row <= board.grid_cells[0].size() - 1:
			return board.grid_cells[column][row]
			
	return null
	

func grid_cell_from_piece(piece: Match3PieceUI) -> Match3GridCellUI:
	var found_pieces = board.grid_cells_flattened.filter(
		func(cell: Match3GridCellUI): return cell.has_piece() and cell.piece == piece
	)
	
	if found_pieces.size() == 1:
		return found_pieces.front()
	
	return null
	
	
func grid_cells_from_row(row: int, only_usables: bool = false) -> Array[Match3GridCellUI]:
	var cells: Array[Match3GridCellUI] = []
	
	if board.grid_cells.size() > 0 and Match3BoardPluginUtilities.value_is_between(row, 0, board.configuration.grid_height - 1):
		for column: int in board.configuration.grid_width:
			cells.append(board.grid_cells[column][row])
			
	
	return cells.filter(_is_usable_cell) if only_usables else cells
	

func grid_cells_from_column(column: int, only_usables: bool = false) -> Array[Match3GridCellUI]:
	var cells: Array[Match3GridCellUI] = []
		
	if board.grid_cells.size() > 0 and Match3BoardPluginUtilities.value_is_between(column, 0, board.configuration.grid_width - 1):
		for row: int in board.configuration.grid_height:
			cells.append(board.grid_cells[column][row])
	
	return cells.filter(_is_usable_cell) if only_usables else cells

	

func top_cells_from(origin_cell: Match3GridCellUI, only_usables: bool = false) -> Array[Match3GridCellUI]:
	var cells: Array[Match3GridCellUI] = []
	var current_cell: Match3GridCellUI = origin_cell
	
	if current_cell.is_top_border():
		return []
	
	while current_cell.neighbours()["top"] != null:
		current_cell = current_cell.neighbours()["top"]
		cells.append(current_cell)
	
	return cells.filter(_is_usable_cell) if only_usables else cells

	

func bottom_cells_from(origin_cell: Match3GridCellUI, only_usables: bool = false) -> Array[Match3GridCellUI]:
	var cells: Array[Match3GridCellUI] = []
	var current_cell: Match3GridCellUI = origin_cell
	
	if current_cell.is_bottom_border():
		return []
	
	while current_cell.neighbours()["bottom"] != null:
		current_cell = current_cell.neighbours()["bottom"]
		cells.append(current_cell)
	
	return cells.filter(_is_usable_cell) if only_usables else cells

	

func right_cells_from(origin_cell: Match3GridCellUI, only_usables: bool = false) -> Array[Match3GridCellUI]:
	var cells: Array[Match3GridCellUI] = []
	var current_cell: Match3GridCellUI = origin_cell
	
	if current_cell.is_right_border():
		return []
	
	while current_cell.neighbours()["right"] != null:
		current_cell = current_cell.neighbours()["right"]
		cells.append(current_cell)
	
	return cells.filter(_is_usable_cell) if only_usables else cells


func left_cells_from(origin_cell: Match3GridCellUI, only_usables: bool = false) -> Array[Match3GridCellUI]:
	var cells: Array[Match3GridCellUI] = []
	var current_cell: Match3GridCellUI = origin_cell
	
	if current_cell.is_left_border():
		return []
	
	while current_cell.neighbours()["left"] != null:
		current_cell = current_cell.neighbours()["left"]
		cells.append(current_cell)
	
	return cells.filter(_is_usable_cell) if only_usables else cells

	
func diagonal_top_right_cells_from(cell: Match3GridCellUI, distance: int, only_usables: bool = false) -> Array[Match3GridCellUI]:
	var diagonal_cells: Array[Match3GridCellUI] = []
	
	distance = clamp(distance, 0, board.configuration.grid_width)
	var current_cell = cell.diagonal_neighbour_top_right
	
	if distance > 0 and current_cell is Match3GridCellUI:
		diagonal_cells.append_array(([current_cell] as Array[Match3GridCellUI]) + diagonal_top_right_cells_from(current_cell, distance - 1, only_usables))
	
	return diagonal_cells.filter(_is_usable_cell) if only_usables else diagonal_cells


func diagonal_top_left_cells_from(cell: Match3GridCellUI, distance: int, only_usables: bool = false) -> Array[Match3GridCellUI]:
	var diagonal_cells: Array[Match3GridCellUI] = []
	
	distance = clamp(distance, 0, board.configuration.grid_width)
	var current_cell = cell.diagonal_neighbour_top_left
	
	if distance > 0 and current_cell is Match3GridCellUI:
		diagonal_cells.append_array(([current_cell] as Array[Match3GridCellUI]) + diagonal_top_left_cells_from(current_cell, distance - 1, only_usables))
	
	return diagonal_cells.filter(_is_usable_cell) if only_usables else diagonal_cells



func diagonal_bottom_left_cells_from(cell: Match3GridCellUI, distance: int, only_usables: bool = false) -> Array[Match3GridCellUI]:
	var diagonal_cells: Array[Match3GridCellUI] = []
	
	distance = clamp(distance, 0, board.configuration.grid_width)
	var current_cell = cell.diagonal_neighbour_bottom_left
	
	if distance > 0 and current_cell is Match3GridCellUI:
		diagonal_cells.append_array(([current_cell] as Array[Match3GridCellUI]) + diagonal_bottom_left_cells_from(current_cell, distance - 1, only_usables))
	
	return diagonal_cells.filter(_is_usable_cell) if only_usables else diagonal_cells


func diagonal_bottom_right_cells_from(cell: Match3GridCellUI, distance: int, only_usables: bool = false) -> Array[Match3GridCellUI]:
	var diagonal_cells: Array[Match3GridCellUI] = []
	
	distance = clamp(distance, 0, board.configuration.grid_width)
	var current_cell = cell.diagonal_neighbour_bottom_right
	
	if distance > 0 and current_cell is Match3GridCellUI:
		diagonal_cells.append_array(([current_cell] as Array[Match3GridCellUI]) + diagonal_bottom_right_cells_from(current_cell, distance - 1, only_usables))
	
	return diagonal_cells.filter(_is_usable_cell) if only_usables else diagonal_cells


func adjacent_cells_from(origin_cell: Match3GridCellUI, only_usables: bool = false) -> Dictionary:
	return origin_cell.usable_neighbours() if only_usables else origin_cell.neighbours()


func cross_cells_from(origin_cell: Match3GridCellUI, only_usables: bool = false) -> Array[Match3GridCellUI]:
	var cross_cells:  Array[Match3GridCellUI] = []
	
	cross_cells.assign(Match3BoardPluginUtilities.remove_duplicates(
		grid_cells_from_row(origin_cell.row, only_usables) + grid_cells_from_column(origin_cell.column, only_usables)
		))
	
	return cross_cells


func cross_diagonal_cells_from(origin_cell: Match3GridCellUI, only_usables: bool = false) -> Array[Match3GridCellUI]:
	var distance: int = board.distance()
	var cross_diagonal_cells: Array[Match3GridCellUI] = []
	
	cross_diagonal_cells.assign(Match3BoardPluginUtilities.remove_falsy_values(
		Match3BoardPluginUtilities.remove_duplicates(
		  	diagonal_top_left_cells_from(origin_cell, distance, only_usables)\
		 	+ diagonal_top_right_cells_from(origin_cell, distance, only_usables)\
			+ diagonal_bottom_left_cells_from(origin_cell, distance, only_usables)\
		 	+ diagonal_bottom_right_cells_from(origin_cell, distance, only_usables)\
		)))
	
	return cross_diagonal_cells


func empty_cells() -> Array[Match3GridCellUI]:
	var cells: Array[Match3GridCellUI] = []
	cells.assign(board.grid_cells_flattened.filter(_is_empty_cell))
	
	return cells


func _is_empty_cell(cell: Match3GridCellUI) -> bool:
	return cell.can_contain_piece and cell.is_empty()


func _is_usable_cell(cell: Match3GridCellUI) -> bool:
	return cell.can_contain_piece and not cell.is_empty()
	
#region Pieces
	
func pieces_from_row(row: int) -> Array[Match3PieceUI]:
	var pieces: Array[Match3PieceUI] = []
	
	pieces.assign(grid_cells_from_row(row).filter(func(cell: Match3GridCellUI): return cell.has_piece())\
		.map(func(cell: Match3GridCellUI): return cell.piece))
	
	return pieces


func pieces_from_column(column: int) -> Array[Match3PieceUI]:
	var pieces: Array[Match3PieceUI] = []
	
	pieces.assign(grid_cells_from_column(column).filter(func(cell: Match3GridCellUI): return cell.has_piece())\
		.map(func(cell: Match3GridCellUI): return cell.piece))
		
	return pieces
#endregion
