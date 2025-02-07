class_name Match3Animator extends Node

#region Animation names
const SwapPiecesAnimation: StringName = &"swap-pieces"
const SwapRejectedPiecesAnimation: StringName = &"swap-pieces"
const ConsumeSequenceAnimation: StringName = &"consume-sequence"
#endregion

signal animation_started(animation_name: StringName)
signal animation_finished(animation_name: StringName)

var board: Match3BoardUI
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
	
	var pieces: Array[Match3PieceUI] = board.ui_pieces_from_sequence(sequence)
	
	if pieces.size() > 0:
		var tween: Tween = create_tween().set_parallel(true)
		
		for piece_ui: Match3PieceUI in pieces:
			tween.tween_property(piece_ui, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_OUT)
		
		await tween.finished
	
	animation_finished.emit(ConsumeSequenceAnimation)

	
func on_animation_started(animation_name: StringName) -> void:
	current_animation = animation_name


func on_animation_finished(animation_name: StringName) -> void:
	current_animation = &""
