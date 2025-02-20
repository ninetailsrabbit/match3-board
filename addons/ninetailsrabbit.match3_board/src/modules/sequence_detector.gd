class_name Match3SequenceDetector extends RefCounted


var board: Match3Board


func _init(_board: Match3Board) -> void:
	board = _board


@warning_ignore("unassigned_variable")
func find_horizontal_sequences(cells: Array[Match3GridCell]) -> Array[Match3Sequence]:
	var sequences: Array[Match3Sequence] = []
	var current_matches: Array[Match3GridCell] = []
	
	if board.configuration.horizontal_shape:
		var valid_cells = cells.filter(func(cell: Match3GridCell): return cell.has_piece())
		var previous_cell: Match3GridCell
		
		for current_cell: Match3GridCell in valid_cells:
			
			if current_matches.is_empty() \
				or (previous_cell is Match3GridCell and previous_cell.is_row_neighbour_of(current_cell) and current_cell.piece.match_with(previous_cell.piece)):
				current_matches.append(current_cell)
				
				if current_matches.size() == board.configuration.max_match:
					sequences.append(Match3Sequence.new(current_matches, Match3Sequence.Shapes.Horizontal))
					current_matches.clear()
			else:
				if Match3BoardPluginUtilities.value_is_between(current_matches.size(), board.configuration.min_match, board.configuration.max_match):
					sequences.append(Match3Sequence.new(current_matches, Match3Sequence.Shapes.Horizontal))
				
				current_matches.clear()
				current_matches.append(current_cell)
			
			if current_cell == valid_cells.back() and Match3BoardPluginUtilities.value_is_between(current_matches.size(), board.configuration.min_match, board.configuration.max_match):
				sequences.append(Match3Sequence.new(current_matches, Match3Sequence.Shapes.Horizontal))
				
			previous_cell = current_cell
			
	sequences.sort_custom(_sort_by_size_descending)

	return sequences
	

@warning_ignore("unassigned_variable")
func find_vertical_sequences(cells: Array[Match3GridCell]) -> Array[Match3Sequence]:
	var sequences: Array[Match3Sequence] = []
	var current_matches: Array[Match3GridCell] = []
	
	if board.configuration.vertical_shape:
		var valid_cells = cells.filter(func(cell: Match3GridCell): return cell.has_piece())
		var previous_cell: Match3GridCell
		
		for current_cell: Match3GridCell in valid_cells:
			
			if current_matches.is_empty() \
				or (previous_cell is Match3GridCell and previous_cell.is_column_neighbour_of(current_cell) and current_cell.piece.match_with(previous_cell.piece)):
				current_matches.append(current_cell)
				
				if current_matches.size() == board.configuration.max_match:
					sequences.append(Match3Sequence.new(current_matches, Match3Sequence.Shapes.Vertical))
					current_matches.clear()
			else:
				if Match3BoardPluginUtilities.value_is_between(current_matches.size(), board.configuration.min_match, board.configuration.max_match):
					sequences.append(Match3Sequence.new(current_matches, Match3Sequence.Shapes.Vertical))
					
				current_matches.clear()
				current_matches.append(current_cell)
			
			if current_cell.in_same_grid_position_as(valid_cells.back().board_position()) and Match3BoardPluginUtilities.value_is_between(current_matches.size(), board.configuration.min_match, board.configuration.max_match):
				sequences.append(Match3Sequence.new(current_matches, Match3Sequence.Shapes.Vertical))
				
			previous_cell = current_cell
	
	sequences.sort_custom(_sort_by_size_descending)
	
	return sequences


func find_tshape_sequence(sequence_a: Match3Sequence, sequence_b: Match3Sequence):
	if board.configuration.tshape and sequence_a != sequence_b and  sequence_a.is_horizontal_or_vertical_shape() and sequence_b.is_horizontal_or_vertical_shape():
		var horizontal_sequence: Match3Sequence = sequence_a if sequence_a.is_horizontal_shape() else sequence_b
		var vertical_sequence: Match3Sequence = sequence_a if sequence_a.is_vertical_shape() else sequence_b
		
		if horizontal_sequence.is_horizontal_shape() and vertical_sequence.is_vertical_shape():
			var left_edge_cell: Match3GridCell = horizontal_sequence.left_edge_cell()
			var right_edge_cell: Match3GridCell = horizontal_sequence.right_edge_cell()
			var top_edge_cell: Match3GridCell = vertical_sequence.top_edge_cell()
			var bottom_edge_cell: Match3GridCell = vertical_sequence.bottom_edge_cell()
			var horizontal_middle_cell: Match3GridCell = horizontal_sequence.middle_cell()
			var vertical_middle_cell: Match3GridCell = vertical_sequence.middle_cell()

			var intersection_cell: Match3GridCell = board.finder.get_cell(horizontal_middle_cell.row, vertical_middle_cell.column)
			if intersection_cell in horizontal_sequence.cells and intersection_cell in vertical_sequence.cells and not (
				(left_edge_cell.in_same_position_as(intersection_cell) and top_edge_cell.in_same_position_as(intersection_cell)) \
				or (left_edge_cell.in_same_position_as(intersection_cell) and bottom_edge_cell.in_same_position_as(intersection_cell)) \
				or (right_edge_cell.in_same_position_as(intersection_cell) and top_edge_cell.in_same_position_as(intersection_cell)) \
				or (right_edge_cell.in_same_position_as(intersection_cell) and bottom_edge_cell.in_same_position_as(intersection_cell))
			):			
				var cells: Array[Match3GridCell] = []
				
				for cell: Match3GridCell in (horizontal_sequence.cells + vertical_sequence.cells):
					cells.append(cell)
								
				return Match3Sequence.new(cells, Match3Sequence.Shapes.TShape)
				
	return null


