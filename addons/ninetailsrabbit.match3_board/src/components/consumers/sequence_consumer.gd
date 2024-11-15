class_name SequenceConsumer extends Node

signal consumed_sequence(sequence: Sequence)

@onready var board: Match3Board = get_tree().get_first_node_in_group(Match3Preloader.BoardGroupName)

func _enter_tree() -> void:
	name = "SequenceConsumer"

#region Overridables
func consume_sequence(sequence: Sequence) -> void:
	consumed_sequence.emit(sequence)
	
	await board.piece_animator.consume_sequence(sequence)
	sequence.consume()
	

func consume_sequences(sequences: Array[Sequence]) -> void:
	for sequence: Sequence in sequences:
		await consume_sequence(sequence)
#endregion
