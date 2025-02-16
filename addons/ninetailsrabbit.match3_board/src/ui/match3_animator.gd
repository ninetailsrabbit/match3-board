class_name Match3Animator extends Node


#region Animation names
const DrawPiecesAnimation: StringName = &"draw-pieces"
const DrawCellsAnimation: StringName = &"draw-cells"
const SwapPiecesAnimation: StringName = &"swap-pieces"
const SwapRejectedPiecesAnimation: StringName = &"swap-pieces"
const ConsumeSequenceAnimation: StringName = &"consume-sequence"
const ConsumeSequencesAnimation: StringName = &"consume-sequences"
const FallPieceAnimation: StringName = &"fall-piece"
const FallPiecesAnimation: StringName = &"fall-pieces"
const SpawnPieceAnimation: StringName = &"spawn-piece"
const SpawnPiecesAnimation: StringName = &"spawn-pieces"
const TriggerSpecialPieceAnimation: StringName = &"trigger-special-piece"
const PieceDragEndedAnimation: StringName = &"piece-drag-ended"
#endregion

signal animation_started(animation_name: StringName)
signal animation_finished(animation_name: StringName)

@export var board: Match3Board

var current_animation: StringName = &""


func _ready() -> void:
	if board == null:
		board = get_tree().get_first_node_in_group(Match3Board.GroupName)
	
	assert(board != null, "Match3Animator: This animator needs a Match3Board assigned")
	
	animation_started.connect(on_animation_started)
	animation_finished.connect(on_animation_finished)


func draw_pieces(pieces: Array[Match3Piece]) -> void:
	animation_started.emit(DrawPiecesAnimation)
	animation_finished.emit(DrawPiecesAnimation)


func draw_cells(cells: Array[Match3GridCell]) -> void:
	animation_started.emit(DrawCellsAnimation)
	animation_finished.emit(DrawCellsAnimation)


func swap_pieces(from_piece: Match3Piece, to_piece: Match3Piece, from_piece_position: Vector2, to_piece_position: Vector2):
	animation_started.emit(SwapPiecesAnimation)
	animation_finished.emit(SwapPiecesAnimation)
	
	
func swap_rejected_pieces(from_piece: Match3Piece, to_piece: Match3Piece, from_piece_position: Vector2, to_piece_position: Vector2):
	animation_started.emit(SwapRejectedPiecesAnimation)
	animation_finished.emit(SwapRejectedPiecesAnimation)
	
	
func consume_sequence(sequence: Match3Sequence) -> void:
	animation_started.emit(ConsumeSequenceAnimation)	
	animation_finished.emit(ConsumeSequenceAnimation)


func consume_sequences(sequences: Array[Match3SequenceConsumer.Match3SequenceConsumeResult]) -> void:
	animation_started.emit(ConsumeSequencesAnimation)
	animation_finished.emit(ConsumeSequencesAnimation)


func fall_piece(movement: Match3FallMover.FallMovement) -> void:
	animation_started.emit(FallPieceAnimation)
	animation_finished.emit(FallPieceAnimation)
	

func fall_pieces(movements: Array[Match3FallMover.FallMovement]) -> void:
	animation_started.emit(FallPiecesAnimation)
	animation_finished.emit(FallPiecesAnimation)
	
	
func spawn_piece(cell: Match3GridCell) -> void:
	animation_started.emit(SpawnPieceAnimation)
	animation_finished.emit(SpawnPieceAnimation)
	

func spawn_pieces(cells: Array[Match3GridCell]) -> void:
	animation_started.emit(SpawnPiecesAnimation)
	animation_finished.emit(SpawnPiecesAnimation)
	
	
func trigger_special_piece(piece: Match3Piece) -> void:
	animation_started.emit(TriggerSpecialPieceAnimation)
	animation_finished.emit(TriggerSpecialPieceAnimation)


func piece_drag_ended(piece: Match3Piece) -> void:
	animation_started.emit(PieceDragEndedAnimation)
	animation_finished.emit(PieceDragEndedAnimation)


func on_animation_started(animation_name: StringName) -> void:
	current_animation = animation_name


func on_animation_finished(animation_name: StringName) -> void:
	current_animation = &""
