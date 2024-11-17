class_name SequenceConsumer extends Node

signal consumed_sequence(sequence: Sequence)
signal consumed_sequences(sequences: Array[Sequence])


@onready var board: Match3Board = get_tree().get_first_node_in_group(Match3Board.BoardGroupName)

func _enter_tree() -> void:
	name = "SequenceConsumer"

#region Overridables
func consume_sequence(sequence: Sequence) -> void:
	consumed_sequence.emit(sequence)
	
	if sequence.is_special_shape() and sequence.contains_special_piece():
		var special_pieces: Array[PieceUI] = sequence.get_special_pieces()
			
		if special_pieces.size() == 1:
			var special_piece = sequence.get_special_piece()
			special_piece.requested_piece_special_trigger.emit()
			await special_piece.finished_piece_special_trigger
			
		else:
			special_pieces[0].combine_effect_with(special_pieces[1])
			special_pieces[0].requested_piece_special_trigger.emit()
			special_pieces[1].requested_piece_special_trigger.emit()
			
			await special_pieces[0].finished_piece_special_trigger
			await special_pieces[1].finished_piece_special_trigger
			
		return
		
	var new_piece_to_spawn = detect_new_combined_piece(sequence)
	
	if new_piece_to_spawn is PieceUI:
		var target_cell_to_spawn: GridCellUI = sequence.middle_cell()
		
		await board.piece_animator.consume_sequence(sequence)
		sequence.consume()
		
		board.draw_piece_on_cell(target_cell_to_spawn, new_piece_to_spawn)
		await board.piece_animator.spawn_special_piece(target_cell_to_spawn, new_piece_to_spawn)
	else:
		#for special_piece: PieceUI in sequence.get_special_pieces():
			#sequence.remove_cell(special_piece.cell())
			#
		await board.piece_animator.consume_sequence(sequence)
		sequence.consume()
		
		for special_piece: PieceUI in sequence.get_special_pieces():
			special_piece.requested_piece_special_trigger.emit()
			await special_piece.finished_piece_special_trigger
			

func consume_sequences(sequences: Array[Sequence], callback: Callable) -> void:
	for sequence: Sequence in sequences:
		await consume_sequence(sequence)
		
	consumed_sequences.emit(sequences)
	callback.call()
	
	
func detect_new_combined_piece(sequence: Sequence):
	pass
#endregion
