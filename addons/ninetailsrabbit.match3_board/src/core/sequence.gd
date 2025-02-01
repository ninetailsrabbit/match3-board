class_name Match3Sequence extends RefCounted


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


var cells: Array[Match3GridCell] = []
var shape: Shapes = Shapes.Irregular


func _init(sequence_cells: Array[Match3GridCell], _shape: Shapes = Shapes.Irregular) -> void:
	cells.assign(Match3BoardPluginUtilities.remove_duplicates(sequence_cells.filter(func(grid_cell: Match3GridCell): return is_instance_valid(grid_cell) and grid_cell.can_contain_piece and grid_cell.has_piece())))
	shape = _detect_shape() if _shape == Shapes.Irregular else _shape


func _detect_shape() -> Shapes:
	if contains_special_piece():
		return Shapes.Special
		
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


func pieces() -> Array[Match3Piece]:
	var current_pieces: Array[Match3Piece] = []
	current_pieces.assign(Match3BoardPluginUtilities.remove_falsy_values(cells.map(func(grid_cell: Match3GridCell): return grid_cell.current_piece)))
	
	return current_pieces.filter(func(piece: PieceUI): return is_instance_valid(piece))


func normal_pieces() -> Array[Match3Piece]:
	return pieces().filter(func(piece: Match3Piece): return piece.is_normal())
	

func contains_special_piece() -> bool:
	return pieces().any(func(piece: Match3Piece): return piece.is_special())


#region Cell positions
func middle_cell() -> Match3GridCell:
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
