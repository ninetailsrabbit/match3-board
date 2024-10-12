class_name SequenceConsumer extends Node

@onready var board = get_tree().get_first_node_in_group(Match3Preloader.BoardGroupName)

func _enter_tree() -> void:
	name = "SequenceConsumer"

#region Overridables

func consume_sequence(sequence: Sequence) -> void:
	var new_piece = detect_new_combined_piece(sequence)
	
	if new_piece is PieceUI:
		sequence.consume_cell(sequence.middle_cell())
		board.draw_piece_on_cell(sequence.middle_cell(), new_piece)
		await board.piece_animator.spawn_special_piece(sequence, new_piece)
		sequence.consume([sequence.middle_cell()])
	else:
		await board.piece_animator.consume_sequence(sequence)
		sequence.consume()
	

func consume_sequences(sequences: Array[Sequence]) -> void:
	for sequence: Sequence in sequences:
		await consume_sequence(sequence)
		

func detect_new_combined_piece(sequence: Sequence):
	if sequence.all_pieces_are_of_type(PieceDefinitionResource.PieceType.Normal):
		var piece: PieceUI = sequence.pieces().front()
		
		if sequence.is_horizontal_or_vertical_shape():
			match sequence.size():
				4:
					var new_piece_definition = piece.piece_definition.match_4_piece
					
					if new_piece_definition:
						var special_piece: PieceUI = board.generate_new_piece()
						special_piece.piece_definition = new_piece_definition
					
						return special_piece
				5:
					var new_piece_definition = piece.piece_definition.match_5_piece
					
					if new_piece_definition:
						var special_piece: PieceUI = board.generate_new_piece()
						special_piece.piece_definition = new_piece_definition
					
						return special_piece
					
		
	return null 
