class_name SequenceConsumer extends Node

signal consumed_sequence(sequence: Sequence)
signal consumed_sequences(sequences: Array[Sequence])


@onready var board: Match3Board = get_tree().get_first_node_in_group(Match3Board.BoardGroupName)


var sequences_to_consume: Array[Sequence] = []
var pending_sequences: Array[Sequence] = []
var pending_pieces: Array[PieceUI] = []


func _enter_tree() -> void:
	name = "SequenceConsumer"
	
	consumed_sequence.connect(on_consumed_sequence)


func consume_sequences(sequences: Array[Sequence]) -> void:
	sequences_to_consume = sequences
	pending_sequences = sequences
	consume_next_sequence()


func consume_next_sequence() -> void:
	var next_sequence: Sequence = pending_sequences.pop_front()
	
	if next_sequence == null:
		consumed_sequences.emit(sequences_to_consume)
		sequences_to_consume.clear()
	else:
		consume_sequence(next_sequence)


func consume_sequence(sequence: Sequence) -> void:
	await preprocess_sequence(sequence)
	pending_pieces = sequence.pieces()
	while pending_pieces.size() > 0:
		var piece = pending_pieces.pop_front()
		if is_instance_valid(piece) and piece != null:
			await piece.consume(sequence)
	await sequence.after_consumed.call()
	consumed_sequence.emit(sequence)


func add_pieces_to_queue(pieces: Array, front := false) -> void:
	if front:
		for piece in pieces:
			pending_pieces.push_front(piece)
	else:
		pending_pieces.append_array(pieces)


# func add_sequence_to_queue(sequence: Sequence, front := false) -> void:
# 	if front:
# 		pending_sequences.push_front(sequence)
# 	else:
# 		pending_sequences.push_back(sequence)

#region Overridables
func preprocess_sequence(sequence: Sequence) -> void:
	pass
#endregion


#region Signal callbacks
func on_consumed_sequence(sequence: Sequence) -> void:
	consume_next_sequence()
#endregion
