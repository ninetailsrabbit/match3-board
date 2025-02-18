class_name Match3DemoAnimator extends Match3Animator


func swap_pieces(from_piece: Match3Piece, to_piece: Match3Piece, from_piece_position: Vector2, to_piece_position: Vector2):
	animation_started.emit(SwapPiecesAnimation)
	
	var tween: Tween = create_tween().set_parallel(true)
	
	tween.tween_property(from_piece, "position", from_piece_position, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(from_piece, "modulate:a", 0.1, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(to_piece, "position", to_piece_position, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(to_piece, "modulate:a", 0.1, 0.2).set_ease(Tween.EASE_IN)
	tween.chain()
	
	tween.tween_property(from_piece, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(to_piece, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	animation_finished.emit(SwapPiecesAnimation)
	
	
func swap_rejected_pieces(from_piece: Match3Piece, to_piece: Match3Piece, from_piece_position: Vector2, to_piece_position: Vector2):
	animation_started.emit(SwapRejectedPiecesAnimation)
	
	var tween: Tween = create_tween().set_parallel(true)
	
	tween.tween_property(from_piece, "position", from_piece_position, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(from_piece, "modulate:a", 0.1, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(to_piece, "position", to_piece_position, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(to_piece, "modulate:a", 0.1, 0.2).set_ease(Tween.EASE_IN)
	tween.chain()
	
	tween.tween_property(from_piece, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(to_piece, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	animation_finished.emit(SwapRejectedPiecesAnimation)
	
	
func consume_sequence(sequence: Match3Sequence) -> void:
	animation_started.emit(ConsumeSequenceAnimation)
	
	var pieces: Array[Match3Piece] = sequence.normal_pieces()
	
	if pieces.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for piece_ui: Match3Piece in pieces:
			tween.tween_property(piece_ui, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_OUT)
		
		await tween.finished
	
	animation_finished.emit(ConsumeSequenceAnimation)


func consume_sequences(sequences: Array[Match3SequenceConsumer.Match3SequenceConsumeResult]) -> void:
	animation_started.emit(ConsumeSequencesAnimation)
	
	if sequences.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for sequence: Match3SequenceConsumer.Match3SequenceConsumeResult in sequences:
			for combo: Match3SequenceConsumer.Match3SequenceConsumeCombo in sequence.combos:
				var pieces: Array[Match3Piece] = combo.sequence.normal_pieces()
				
				for piece_ui: Match3Piece in pieces:
					tween.tween_property(piece_ui, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_OUT)
		
		await tween.finished
	
	animation_finished.emit(ConsumeSequencesAnimation)


func fall_piece(movement: Match3FallMover.FallMovement) -> void:
	animation_started.emit(FallPieceAnimation)
	
	if is_instance_valid(movement.piece) and is_instance_valid(movement.to_cell):
		var tween: Tween = create_tween()
		
		tween.tween_property(movement.piece, "position", movement.to_cell.position, 0.2)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
			
		await tween.finished
	
	animation_finished.emit(FallPieceAnimation)
	

func fall_pieces(movements: Array[Match3FallMover.FallMovement]) -> void:
	animation_started.emit(FallPiecesAnimation)
	
	if movements.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for movement in movements:
			if is_instance_valid(movement.piece) and is_instance_valid(movement.to_cell):
				tween.tween_property(movement.piece, "position", movement.to_cell.position, 0.2)\
					.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
				
		await tween.finished
	
	animation_finished.emit(FallPiecesAnimation)
	
	
func spawn_piece(cell: Match3GridCell) -> void:
	animation_started.emit(SpawnPieceAnimation)
	
	if cell.has_piece():
		var tween: Tween = create_tween()
		var fall_distance = board.configuration.cell_size.y * board.configuration.grid_height
		
		cell.piece.hide()
		tween.tween_property(cell.piece, "visible", true, 0.1)
		tween.tween_property(cell.piece, "position", cell.position, 0.25)\
			.set_trans(Tween.TRANS_QUAD).from(Vector2(cell.position.x, cell.position.y - fall_distance))
		
		await tween.finished
	
	animation_finished.emit(SpawnPieceAnimation)
	

func spawn_pieces(cells: Array[Match3GridCell]) -> void:
	animation_started.emit(SpawnPiecesAnimation)
	
	if cells.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for cell: Match3GridCell in cells.filter(func(cell: Match3GridCell): return cell.has_piece()):
			var fall_distance = board.configuration.cell_size.y * board.configuration.grid_height
			
			cell.piece.hide()
			tween.tween_property(cell.piece, "visible", true, 0.1)
			tween.tween_property(cell.piece, "position", cell.position, 0.25)\
				.set_trans(Tween.TRANS_QUAD).from(Vector2(cell.position.x, cell.position.y - fall_distance))
			
		await tween.finished
	
	animation_finished.emit(SpawnPiecesAnimation)
	
	
func trigger_special_piece(piece: Match3Piece) -> void:
	animation_started.emit(TriggerSpecialPieceAnimation)
	
	match piece.id:
		&"special-blue-triangle":
			var tween: Tween = create_tween()
			tween.tween_property(piece, "scale", Vector2(piece.scale.x * 1.2, piece.scale.y * 1.5), 1.0)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
			
			await tween.finished
		&"special-blue-triangle-5":
			var tween: Tween = create_tween()
			tween.tween_property(piece, "rotation", TAU, 0.5).set_ease(Tween.EASE_IN)
			tween.set_loops(2)
			
			await tween.loop_finished
			
	animation_finished.emit(TriggerSpecialPieceAnimation)
	

func piece_drag_ended(piece: Match3Piece) -> void:
	animation_started.emit(PieceDragEndedAnimation)
	
	if is_instance_valid(piece):
		var tween: Tween = create_tween()
		tween.tween_property(piece, "position", piece.cell.position, 0.25)\
			.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT)
			
		await tween.finished
		
	animation_finished.emit(PieceDragEndedAnimation)
	
	
func shuffle(movements: Array[Match3Shuffler.ShuffleMovement]) -> void:
	animation_started.emit(ShufflePiecesAnimation)
	
	if movements.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for movement in movements:
			tween.tween_property(movement.from_cell.piece, "position", movement.to_cell.position, 0.4)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(movement.to_cell.piece, "position", movement.from_cell.position, 0.4)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		
		await tween.finished
		
	animation_finished.emit(ShufflePiecesAnimation)


func on_animation_started(animation_name: StringName) -> void:
	current_animation = animation_name


func on_animation_finished(animation_name: StringName) -> void:
	current_animation = &""
