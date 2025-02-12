class_name Match3LineConnector extends Line2D

signal connected_origin_piece(piece: Match3PieceUI)
signal connected_piece(piece: Match3PieceUI)
#signal match_selected(selected_pieces: Array[PieceUI])
#signal canceled_match(selected_pieces: Array[PieceUI])
#
@export var board: Match3BoardUI

var pieces_connected: Array[Match3PieceUI] = []
var origin_piece: Match3PieceUI

var detection_area: Area2D
#var previous_matches: Array[PieceUI] = []
#var possible_next_matches: Array[PieceUI] = []



func _enter_tree() -> void:
	name = "Match3LineConnector"
	
	
func _ready() -> void:
	if board == null:
		get_tree().get_first_node_in_group(Match3BoardUI.GroupName)
	
	_prepare_detection_area()
	
	board.selected_piece.connect(on_selected_origin_piece)
	board.piece_drag_started.connect(on_selected_origin_piece)
	connected_origin_piece.connect(on_connected_origin_piece)
	
	set_process(false)
	
	
func _process(_delta: float) -> void:
	if points.is_empty() or detection_area == null:
		return
		
	var mouse_position: Vector2 = get_global_mouse_position()
	
	remove_point(points.size() - 1)
	add_point(mouse_position)
	
	detection_area.global_position = mouse_position


func add_piece(new_piece: Match3PieceUI) -> void:
	new_piece.disable_detection_area()
	new_piece.disable_piece_area()
	
	if pieces_connected.is_empty():
		origin_piece = new_piece
		
	pieces_connected.append(new_piece)
	clear_points()
	
	for piece_connected: Match3PieceUI in pieces_connected:
		add_point(piece_connected.global_position)
	
	add_point(get_global_mouse_position())
	
	if pieces_connected.size() == 1:
		connected_origin_piece.emit(new_piece)
		
	connected_piece.emit(new_piece)

#func detect_new_matches_from_last_piece(last_piece: PieceUI) -> void:
	#var origin_cell: GridCellUI = last_piece.cell()
	#
	#if origin_cell is GridCellUI:
		#var adjacent_cells: Array[GridCellUI] = origin_cell.available_neighbours(true)
	#
		#previous_matches = possible_next_matches.duplicate()
		#possible_next_matches.clear()
		#
		#for cell: GridCellUI in adjacent_cells:
			#var piece: PieceUI = cell.current_piece as PieceUI
			#
			#if not pieces_connected.has(piece) and (piece.match_with(last_piece) or piece.is_special()):
				#possible_next_matches.append(piece)
#
#
#func consume_matches() -> void:
	#if pieces_connected.size() >= origin_piece.board.configuration.min_match or _connected_pieces_has_special():
		#var cells: Array[GridCellUI] = []
		#cells.assign(pieces_connected.map(func(piece: PieceUI): return piece.cell()))
		#
		#origin_piece.board.consume_requested.emit(Sequence.new(cells, Sequence.Shapes.LineConnected))
		#match_selected.emit(pieces_connected)
		#
		#queue_free()
	#else:
		#cancel()
		#
#
#func cancel() -> void:
	#set_process(false)
	#remove_point(points.size() - 1)
	#detection_area.process_mode = Node.PROCESS_MODE_DISABLED
	#canceled_match.emit(pieces_connected)
	#board.canceled_line_connector_match.emit(pieces_connected)
	#
	#queue_free()
#
#
#func _connected_pieces_has_special() -> bool:
	#return pieces_connected.any(func(piece: PieceUI): return piece.is_special())
	#
	#
func _prepare_detection_area() -> void:
	detection_area = Area2D.new()
	detection_area.name = "Match3LineConnectorDetectionArea"
	detection_area.collision_layer = 0
	detection_area.collision_mask = pow(2, board.configuration.pieces_collision_layer - 1)
	detection_area.monitorable = false
	detection_area.monitoring = false
	detection_area.process_priority = 2
	detection_area.disable_mode = CollisionObject2D.DISABLE_MODE_MAKE_STATIC
	detection_area.z_index = 100
	
	var collision_shape = CollisionShape2D.new()
	collision_shape.name = "Match3LineConnectorDetectionAreaCollisionShape2D"
	collision_shape.shape = RectangleShape2D.new()
	collision_shape.shape.size = board.configuration.cell_size / 2
	collision_shape.debug_color = Color.GREEN
	
	detection_area.add_child(collision_shape)
	detection_area.top_level = true

	add_child(detection_area)

	detection_area.area_entered.connect(on_piece_detected)
	
	
##region Signal callbacks
func on_selected_origin_piece(piece: Match3PieceUI) -> void:
	add_piece(piece)
	

func on_connected_origin_piece(piece: Match3PieceUI) -> void:
	piece.disable_piece_area()
	piece.disable_detection_area()
	
	set_process(true)
	top_level = true
	z_index = detection_area.z_index
	
	detection_area.monitoring = true
	detection_area.global_position = get_global_mouse_position()


func on_piece_detected(area: Area2D) -> void:
	var piece: Match3PieceUI = area.get_parent() as Match3PieceUI

	
#func on_piece_detected(other_area: Area2D) -> void:
	#var piece: PieceUI = other_area.get_parent() as PieceUI
	#
	#if possible_next_matches.has(piece):
		#add_piece(piece)
#
#
#func on_added_piece(piece: PieceUI) -> void:
	#piece.disable_piece_area()
	#
	#board.added_piece_to_line_connector.emit(piece)
	#
	#if pieces_connected.size() == 1:
		#origin_piece = piece
#
		#_prepare_detection_area(origin_piece)
	#
	#if pieces_connected.size() < origin_piece.board.configuration.max_match:
		#detect_new_matches_from_last_piece(piece)
		#board.cell_highlighter.remove_current_highlighters()
		#board.cell_highlighter.highlight_cells(board.grid_cells_from_pieces(possible_next_matches))
	#else:
		#if board.is_click_mode_drag():
			#consume_matches()
#
##endregion
