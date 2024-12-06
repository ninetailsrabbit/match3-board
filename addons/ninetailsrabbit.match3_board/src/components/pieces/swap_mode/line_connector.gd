class_name LineConnector extends Line2D

signal added_piece(piece: PieceUI)
signal match_selected(selected_pieces: Array[PieceUI])
signal canceled_match(selected_pieces: Array[PieceUI])

var board: Match3Board
var pieces_connected: Array[PieceUI] = []
var detection_area: Area2D
var origin_piece: PieceUI
var previous_matches: Array[PieceUI] = []
var possible_next_matches: Array[PieceUI] = []


func _exit_tree() -> void:
	for piece: PieceUI in pieces_connected:
		piece.enable_piece_area()
		piece.disable_detection_area()
	
	board.cell_highlighter.remove_current_highlighters()


func _enter_tree() -> void:
	name = "LineConnector"
	width = 1.5
	default_color = Color.YELLOW
	
	added_piece.connect(on_added_piece)
	
	
func _ready() -> void:
	if board == null:
		get_tree().get_first_node_in_group(Match3Board.BoardGroupName)
		
	set_process(false)
	
	
func _process(_delta: float) -> void:
	if points.is_empty() or detection_area == null:
		return
		
	var mouse_position: Vector2 = get_global_mouse_position()
	
	remove_point(points.size() - 1)
	add_point(mouse_position)
	
	detection_area.global_position = mouse_position


	
func add_piece(new_piece: PieceUI) -> void:
	new_piece.disable_interaction_areas()
	
	pieces_connected.append(new_piece)
	clear_points()
	
	for piece_connected: PieceUI in pieces_connected:
		add_point(piece_connected.global_position)
	
	add_point(get_global_mouse_position())
	
	added_piece.emit(new_piece)


func detect_new_matches_from_last_piece(last_piece: PieceUI) -> void:
	var origin_cell: GridCellUI = last_piece.cell()
	
	if origin_cell is GridCellUI:
		var adjacent_cells: Array[GridCellUI] = origin_cell.available_neighbours(true)
	
		previous_matches = possible_next_matches.duplicate()
		possible_next_matches.clear()
		
		for cell: GridCellUI in adjacent_cells:
			var piece: PieceUI = cell.current_piece as PieceUI
			
			if not pieces_connected.has(piece) and piece.match_with(last_piece):
				possible_next_matches.append(piece)


func consume_matches() -> void:
	if pieces_connected.size() >= origin_piece.board.configuration.min_match:
		var cells: Array[GridCellUI] = []
		cells.assign(pieces_connected.map(func(piece: PieceUI): return piece.cell()))
		
		origin_piece.board.consume_requested.emit(Sequence.new(cells, Sequence.Shapes.LineConnected))
		match_selected.emit(pieces_connected)
		pieces_connected.clear()
		queue_free()
	else:
		cancel()
		

func cancel() -> void:
	set_process(false)
	remove_point(points.size() - 1)
	detection_area.process_mode = Node.PROCESS_MODE_DISABLED
	canceled_match.emit(pieces_connected)
	board.canceled_line_connector_match.emit(pieces_connected)
	
	queue_free()
	
	
func _prepare_detection_area(piece: PieceUI) -> void:
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
	piece.disable_piece_area()
	
	board.added_piece_to_line_connector.emit(piece)
	
	if pieces_connected.size() == 1:
		origin_piece = piece

		_prepare_detection_area(origin_piece)
	
	if pieces_connected.size() < origin_piece.board.configuration.max_match:
		detect_new_matches_from_last_piece(piece)
		board.cell_highlighter.remove_current_highlighters()
		board.cell_highlighter.highlight_cells(board.grid_cells_from_pieces(possible_next_matches))
	else:
		if board.is_click_mode_drag():
			consume_matches()

#endregion
