class_name SequenceConsumer extends Node

signal consumed_sequence(sequence: Sequence)
signal consumed_sequences(sequences: Array[Sequence])


@onready var board: Match3Board = get_tree().get_first_node_in_group(Match3Board.BoardGroupName)


var sequences_to_consume: Array[Sequence] = []
var sequence_actions_queue: Array[SequenceAction] = []


func _enter_tree() -> void:
	name = "SequenceConsumer"
	
	consumed_sequence.connect(on_consumed_sequence)

func prepare_action_queue(sequences: Array[Sequence]) -> void:
	sequences_to_consume = sequences
	
	for sequence: Sequence in sequences:
		if sequence.is_special_shape() and sequence.contains_special_piece():
			if sequence.special_pieces_count() == 1:
				add_action_to_queue(create_special_sequence_action(sequence))
			else:
				add_action_to_queue(create_special_combined_sequence_action(sequence))
				
			return
			
		var new_piece_to_spawn = detect_new_combined_piece(sequence)
	
		if new_piece_to_spawn is PieceUI:
			add_action_to_queue(create_draw_piece_action(sequence, new_piece_to_spawn))
		else:
			add_action_to_queue(create_normal_sequence_action(sequence))
	
			
func consume_next_action() -> void:
	var next_action: SequenceAction = sequence_actions_queue.pop_front()
	
	if next_action == null:
		consumed_sequences.emit(sequences_to_consume)
		sequences_to_consume.clear()
	else:
		await next_action.run()
		consumed_sequence.emit(next_action.sequence)


func consume_sequences(sequences: Array[Sequence]) -> void:
	prepare_action_queue(sequences)
	consume_next_action()


func trigger_special_piece(sequence: Sequence, special_piece: PieceUI) -> void:
	if is_instance_valid(special_piece) and special_piece != null:
		await special_piece.trigger_special_effect()
		sequence.consume_piece(special_piece)
		

#region Overridables
func detect_new_combined_piece(sequence: Sequence):
	pass
#endregion


#region Actions
func add_action_to_queue(action: SequenceAction, front: bool = false) -> void:
	if front:
		sequence_actions_queue.push_front(action)
	else:
		sequence_actions_queue.push_back(action)

	
func create_normal_sequence_action(sequence: Sequence) -> ConsumeNormalSequenceAction:
	return ConsumeNormalSequenceAction.new(self, sequence) 


func create_special_sequence_action(sequence: Sequence) -> ConsumeSpecialPieceAction:
	return ConsumeSpecialPieceAction.new(self, sequence) 


func create_special_combined_sequence_action(sequence: Sequence) -> ConsumeSpecialPieceCombinedAction:
	return ConsumeSpecialPieceCombinedAction.new(self, sequence) 


func create_draw_piece_action(sequence: Sequence, new_piece: PieceUI) -> DrawNewPieceSequenceAction:
	return DrawNewPieceSequenceAction.new(self, sequence, {"new_piece": new_piece}) 


class SequenceAction extends RefCounted:
	var consumer: SequenceConsumer
	var sequence: Sequence
	var arguments: Dictionary = {}
	
	func _init(_consumer: SequenceConsumer, _sequence: Sequence, _arguments: Dictionary = {}) -> void:
		consumer = _consumer
		sequence = _sequence
		arguments = _arguments
		
	func run() -> void:
		pass
	
	
	func get_class_name() -> StringName:
		return &"SequenceAction"


class ConsumeNormalSequenceAction extends SequenceAction:
	func run() -> void:
		## The special pieces detected on this sequences will be appended to queue to be consumed after in the chain action
		for special_piece: PieceUI in sequence.get_special_pieces():
			consumer.add_action_to_queue(ConsumeSpecialPieceAction.new(consumer, Sequence.create_from_piece(special_piece)), true)
		
		await consumer.board.piece_animator.consume_pieces(sequence.normal_pieces())
		
		sequence.consume_only(sequence.normal_pieces_cells() + sequence.special_piece_cells(true))
	
	func get_class_name() -> StringName:
		return &"ConsumeNormalSequenceAction"


class DrawNewPieceSequenceAction extends SequenceAction:
	func run() -> void:
		if arguments.has("new_piece") and is_instance_valid(arguments.new_piece):
			arguments.new_piece.board = consumer.board
			
			var target_cell_to_spawn: GridCellUI = arguments.new_piece.custom_spawn_and_draw({"sequence": sequence})
			
			if target_cell_to_spawn == null:
				target_cell_to_spawn = sequence.middle_cell()
			
			await consumer.board.piece_animator.consume_pieces(sequence.normal_pieces())
			
			sequence.consume_only_normal_pieces()

			consumer.board.draw_piece_on_cell(target_cell_to_spawn, arguments.new_piece)
			await consumer.board.piece_animator.spawn_special_piece(target_cell_to_spawn, arguments.new_piece)
		

	func get_class_name() -> StringName:
		return &"DrawNewPieceSequenceAction"
		
		
class ConsumeSpecialPieceAction extends SequenceAction:
	func run() -> void:
		await consumer.trigger_special_piece(sequence, sequence.get_special_piece())
		
	func get_class_name() -> StringName:
		return &"ConsumeSpecialPieceAction"
		
		
class ConsumeSpecialPieceCombinedAction extends SequenceAction:
	func run() -> void:
		var special_pieces: Array[PieceUI] = sequence.get_special_pieces()
		
		special_pieces[0].combine_effect_with(special_pieces[1])
		await consumer.trigger_special_piece(sequence, special_pieces[0])


	func get_class_name() -> StringName:
		return &"ConsumeSpecialPieceCombinedAction"
#endregion

#region Signal callbacks
func on_consumed_sequence(_sequence: Sequence) -> void:
	consume_next_action()
#endregion
