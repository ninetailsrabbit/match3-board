class_name Match3Animator extends Node

## TODO - LEAVE THIS CLASS TO OVERRIDE THE METHODS

#region Animation names
const SwapPiecesAnimation: StringName = &"swap-pieces"
const SwapRejectedPiecesAnimation: StringName = &"swap-pieces"
const ConsumeSequenceAnimation: StringName = &"consume-sequence"
const ConsumeSequencesAnimation: StringName = &"consume-sequences"
const FallPieceAnimation: StringName = &"fall-piece"
const FallPiecesAnimation: StringName = &"fall-pieces"
const SpawnPieceAnimation: StringName = &"spawn-piece"
const SpawnPiecesAnimation: StringName = &"spawn-pieces"
#endregion

signal animation_started(animation_name: StringName)
signal animation_finished(animation_name: StringName)

@export var board: Match3BoardUI

var current_animation: StringName = &""


func _ready() -> void:
	if board == null:
		board = get_tree().get_first_node_in_group(Match3BoardUI.GroupName)
	
	assert(board != null, "Match3Animator: This animator needs a Match3BoardUI assigned")
	
	animation_started.connect(on_animation_started)
	animation_finished.connect(on_animation_finished)


func swap_pieces(from_piece: Match3PieceUI, to_piece: Match3PieceUI, from_piece_position: Vector2, to_piece_position: Vector2):
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
	
	
func swap_rejected_pieces(from_piece: Match3PieceUI, to_piece: Match3PieceUI, from_piece_position: Vector2, to_piece_position: Vector2):
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
	
	var pieces: Array[Match3PieceUI] = sequence.pieces
	
	if pieces.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for piece_ui: Match3PieceUI in pieces:
			tween.tween_property(piece_ui, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_OUT)
		
		await tween.finished
	
	animation_finished.emit(ConsumeSequenceAnimation)


func consume_sequences(sequences: Array[Match3SequenceConsumer.Match3SequenceConsumeResult]) -> void:
	animation_started.emit(ConsumeSequencesAnimation)
	
	if sequences.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for sequence: Match3SequenceConsumer.Match3SequenceConsumeResult in sequences:
			for combo: Match3SequenceConsumer.Match3SequenceConsumeCombo in sequence.combos:
				var pieces: Array[Match3PieceUI] = combo.sequence.pieces
				
				for piece_ui: Match3PieceUI in pieces:
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
	
	
func spawn_piece(cell: Match3GridCellUI) -> void:
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
	

func spawn_pieces(cells: Array[Match3GridCellUI]) -> void:
	animation_started.emit(SpawnPiecesAnimation)
	
	if cells.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for cell: Match3GridCellUI in cells.filter(func(cell: Match3GridCellUI): return cell.has_piece()):
			var fall_distance = board.configuration.cell_size.y * board.configuration.grid_height
			
			cell.piece.hide()
			tween.tween_property(cell.piece, "visible", true, 0.1)
			tween.tween_property(cell.piece, "position", cell.position, 0.25)\
				.set_trans(Tween.TRANS_QUAD).from(Vector2(cell.position.x, cell.position.y - fall_distance))
			
		await tween.finished
	
	animation_finished.emit(SpawnPiecesAnimation)
	
	
func on_animation_started(animation_name: StringName) -> void:
	current_animation = animation_name


func on_animation_finished(animation_name: StringName) -> void:
	current_animation = &""
