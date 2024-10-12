class_name PieceAnimator extends Node

@onready var board = get_tree().get_first_node_in_group(Match3Preloader.BoardGroupName)

func _enter_tree() -> void:
	name = "PieceAnimator"


func swap_pieces(from: PieceUI, to: PieceUI):
		var from_global_position: Vector2 = from.global_position
		var to_global_position: Vector2 = to.global_position
		var tween: Tween = create_tween().set_parallel(true)
		
		tween.tween_property(from, "global_position", to_global_position, 0.2).set_ease(Tween.EASE_IN)
		tween.tween_property(from, "modulate:a", 0.1, 0.2).set_ease(Tween.EASE_IN)
		tween.tween_property(to, "global_position", from_global_position, 0.2).set_ease(Tween.EASE_IN)
		tween.tween_property(to, "modulate:a", 0.1, 0.2).set_ease(Tween.EASE_IN)
		tween.chain()
		
		tween.tween_property(from, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
		tween.tween_property(to, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
		
		await tween.finished


func fall_down(piece: PieceUI, empty_cell: GridCellUI, _is_diagonal: bool = false):
	var tween: Tween = create_tween()
	
	tween.tween_property(piece, "global_position", empty_cell.global_position, 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
		
	await tween.finished


func fall_down_pieces(movements) -> void:
	if movements.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for movement in movements:
			tween.tween_property(movement.to_cell.current_piece, "global_position", movement.to_cell.global_position, 0.2)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
			
		await tween.finished


func spawn_pieces(new_pieces: Array[PieceUI]):
	if new_pieces.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for piece: PieceUI in new_pieces:
			var fall_distance = piece.cell_size.y * board.grid_height
			piece.hide()
			tween.tween_property(piece, "visible", true, 0.1)
			tween.tween_property(piece, "global_position", piece.global_position, 0.25)\
				.set_trans(Tween.TRANS_QUAD).from(Vector2(piece.global_position.x, piece.global_position.y - fall_distance))
			
		await tween.finished


func consume_sequence(sequence: Sequence):
	if sequence.pieces().size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for piece: PieceUI in sequence.pieces():
			tween.tween_property(piece, "scale", Vector2.ZERO, 0.15).set_ease(Tween.EASE_OUT)
			
		await tween.finished
		
		
func spawn_special_piece(sequence: Sequence, new_piece: PieceUI):
	if sequence.pieces().size() > 0:
		var middle_cell: GridCellUI = sequence.middle_cell()
		new_piece.hide()
		var tween: Tween = create_tween().set_parallel(true)
		
		for cell in sequence.cells.filter(func(grid_cell: GridCellUI): return grid_cell.has_piece() and grid_cell != middle_cell):
			tween.tween_property(cell.current_piece, "global_position", middle_cell.global_position, 0.15)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.chain()
		tween.tween_property(new_piece, "visible", true, 0.1)
		
		await tween.finished
