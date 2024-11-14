class_name LineConnector extends Line2D

signal added_piece(piece: PieceUI)
signal match_selected(selected_pieces: Array[PieceUI])

var board: Match3Board
var pieces_connected: Array[PieceUI] = []
var detection_area: Area2D
var origin_piece: PieceUI
var previous_matches: Array[PieceUI] = []
var possible_next_matches: Array[PieceUI] = []


func _exit_tree() -> void:
	match_selected.emit(pieces_connected)
	
	for piece: PieceUI in pieces_connected:
		piece.piece_area.process_mode = Node.PROCESS_MODE_INHERIT
		
	previous_matches.append_array(possible_next_matches)
	board.cell_highlighter.remove_current_highlighters()
	
	if detection_area and not detection_area.is_queued_for_deletion():
		detection_area.queue_free()


func _enter_tree() -> void:
	width = 1.5
	default_color = Color.YELLOW
	
	added_piece.connect(on_added_piece)
	match_selected.connect(on_line_match_selected)
	
	
func _ready() -> void:
	if board == null:
		get_tree().get_first_node_in_group(Match3Preloader.BoardGroupName)
		
	set_process(false)
	
	
func _process(_delta: float) -> void:
	if points.is_empty() or detection_area == null:
		return
		
	var mouse_position: Vector2 = get_global_mouse_position()
	
	remove_point(points.size() - 1)
	add_point(mouse_position)
	
	detection_area.global_position = mouse_position
	
	
func add_piece(new_piece: PieceUI) -> void:
	new_piece.piece_area.process_mode = Node.PROCESS_MODE_DISABLED
	
	pieces_connected.append(new_piece)
	clear_points()
	
	for piece_connected: PieceUI in pieces_connected:
		add_point(piece_connected.global_position)
	
	add_point(get_global_mouse_position())
	
	added_piece.emit(new_piece)


func detect_new_matches_from_last_piece(last_piece: PieceUI) -> void:
	var origin_cell: GridCellUI = last_piece.board.grid_cell_from_piece(last_piece)
	
	if origin_cell is GridCellUI:
		var adjacent_cells: Array[GridCellUI] = origin_cell.available_neighbours(true)
	
		previous_matches = possible_next_matches.duplicate()
		possible_next_matches.clear()
		
		for cell: GridCellUI in adjacent_cells:
			var piece: PieceUI = cell.current_piece as PieceUI
			
			if not pieces_connected.has(piece) and piece.match_with(last_piece):
				possible_next_matches.append(piece)
		

func prepare_detection_area(piece: PieceUI) -> void:
	z_index = piece.z_index
	z_as_relative = piece.z_as_relative
	
	detection_area = Area2D.new()
	detection_area.collision_layer = 0
	detection_area.collision_mask = piece.piece_area.collision_layer
	detection_area.monitorable = false
	detection_area.monitoring = true
	detection_area.process_priority = 2
	detection_area.disable_mode = CollisionObject2D.DISABLE_MODE_MAKE_STATIC
	detection_area.z_index = piece.z_index
	detection_area.z_as_relative = piece.z_as_relative
	
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
	var piece: PieceUI = other_area.get_parent() as PieceUI
	
	if possible_next_matches.has(piece):
		add_piece(piece)


func on_added_piece(piece: PieceUI) -> void:
	if pieces_connected.size() == 1:
		origin_piece = piece

		prepare_detection_area(origin_piece)
		
	if pieces_connected.size() < piece.board.max_match:
		detect_new_matches_from_last_piece(piece)
		board.cell_highlighter.remove_current_highlighters()
		board.cell_highlighter.highlight_cells(board.grid_cells_from_pieces(possible_next_matches))
		
	else:
		set_process(false)
		remove_point(points.size() - 1)
		detection_area.process_mode = Node.PROCESS_MODE_DISABLED
		queue_free()


func on_line_match_selected(selected_pieces: Array[PieceUI]) -> void:
	var cells: Array[GridCellUI] = []
	cells.assign(selected_pieces.map(func(piece: PieceUI): return piece.board.grid_cell_from_piece(piece)))
	
	origin_piece.board.consume_requested.emit(Sequence.new(cells, Sequence.Shapes.LineConnected))
	
#endregion
