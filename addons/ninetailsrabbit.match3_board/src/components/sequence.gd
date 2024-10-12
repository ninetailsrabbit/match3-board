class_name Sequence

signal consumed(pieces_consumed: Array[PieceDefinitionResource])

enum Shapes {
	Horizontal,
	Vertical,
	TShape,
	LShape,
	Diagonal,
	LineConnected,
	Irregular
}


var cells: Array[GridCellUI] = []
var shape: Shapes = Shapes.Irregular


func _init(_cells: Array[GridCellUI], _shape: Shapes = Shapes.Irregular) -> void:
	cells = _cells.filter(func(grid_cell: GridCellUI): return grid_cell.has_piece())
	shape = _detect_shape() if _shape == Shapes.Irregular else _shape


func size() -> int:
	return cells.size()
	
	
func consume(except: Array[GridCellUI] = []) -> void:
	var pieces_consumed: Array[PieceDefinitionResource] = []
	pieces_consumed.assign(self.pieces().map(func(piece: PieceUI): return piece.piece_definition))
	
	consumed.emit(pieces_consumed)
	
	for cell: GridCellUI in cells.filter(func(grid_cell: GridCellUI): return not except.has(grid_cell)):
		consume_cell(cell)


func consume_cell(cell: GridCellUI) -> void:
	if cells.has(cell):
		var removed_piece = cell.remove_piece()
		
		if removed_piece is PieceUI:
			removed_piece.queue_free()


func contain_special_piece() -> bool:
	return pieces().filter(func(piece: PieceUI): return piece.piece_definition.is_special()).size() > 0


func pieces() -> Array[PieceUI]:
	var current_pieces: Array[PieceUI] = []
	
	current_pieces.assign(PluginUtilities.remove_falsy_values(cells.map(func(grid_cell: GridCellUI): return grid_cell.current_piece)))
	
	return current_pieces
	

func all_pieces_are_of_type(type: PieceDefinitionResource.PieceType) -> bool:
	if pieces().is_empty():
		return false
	else:
		return pieces().all(func(piece: PieceUI): return piece.piece_definition.type == type)


#region Cell position in sequence
func middle_cell() -> GridCellUI:
	return PluginUtilities.middle_element(cells)


func top_edge_cell():
	if shape == Shapes.Vertical:
		return cells.front()
		
	return null
	
	
func bottom_edge_cell():
	if shape == Shapes.Vertical:
		return cells.back()
		
	return null


func right_edge_cell():
	if shape == Shapes.Horizontal:
		return cells.back()
	
	return null
	
	
func left_edge_cell():
	if shape == Shapes.Horizontal:
		return cells.front()

	return null
	
#endregion


#region Shape detector
func is_horizontal_shape() -> bool:
	return shape == Shapes.Horizontal


func is_vertical_shape() -> bool:
	return shape == Shapes.Vertical


func is_horizontal_or_vertical_shape() -> bool:
	return is_horizontal_shape() or is_vertical_shape()


func is_tshape() -> bool:
	return shape == Shapes.TShape


func is_lshape() -> bool:
	return shape == Shapes.LShape


func is_diagonal_shape() -> bool:
	return shape == Shapes.Diagonal


func is_line_connected_shape() -> bool:
	return shape == Shapes.LineConnected
	
	
func _detect_shape() -> Shapes:
	var is_horizontal: bool = false
	var is_vertical: bool = false
	var is_diagonal: bool = false
	
	for index: int in cells.size():
		is_horizontal = index == 0 or cells[index].in_same_column_as(cells[index - 1])
		is_vertical = index == 0 or cells[index].in_same_row_as(cells[index - 1])
		is_diagonal = index == 0 or cells[index].in_diagonal_with(cells[index - 1])
	
	## We don't need to detect TShape or LShape as this ones are set always manually when the sequence it's created
	if is_horizontal:
		return Shapes.Horizontal
	elif is_vertical:
		return Shapes.Vertical
	elif is_diagonal:
		return Shapes.Diagonal
	else:
		return Shapes.Irregular
#endregion
