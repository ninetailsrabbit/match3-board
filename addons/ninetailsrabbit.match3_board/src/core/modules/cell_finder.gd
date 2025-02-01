class_name Match3BoardCellFinder extends RefCounted


var board: Board


func _init(_board: Board) -> void:
	board = _board


func get_cell(column: int, row: int) -> Match3GridCell:
	if not board.grid_cells.is_empty() and column >= 0 and row >= 0:
		if column <= board.grid_cells.size() - 1 and row <= board.grid_cells[0].size() - 1:
			return board.grid_cells[column][row]
			
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
	var cross_cells: Array[Match3GridCell] = []
	
	cross_cells.assign(Match3BoardPluginUtilities.remove_duplicates(
		grid_cells_from_row(origin_cell.row) + grid_cells_from_column(origin_cell.column))
	)
	
	cross_cells.erase(origin_cell)
	
	return cross_cells
