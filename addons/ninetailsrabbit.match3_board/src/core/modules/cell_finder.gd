class_name Match3BoardCellFinder extends RefCounted


var board: Board


func _init(_board: Board) -> void:
	board = _board


func get_cell(column: int, row: int) -> Match3GridCell:
	if not board.grid_cells.is_empty() and column >= 0 and row >= 0:
		if column <= board.grid_cells.size() - 1 and row <= board.grid_cells[0].size() - 1:
			return board.grid_cells[column][row]
			
	return null

## For some reason, the .has() method is not valid to detect valid cells in a list
## so I'll change it instead to do a comparison using the board position value
#func cells_contains_cell(cells: Array[Match3GridCell], target_cell: Match3GridCell) -> bool:
	#var found_cells: Array[Match3GridCell] = cells.filter(
		#func(cell: Match3GridCell): return cell.in_same_position_as(target_cell)
		#)
		#
	#return found_cells.size() > 0
		#

func grid_cell_from_piece(piece: Match3Piece) -> Match3GridCell:
	var found_pieces = board.grid_cells_flattened.filter(
		func(cell: Match3GridCell): return cell.has_piece() and cell.current_piece == piece
	)
	
	if found_pieces.size() == 1:
		return found_pieces.front()
	
	return null
	
	
func grid_cells_from_row(row: int) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	
	if board.grid_cells.size() > 0 and Match3BoardPluginUtilities.value_is_between(row, 0, board.grid_height - 1):
		for column: int in board.grid_width:
			cells.append(board.grid_cells[column][row])
	
	return cells
	

func grid_cells_from_column(column: int) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
		
	if board.grid_cells.size() > 0 and Match3BoardPluginUtilities.value_is_between(column, 0, board.grid_width - 1):
		for row: int in board.grid_height:
			cells.append(board.grid_cells[column][row])
	
	return cells


func top_cells_from(origin_cell: Match3GridCell) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	var current_cell: Match3GridCell = origin_cell
	
	if current_cell.is_top_border():
		return []
	
	while current_cell.neighbours()["top"] != null:
		current_cell = current_cell.neighbours()["top"]
		cells.append(current_cell)
	
	return cells
	

func bottom_cells_from(origin_cell: Match3GridCell) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	var current_cell: Match3GridCell = origin_cell
	
	if current_cell.is_bottom_border():
		return []
	
	while current_cell.neighbours()["bottom"] != null:
		current_cell = current_cell.neighbours()["bottom"]
		cells.append(current_cell)
	
	return cells
	

func right_cells_from(origin_cell: Match3GridCell) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	var current_cell: Match3GridCell = origin_cell
	
	if current_cell.is_right_border():
		return []
	
	while current_cell.neighbours()["right"] != null:
		current_cell = current_cell.neighbours()["right"]
		cells.append(current_cell)
	
	return cells
	

func left_cells_from(origin_cell: Match3GridCell) -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	var current_cell: Match3GridCell = origin_cell
	
	if current_cell.is_left_border():
		return []
	
	while current_cell.neighbours()["left"] != null:
		current_cell = current_cell.neighbours()["left"]
		cells.append(current_cell)
	
	return cells
	

func diagonal_top_right_cells_from(cell: Match3GridCell, distance: int) -> Array[Match3GridCell]:
	var diagonal_cells: Array[Match3GridCell] = []
	
	distance = clamp(distance, 0, board.grid_width)
	var current_cell = cell.diagonal_neighbour_top_right
	
	if distance > 0 and current_cell is Match3GridCell:
		diagonal_cells.append_array(([current_cell] as Array[Match3GridCell]) + diagonal_top_right_cells_from(current_cell, distance - 1))
	
	return diagonal_cells


func diagonal_top_left_cells_from(cell: Match3GridCell, distance: int) -> Array[Match3GridCell]:
	var diagonal_cells: Array[Match3GridCell] = []
	
	distance = clamp(distance, 0, board.grid_width)
	var current_cell = cell.diagonal_neighbour_top_left
	
	if distance > 0 and current_cell is Match3GridCell:
		diagonal_cells.append_array(([current_cell] as Array[Match3GridCell]) + diagonal_top_left_cells_from(current_cell, distance - 1))
	
	return diagonal_cells


func diagonal_bottom_left_cells_from(cell: Match3GridCell, distance: int) -> Array[Match3GridCell]:
	var diagonal_cells: Array[Match3GridCell] = []
	
	distance = clamp(distance, 0, board.grid_width)
	var current_cell = cell.diagonal_neighbour_bottom_left
	
	if distance > 0 and current_cell is Match3GridCell:
		diagonal_cells.append_array(([current_cell] as Array[Match3GridCell]) + diagonal_bottom_left_cells_from(current_cell, distance - 1))
	
	return diagonal_cells


func diagonal_bottom_right_cells_from(cell: Match3GridCell, distance: int) -> Array[Match3GridCell]:
	var diagonal_cells: Array[Match3GridCell] = []
	
	distance = clamp(distance, 0, board.grid_width)
	var current_cell = cell.diagonal_neighbour_bottom_right
	
	if distance > 0 and current_cell is Match3GridCell:
		diagonal_cells.append_array(([current_cell] as Array[Match3GridCell]) + diagonal_bottom_right_cells_from(current_cell, distance - 1))
	
	return diagonal_cells


func adjacent_cells_from(origin_cell: Match3GridCell) -> Dictionary:
	return origin_cell.neighbours()


func cross_cells_from(origin_cell: Match3GridCell) -> Array[Match3GridCell]:
	var cross_cells:  Array[Match3GridCell] = []
	
	cross_cells.assign(Match3BoardPluginUtilities.remove_duplicates(
			grid_cells_from_row(origin_cell.row) + grid_cells_from_column(origin_cell.column)
		))
	
	#for cell: Match3GridCell in cross_cells:
		#print("cross cell position ", Vector2(cell.column, cell.row))
	#
	return cross_cells


func cross_diagonal_cells_from(origin_cell: Match3GridCell) -> Array[Match3GridCell]:
	var distance: int = board.distance()
	var cross_diagonal_cells: Array[Match3GridCell] = []
	
	cross_diagonal_cells.assign(Match3BoardPluginUtilities.remove_falsy_values(
		Match3BoardPluginUtilities.remove_duplicates(
		  	diagonal_top_left_cells_from(origin_cell, distance)\
		 	+ diagonal_top_right_cells_from(origin_cell, distance)\
			+ diagonal_bottom_left_cells_from(origin_cell, distance)\
		 	+ diagonal_bottom_right_cells_from(origin_cell, distance)\
		)))
	
	return cross_diagonal_cells

func empty_cells() -> Array[Match3GridCell]:
	var cells: Array[Match3GridCell] = []
	cells.assign(board.grid_cells_flattened.filter(_is_empty_cell))
	
	return cells
	
	
func last_empty_cell_on_column(column: int) -> Match3GridCell:
	var column_cells: Array[Match3GridCell] = grid_cells_from_column(column)
	column_cells.reverse()
	
	var current_empty_cells = column_cells.filter(_is_empty_cell)
	
	if current_empty_cells.size() > 0:
		return current_empty_cells.front()
	
	return null


func _is_empty_cell(cell: Match3GridCell) -> bool:
	return cell.can_contain_piece and cell.is_empty()
