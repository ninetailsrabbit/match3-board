class_name LineConnector extends Line2D

signal added_piece(piece: LineConnectorPiece)
signal match_selected(selected_pieces: Array[LineConnectorPiece])

var pieces_connected: Array[LineConnectorPiece] = []
var detection_area: Area2D
var origin_piece: LineConnectorPiece
var previous_matches: Array[LineConnectorPiece] = []
var possible_next_matches: Array[LineConnectorPiece] = []


func _exit_tree() -> void:
	match_selected.emit(pieces_connected)
	
	for piece: LineConnectorPiece in pieces_connected:
		piece.piece_area.process_mode =Node.PROCESS_MODE_INHERIT
		
	previous_matches.append_array(possible_next_matches)
	## TODO DESELECT HIGHLIGHTER ON THIS MATCHES
	
	if detection_area and not detection_area.is_queued_for_deletion():
		detection_area.queue_free()


func _enter_tree() -> void:
	width = 1.5
	default_color = Color.YELLOW
	
	added_piece.connect(on_added_piece)
	match_selected.connect(on_line_match_selected)
	
	
func _ready() -> void:
	set_process(false)
	
	
func _process(_delta: float) -> void:
	if points.is_empty() or detection_area == null:
		return
		
	var mouse_position: Vector2 = get_global_mouse_position()
	
	remove_point(points.size() - 1)
	add_point(mouse_position)
	
	detection_area.global_position = mouse_position
	
	
func add_piece(new_piece: LineConnectorPiece) -> void:
	new_piece.piece_area.process_mode = Node.PROCESS_MODE_DISABLED
	
	pieces_connected.append(new_piece)
	clear_points()
	
	for piece_connected: LineConnectorPiece in pieces_connected:
		add_point(piece_connected.global_position)
	
	add_point(get_global_mouse_position())
	
	added_piece.emit(new_piece)


func detect_new_matches_from_last_piece(last_piece: LineConnectorPiece) -> void:
	var origin_cell: GridCellUI = last_piece.board.grid_cell_from_piece(last_piece)
	
	if origin_cell is GridCellUI:
		var adjacent_cells: Array[GridCellUI] = origin_cell.available_neighbours(true)
	
		previous_matches = possible_next_matches.duplicate()
		possible_next_matches.clear()
		
		for cell: GridCellUI in adjacent_cells:
			var piece: LineConnectorPiece = cell.current_piece as LineConnectorPiece
			
			if not pieces_connected.has(piece) and piece.match_with(last_piece):
				possible_next_matches.append(piece)
		

func prepare_detection_area(piece: PieceUI) -> void:
	detection_area = Area2D.new()
	detection_area.collision_layer = 0
	detection_area.collision_mask = piece.board.pieces_collision_layer
	detection_area.monitorable = false
	detection_area.monitoring = true
	detection_area.process_priority = 2
	detection_area.disable_mode = CollisionObject2D.DISABLE_MODE_MAKE_STATIC
	
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = RectangleShape2D.new()
	collision_shape.shape.size = origin_piece.cell_size / 2
	
	detection_area.add_child(collision_shape)
	
	get_tree().root.add_child(detection_area)
	
	detection_area.global_position = get_global_mouse_position()
	detection_area.area_entered.connect(on_piece_detected)
	
	origin_piece.piece_area.process_mode = Node.PROCESS_MODE_DISABLED
	set_process(true)
	
	
#region Signal callbacks
func on_piece_detected(other_area: Area2D) -> void:
	var piece: LineConnectorPiece = other_area.get_parent() as LineConnectorPiece
	
	if possible_next_matches.has(piece):
		add_piece(piece)


func on_added_piece(piece: LineConnectorPiece) -> void:
	if pieces_connected.size() == 1:
		origin_piece = piece
		z_index = origin_piece.z_index + 25
		z_as_relative = true
		prepare_detection_area(origin_piece)
		
	if pieces_connected.size() < piece.board.max_match:
		detect_new_matches_from_last_piece(piece)
	
		## TODO - CELL HIGHLIGHTERS HERE
		
	else:
		set_process(false)
		remove_point(points.size() - 1)
		detection_area.process_mode = Node.PROCESS_MODE_DISABLED
		
	
func on_line_match_selected(selected_pieces: Array[LineConnectorPiece]) -> void:
	var cells: Array[GridCellUI] = []
	cells.assign(selected_pieces.map(func(piece: PieceUI): return piece.board.grid_cell_from_piece(piece)))
	
	origin_piece.board.consume_requested.emit(Sequence.new(cells, Sequence.Shapes.LineConnected))
	
#endregion
