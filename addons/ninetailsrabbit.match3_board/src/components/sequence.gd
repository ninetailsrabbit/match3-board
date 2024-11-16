class_name Sequence

signal consumed(pieces_consumed: Array[PieceDefinitionResource])

enum Shapes {
	Horizontal,
	Vertical,
	TShape,
	LShape,
	Diagonal,
	LineConnected,
	Cross,
	CrossDiagonal,
	Irregular
}


var cells: Array[GridCellUI] = []
var shape: Shapes = Shapes.Irregular
var generated_from_swap: bool = false


func _init(_cells: Array[GridCellUI], _shape: Shapes = Shapes.Irregular) -> void:
	cells = _cells.filter(func(grid_cell: GridCellUI): return grid_cell.can_contain_piece and grid_cell.has_piece())
	shape = _detect_shape() if _shape == Shapes.Irregular else _shape


func size() -> int:
	return cells.size()
	
	
func consume(except: Array[GridCellUI] = []) -> void:
	consumed.emit(pieces())
	
	for cell: GridCellUI in cells.filter(func(grid_cell: GridCellUI): return not except.has(grid_cell)):
		consume_cell(cell)


func consume_cell(cell: GridCellUI) -> void:
	if cells.has(cell):
		var removed_piece = cell.remove_piece()
		
		if removed_piece is PieceUI:
			removed_piece.consumed.emit()
			removed_piece.queue_free()


func pieces() -> Array[PieceUI]:
	var current_pieces: Array[PieceUI] = []
	
	current_pieces.assign(Match3BoardPluginUtilities.remove_falsy_values(cells.map(func(grid_cell: GridCellUI): return grid_cell.current_piece)))
	
	return current_pieces
	

func contains_special_piece() -> bool:
	return pieces().any(func(piece: PieceUI): return piece.is_special())


func get_special_piece():
	if contains_special_piece():
		return pieces().filter(func(piece: PieceUI): return piece.is_special()).front()
	
	return null


func add_cell(new_cell: GridCellUI) -> void:
	if not cells.has(new_cell):
		cells.append(new_cell)


func remove_cell(grid_cell: GridCellUI) -> void:
	cells.erase(grid_cell)


func remove_cell_with_piece(piece: PieceUI) -> void:
	cells = cells.filter(func(cell: GridCellUI): return cell.current_piece != piece)


func all_pieces_are_special(type: PieceDefinitionResource.PieceType) -> bool:
	if pieces().is_empty():
		return false
	else:
		return pieces().all(func(piece: PieceUI): return piece.is_special())


func all_pieces_are_of_type(type: PieceDefinitionResource.PieceType) -> bool:
	if pieces().is_empty():
		return false
	else:
		return pieces().all(func(piece: PieceUI): return piece.piece_definition.type == type)


func all_pieces_are_of_shape(shape: String) -> bool:
	if pieces().is_empty():
		return false
	else:
		return pieces().all(func(piece: PieceUI): return piece.piece_definition.shape.to_lower() == shape.strip_edges().to_lower())


#region Cell position in sequence
func middle_cell() -> GridCellUI:
	return Match3BoardPluginUtilities.middle_element(cells)


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
