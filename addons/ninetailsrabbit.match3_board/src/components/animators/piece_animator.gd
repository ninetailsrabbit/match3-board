class_name PieceAnimator extends Node

signal animation_started
signal animation_finished

@onready var board = get_tree().get_first_node_in_group(Match3Board.BoardGroupName)

var animation_running: bool = false


func _enter_tree() -> void:
	name = "PieceAnimator"
	
	animation_started.connect(on_animation_started)
	animation_finished.connect(on_animation_finished)


func swap_pieces(from: PieceUI, to: PieceUI):
	animation_started.emit()
	
	var from_position: Vector2 = from.position
	var to_position: Vector2 = to.position
	var tween: Tween = create_tween().set_parallel(true)
	
	tween.tween_property(from, "position", to_position, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(from, "modulate:a", 0.1, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(to, "position", from_position, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(to, "modulate:a", 0.1, 0.2).set_ease(Tween.EASE_IN)
	tween.chain()
	
	tween.tween_property(from, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(to, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	animation_finished.emit()


func fall_down(piece: PieceUI, empty_cell: GridCellUI, _is_diagonal: bool = false):
	animation_started.emit()
	
	if is_instance_valid(piece):
		var tween: Tween = create_tween()
		
		tween.tween_property(piece, "position", empty_cell.position, 0.2)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
			
		await tween.finished
	
	animation_finished.emit()


func fall_down_pieces(movements: Array[Match3Board.FallMovement]) -> void:
	animation_started.emit()
	
	if movements.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for movement: Match3Board.FallMovement in movements.filter(func(movement): return is_instance_valid(movement.to_cell.current_piece)):
			tween.tween_property(movement.to_cell.current_piece, "position", movement.to_cell.position, 0.1)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
			
		await tween.finished
		
	animation_finished.emit()


func spawn_pieces(new_pieces: Array[PieceUI]):
	animation_started.emit()
	
	if new_pieces.size() > 0:
		
		var tween: Tween = create_tween().set_parallel(true)
		
		for piece: PieceUI in new_pieces.filter(func(piece): return is_instance_valid(piece)):
			var fall_distance = piece.cell_size.y * board.grid_height
			piece.hide()
			tween.tween_property(piece, "visible", true, 0.1)
			tween.tween_property(piece, "position", piece.position, 0.25)\
				.set_trans(Tween.TRANS_QUAD).from(Vector2(piece.position.x, piece.position.y - fall_distance))
			
		await tween.finished
	
	animation_finished.emit()


func consume_sequence(sequence: Sequence):
	animation_started.emit()
	
	if sequence.pieces().size() > 0:
		
		var tween: Tween = create_tween().set_parallel(true)
		
		for piece: PieceUI in sequence.pieces():
			tween.tween_property(piece, "scale", Vector2.ZERO, 0.15).set_ease(Tween.EASE_OUT)
		
		await tween.finished
		
	animation_finished.emit()


func consume_pieces(pieces: Array[PieceUI]):
	animation_started.emit()
	
	if pieces.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for piece: PieceUI in pieces.filter(func(piece: PieceUI): return is_instance_valid(piece)):
			tween.tween_property(piece, "scale", Vector2.ZERO, 0.15).set_ease(Tween.EASE_OUT)
		
		await tween.finished
		
	animation_finished.emit()
		
		
func spawn_piece(target_cell: GridCellUI, new_piece: PieceUI):
		animation_started.emit()
		
		if is_instance_valid(new_piece) and target_cell.current_piece == new_piece:
			new_piece.hide()
			var tween: Tween = create_tween().set_parallel(true)
			
			tween.tween_property(target_cell.current_piece, "position", target_cell.position, 0.15)\
				.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			tween.chain()
			tween.tween_property(new_piece, "visible", true, 0.1)
			
			await tween.finished
			
		animation_finished.emit()


func on_animation_started() -> void:
	animation_running = true
	
	
func on_animation_finished() -> void:
	animation_running = false
