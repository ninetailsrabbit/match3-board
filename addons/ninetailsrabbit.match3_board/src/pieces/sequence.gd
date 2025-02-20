class_name Match3Sequence extends RefCounted

signal consumed(pieces: Array[Match3Piece])

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
var origin_special_piece: Match3PieceConfiguration


func _init(sequence_cells: Array[Match3GridCell], _shape: Shapes = Shapes.Irregular) -> void:
	cells.assign(Match3BoardPluginUtilities.remove_duplicates(sequence_cells.filter(
		func(cell: Match3GridCell): return cell.can_contain_piece and cell.has_piece() and is_instance_valid(cell.piece)))
		)
	
	shape = _detect_shape() if _shape == Shapes.Irregular else _shape
	

static func create_from_pieces(pieces: Array[Match3Piece], selected_shape: Shapes = Shapes.Irregular) -> Match3Sequence:
	var cells: Array[Match3GridCell] = []
	cells.assign(pieces.map(func(piece: Match3Piece): return piece.cell))
	
	return Match3Sequence.new(cells, selected_shape)
	
	
func duplicate() -> Match3Sequence:
	return Match3Sequence.new(cells.duplicate(true))

	
func all_pieces_are_the_same() -> bool:
	var origin_piece: Match3Piece = pieces().front()
	
	return pieces().all(func(piece: Match3Piece): return piece.match_with(origin_piece))

#region Pieces
func consume(remove_from_sequence: bool = false) -> void:
	consume_cells(cells, remove_from_sequence)
	
	
func consume_cells(consumable_cells: Array[Match3GridCell], remove_from_sequence: bool = false) -> void:
	if is_special_shape():
		assert(origin_special_piece != null, "Match3Sequence: This sequence with Special Shape needs a origin piece configuration to be set")

	var consumed_pieces: Array[Match3Piece] = []
	
	for cell: Match3GridCell in consumable_cells.filter(func(grid_cell: Match3GridCell): return grid_cell.has_piece() and is_instance_valid(grid_cell.piece)):
		consumed_pieces.append(cell.piece)
		consume_cell(cell, remove_from_sequence)
	
	if not consumed_pieces.is_empty():
		consumed.emit(consumed_pieces)
	

func consume_cell(consumable_cell: Match3GridCell, remove_from_sequence: bool = false) -> void:
	if cells.has(consumable_cell):
		consumable_cell.remove_piece()
		
		if remove_from_sequence:
			cells.erase(consumable_cell)


func consume_normal_cells() -> void:
	consume_cells(normal_cells())


func pieces() -> Array[Match3Piece]:
	var pieces: Array[Match3Piece] = []
	pieces.assign(cells.filter(func(cell: Match3GridCell): return cell.has_piece() and is_instance_valid(cell.piece))\
			.map(func(cell: Match3GridCell): return cell.piece))
	
	return pieces


func normal_pieces() -> Array[Match3Piece]:
	return pieces().filter(func(piece: Match3Piece): return piece.is_normal())


func normal_pieces_ids() -> Array[StringName]:
	return normal_pieces().map(func(piece: Match3Piece): return piece.id)


func contains_special_piece() -> bool:
	return pieces().any(func(piece: Match3Piece): return is_instance_valid(piece) and piece.is_special())


func special_pieces() -> Array[Match3Piece]:
	var result: Array[Match3Piece] = []
	
	result.assign(pieces().filter(
		func(piece: Match3Piece): 
			return is_instance_valid(piece) and piece.is_special() and not piece.on_queue and not piece.is_triggered)
		)
	
	if result.size() > 1:
		result.sort_custom(_sort_by_priority)
	
	return result
	
#endregion

#region Cell positions
func normal_cells() -> Array[Match3GridCell]:
	return cells.filter(func(cell: Match3GridCell): return cell.has_piece() and is_instance_valid(cell.piece) and cell.piece.is_normal())
	
	
func special_cells() -> Array[Match3GridCell]:
	return cells.filter(func(cell: Match3GridCell): return cell.has_piece() and is_instance_valid(cell.piece) and cell.piece.is_special())
	
	
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

#region Helpers
func size() -> int:
	return cells.size()
	
	
func combine_with(other_sequence: Match3Sequence) -> Match3Sequence:
	return Match3Sequence.new(cells + other_sequence.cells)

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
	if contains_special_piece():
		return Shapes.Special
		
	var is_horizontal: bool = false
	var is_vertical: bool = false
	var is_diagonal: bool = false
	
	for index: int in cells.size():
		is_horizontal = index == 0 or cells[index].in_same_column_as(cells[index - 1])
		is_vertical = index == 0 or cells[index].in_same_row_as(cells[index - 1])
		is_diagonal = index == 0 or cells[index].in_diagonal_with(cells[index - 1])
	
	## We don't need to detect TShape or LShape as this ones are set always manually when the sequence it's d
	if is_horizontal:
		return Shapes.Horizontal
	elif is_vertical:
		return Shapes.Vertical
	elif is_diagonal:
		return Shapes.Diagonal
	else:
		return Shapes.Irregular


func _sort_by_priority(a: Match3Piece, b: Match3Piece): 
	return a.priority > b.priority
