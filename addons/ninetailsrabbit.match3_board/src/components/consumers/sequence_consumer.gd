class_name SequenceConsumer extends Node

signal consumed_sequence(sequence: Sequence)
signal consumed_sequences(sequences: Array[Sequence])


@onready var board: Match3Board = get_tree().get_first_node_in_group(Match3Board.BoardGroupName)

var special_pieces_queue: Array[PieceUI] = []


func _enter_tree() -> void:
	name = "SequenceConsumer"
	
	#consumed_sequences.connect(on_consumed_sequences)

#region Overridables
func consume_sequence(sequence: Sequence) -> void:
	if sequence.is_special_shape() and sequence.contains_special_piece():
		var special_pieces: Array[PieceUI] = sequence.get_special_pieces()
		
		if special_pieces.size() == 1:
			await consume_special_piece(sequence, sequence.get_special_piece())
			consumed_sequence.emit(sequence)
			
		else:
			special_pieces[0].combine_effect_with(special_pieces[1])
			await consume_special_piece(sequence, special_pieces[0])
			consumed_sequence.emit(sequence)
			
		return
		
	var new_piece_to_spawn = detect_new_combined_piece(sequence)
	
	if new_piece_to_spawn is PieceUI:
		var target_cell_to_spawn: GridCellUI = sequence.middle_cell()
		
		await board.piece_animator.consume_pieces(sequence.normal_pieces())
		sequence.consume_only_normal_pieces()

		board.draw_piece_on_cell(target_cell_to_spawn, new_piece_to_spawn)
		await board.piece_animator.spawn_special_piece(target_cell_to_spawn, new_piece_to_spawn)
	else:
		special_pieces_queue.append_array(sequence.get_special_pieces())
		
		await board.piece_animator.consume_pieces(sequence.normal_pieces())
		sequence.consume_only_normal_pieces()
	
	await get_tree().process_frame
	consumed_sequence.emit(sequence)


func consume_sequences(sequences: Array[Sequence], callback: Callable) -> void:
	for sequence: Sequence in sequences:
		await consume_sequence(sequence)
	
	while not special_pieces_queue.is_empty():
		print("special piece queue", special_pieces_queue.front())

		await consume_sequence(Sequence.create_from_piece(special_pieces_queue.pop_front()))
		
	consumed_sequences.emit()
	board.consumed_sequences.emit(sequences)
	callback.call()


func consume_special_piece(sequence: Sequence, special_piece: PieceUI) -> void:
	special_piece.requested_piece_special_trigger.emit()
	await special_piece.finished_piece_special_trigger
	
	sequence.consume_piece(special_piece)


func detect_new_combined_piece(sequence: Sequence):
	pass
#endregion
