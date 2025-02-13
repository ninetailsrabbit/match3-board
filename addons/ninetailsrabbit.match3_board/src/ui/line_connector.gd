class_name Match3LineConnector extends Line2D

signal connected_origin_piece(piece: Match3PieceUI)
signal connected_piece(piece: Match3PieceUI)
signal max_connected_pieces_reached(pieces: Array[Match3PieceUI])
signal canceled_match(pieces: Array[Match3PieceUI])

@export var board: Match3BoardUI
@export var confirm_match_input_action: StringName = &"ui_accept"
@export var cancel_match_input_action: StringName = &"ui_cancel"
@export var auto_consume_when_release_drag: bool = false

var pieces_connected: Array[Match3PieceUI] = []
var origin_piece: Match3PieceUI
var detection_area: Area2D


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed(cancel_match_input_action):
		cancel()
	
	if board.configuration.click_mode_is_selection() and Input.is_action_just_pressed(confirm_match_input_action):
		pass ## TODO - CREATE SEQUENCE AND CONSUME


func _enter_tree() -> void:
	name = "Match3LineConnector"
	
	
func _ready() -> void:
	if board == null:
		get_tree().get_first_node_in_group(Match3BoardUI.GroupName)
	
	set_process(false)
	set_process_unhandled_input(false)
	_prepare_detection_area()
	
	board.selected_piece.connect(on_selected_origin_piece)
	board.piece_drag_started.connect(on_selected_origin_piece)
	board.piece_drag_ended.connect(on_piece_drag_ended)
	connected_origin_piece.connect(on_connected_origin_piece)
	
	
func _process(_delta: float) -> void:
	if points.is_empty() or detection_area == null:
		return
		
	var mouse_position: Vector2 = get_global_mouse_position()
	
	remove_point(points.size() - 1)
	add_point(mouse_position)
	
	detection_area.global_position = mouse_position


func can_connect_more_pieces() -> bool:
	return pieces_connected.size() < board.configuration.max_match


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


func matches_from_piece(piece: Match3PieceUI) -> Array[Match3GridCellUI]:
	var current_neighbours: Dictionary = piece.cell.usable_neighbours()
	
	var adjacent_cells: Array[Match3GridCellUI] = []
	adjacent_cells.assign(
		Match3BoardPluginUtilities.remove_falsy_values(current_neighbours.values())
		)
		 
	return adjacent_cells.filter(
		func(cell: Match3GridCellUI): 
		return is_instance_valid(cell.piece) and not pieces_connected.has(cell.piece) and cell.piece.match_with(origin_piece)
		)


func confirm_match() -> void:
	if pieces_connected.size() >= board.configuration.min_match:
		board.consume_sequences([Match3Sequence.create_from_pieces(pieces_connected, Match3Sequence.Shapes.LineConnected)])
		

func cancel() -> void:
	set_process(false)
	set_process_unhandled_input(false)
	clear_points()
	
	origin_piece = null
	detection_area.position = Vector2.ZERO
	detection_area.monitoring = false
	
	for piece in pieces_connected:
		piece.enable_piece_area()
		
	canceled_match.emit(pieces_connected)
	pieces_connected.clear()


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
	
	
#region Signal callbacks
func on_selected_origin_piece(piece: Match3PieceUI) -> void:
	if board.configuration.swap_mode_is_connect_line():
		add_piece(piece)
	

func on_connected_origin_piece(piece: Match3PieceUI) -> void:
	piece.disable_piece_area()
	
	set_process(true)
	set_process_unhandled_input(true)
	
	top_level = true
	z_index = detection_area.z_index
	
	detection_area.monitoring = true
	detection_area.global_position = get_global_mouse_position()


func on_connected_piece(piece: Match3PieceUI) -> void:
	pass


func on_piece_detected(area: Area2D) -> void:
	if can_connect_more_pieces():
		var detected_piece: Match3PieceUI = area.get_parent() as Match3PieceUI
		
		if detected_piece and detected_piece.cell.is_adjacent_to(pieces_connected.back().cell, true) and detected_piece.match_with(origin_piece):
			add_piece(detected_piece)
			
	else:
		max_connected_pieces_reached.emit(pieces_connected)
		
		
func on_piece_drag_ended() -> void:
	pass
#endregion
