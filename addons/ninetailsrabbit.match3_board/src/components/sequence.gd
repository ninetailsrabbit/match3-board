class_name Sequence

signal consumed(pieces_consumed: Array[PieceConfiguration])

enum Shapes {
	Horizontal,
	Vertical,
	TShape,
	LShape,
	Diagonal,
	LineConnected,
	Cross,
	CrossDiagonal,
	Irregular,
	Special
}


var cells: Array[GridCellUI] = []
var shape: Shapes = Shapes.Irregular
var after_consumed: Callable = func(): pass


func _init(sequence_cells: Array[GridCellUI], _shape: Shapes = Shapes.Irregular) -> void:
	cells.assign(Match3BoardPluginUtilities.remove_duplicates(sequence_cells.filter(func(grid_cell: GridCellUI): return is_instance_valid(grid_cell) and grid_cell.can_contain_piece and grid_cell.has_piece())))
	shape = _detect_shape() if _shape == Shapes.Irregular else _shape


static func create_from_piece(piece: PieceUI) -> Sequence:
	return Sequence.new([piece.cell()])


static func create_from_pieces(pieces: Array[PieceUI]) -> Sequence:
	var cells: Array[GridCellUI] = []
	cells.assign(pieces.map(func(piece: PieceUI): return piece.cell()))
	
	return Sequence.new(cells)


func size() -> int:
	return cells.size()


func combine_with(other_sequence: Sequence) -> Sequence:
	return Sequence.new(cells + other_sequence.cells)


func consume() -> void:
	var pieces: Array[PieceUI] = []
	
	for cell: GridCellUI in cells.filter(func(grid_cell: GridCellUI): return grid_cell.has_piece()):
		pieces.append(cell.current_piece)
		await consume_cell(cell)
	
	consumed.emit(pieces)


func consume_except(except: Array[GridCellUI] = []) -> void:
	var pieces: Array[PieceUI] = []
	
	for cell: GridCellUI in cells.filter(func(grid_cell: GridCellUI): return not except.has(grid_cell) and grid_cell.has_piece()):
		pieces.append(cell.current_piece)
		consume_cell(cell)
	
	consumed.emit(pieces)


func consume_only(cells: Array[GridCellUI] = []) -> void:
	var pieces: Array[PieceUI] = []
	
	for cell: GridCellUI in cells.filter(func(grid_cell: GridCellUI): return grid_cell.has_piece()):
		pieces.append(cell.current_piece)
		consume_cell(cell)
	
	consumed.emit(pieces)


func consume_piece(piece: PieceUI, remove_from_sequence: bool = false) -> void:
	if pieces().has(piece):
		consume_cell(piece.cell())


func consume_cell(cell: GridCellUI, remove_from_sequence: bool = false) -> void:
	if cells.has(cell):
		var piece: PieceUI = cell.current_piece
		
		if is_instance_valid(piece) and piece != null:
			if await piece.consume(self):
				if remove_from_sequence:
					cells.erase(cell)


func pieces() -> Array[PieceUI]:
	var current_pieces: Array[PieceUI] = []
	current_pieces.assign(
		Match3BoardPluginUtilities.remove_falsy_values(cells.map(func(grid_cell: GridCellUI): return grid_cell.current_piece)))
	
	return current_pieces.filter(func(piece: PieceUI): return is_instance_valid(piece) and piece != null)


func add_cell(new_cell: GridCellUI) -> void:
	if not cells.has(new_cell):
		cells.append(new_cell)


func remove_cell(grid_cell: GridCellUI) -> void:
	cells.erase(grid_cell)


func remove_cells(grid_cells: Array[GridCellUI]) -> void:
	for cell: GridCellUI in grid_cells:
		remove_cell(cell)


func remove_cell_with_piece(piece: PieceUI) -> void:
	cells = cells.filter(func(cell: GridCellUI): return cell.current_piece != piece)


func remove_cells_with_pieces(pieces: Array[PieceUI]) -> void:
	for piece: PieceUI in pieces:
		remove_cell_with_piece(piece)


func all_pieces_are_same_shape() -> bool:
	if pieces().is_empty():
		return false
	else:
		if cells.any(func(cell: GridCellUI): return not cell.has_piece()):
			return false

		return pieces().all(func(piece: PieceUI): return piece.piece_definition.shape == pieces().front().piece_definition.shape)


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


func is_tshape_or_lshape() -> bool:
	return is_lshape() or is_tshape()


func is_diagonal_shape() -> bool:
	return shape == Shapes.Diagonal


func is_line_connected_shape() -> bool:
	return shape == Shapes.LineConnected


func is_special_shape() -> bool:
	return shape == Shapes.Special


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