func find_lshape_sequence(sequence_a: Match3Sequence, sequence_b: Match3Sequence):
	if board.configuration.lshape and sequence_a != sequence_b and  sequence_a.is_horizontal_or_vertical_shape() and sequence_b.is_horizontal_or_vertical_shape():
		var horizontal_sequence: Match3Sequence = sequence_a if sequence_a.is_horizontal_shape() else sequence_b
		var vertical_sequence: Match3Sequence = sequence_a if sequence_a.is_vertical_shape() else sequence_b
		
		if horizontal_sequence.is_horizontal_shape() and vertical_sequence.is_vertical_shape():
			var left_edge_cell: Match3GridCell = horizontal_sequence.left_edge_cell()
			var right_edge_cell: Match3GridCell = horizontal_sequence.right_edge_cell()
			var top_edge_cell: Match3GridCell = vertical_sequence.top_edge_cell()
			var bottom_edge_cell: Match3GridCell = vertical_sequence.bottom_edge_cell()
		#
			if left_edge_cell.in_same_position_as(top_edge_cell) \
				or left_edge_cell.in_same_position_as(bottom_edge_cell) \
				or right_edge_cell.in_same_position_as(top_edge_cell) or right_edge_cell.in_same_position_as(bottom_edge_cell):
				
				var cells: Array[Match3GridCell] = []
				
				## We need to iterate manually to be able append the item type on the array
				for cell: Match3GridCell in (horizontal_sequence.cells + vertical_sequence.cells):
					cells.append(cell)
				
				return Match3Sequence.new(cells, Match3Sequence.Shapes.LShape)
				
	return null


func find_board_sequences() -> Array[Match3Sequence]:
	var horizontal_sequences: Array[Match3Sequence] = find_horizontal_board_sequences()
	var vertical_sequences: Array[Match3Sequence] = find_vertical_board_sequences()
	
	var valid_horizontal_sequences: Array[Match3Sequence] = []
	var valid_vertical_sequences: Array[Match3Sequence] = []
	
	var tshape_sequences: Array[Match3Sequence] = []
	var lshape_sequences: Array[Match3Sequence] = []
	
	if vertical_sequences.is_empty() and not horizontal_sequences.is_empty():
		valid_horizontal_sequences.append_array(horizontal_sequences)
	elif horizontal_sequences.is_empty() and not vertical_sequences.is_empty():
		valid_vertical_sequences.append_array(vertical_sequences)
	else:
		for horizontal_sequence: Match3Sequence in horizontal_sequences:
			var add_sequence: bool = true ## When false, the horizontal and vertical sequences are not added to valid ones
		
			for vertical_sequence: Match3Sequence in vertical_sequences:
				var lshape_sequence = find_lshape_sequence(horizontal_sequence, vertical_sequence)
				
				if lshape_sequence is Match3Sequence:
					lshape_sequences.append(lshape_sequence)
					add_sequence = false
				else:
					var tshape_sequence = find_tshape_sequence(horizontal_sequence, vertical_sequence)
				
					if tshape_sequence is Match3Sequence:
						tshape_sequences.append(tshape_sequence)
						add_sequence = false
				
				if add_sequence:
					valid_vertical_sequences.append(vertical_sequence)
				
			if add_sequence:
				valid_horizontal_sequences.append(horizontal_sequence)
			
	var result: Array[Match3Sequence] = valid_horizontal_sequences + valid_vertical_sequences + tshape_sequences + lshape_sequences
	
	return result


func find_horizontal_board_sequences() -> Array[Match3Sequence]:
	var horizontal_sequences: Array[Match3Sequence] = []
	
	for row in board.configuration.grid_height:
		horizontal_sequences.append_array(find_horizontal_sequences(board.finder.cells_from_row(row)))
	
	return horizontal_sequences


func find_vertical_board_sequences() -> Array[Match3Sequence]:
	var vertical_sequences: Array[Match3Sequence] = []
	
	for column in board.configuration.grid_width:
		vertical_sequences.append_array(find_vertical_sequences(board.finder.cells_from_column(column)))
	
	return vertical_sequences


func find_match_from_piece(piece: Match3Piece) -> Match3Sequence:
	return find_match_from_cell(piece.cell)
	
	
func find_match_from_cell(cell: Match3GridCell) -> Match3Sequence:
	if cell.has_piece():
		var horizontal_sequences: Array[Match3Sequence] = find_horizontal_board_sequences()
		var vertical_sequences: Array[Match3Sequence] = find_vertical_board_sequences()
		
		var horizontal = horizontal_sequences.filter(func(sequence: Match3Sequence): return sequence.cells.has(cell))
		var vertical = vertical_sequences.filter(func(sequence: Match3Sequence): return sequence.cells.has(cell))
		
		if not horizontal.is_empty() and not vertical.is_empty():
			var tshape_sequence = find_tshape_sequence(horizontal.front(), vertical.front())
			
			if tshape_sequence:
				return tshape_sequence
			
			var lshape_sequence = find_lshape_sequence(horizontal.front(), vertical.front())
			
			if lshape_sequence:
				return lshape_sequence
		else:
			if horizontal:
				return horizontal.front()
			
			if vertical:
				return vertical.front()
	
	return null


func _sort_by_size_descending(a: Match3Sequence, b: Match3Sequence) -> bool:
	return a.size() > b.size()
