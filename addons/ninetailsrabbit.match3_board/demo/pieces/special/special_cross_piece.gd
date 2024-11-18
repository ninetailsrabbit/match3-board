class_name SpecialCrossPiece extends PieceUI

@onready var animation_player: AnimationPlayer = $AnimationPlayer


var extra_sequence: Sequence


func _ready() -> void:
	super._ready()
	animation_player.play("idle")


func trigger_special_effect() -> void:
	if not triggered:
		triggered = true

		board.lock()

		var sequence: Sequence = Sequence.new(board.cross_cells_from(cell()), Sequence.Shapes.Cross)

		if extra_sequence:
			sequence = sequence.combine_with(extra_sequence)

		sequence.add_cell(cell())

		animation_player.play("explode")
		await animation_player.animation_finished

		board.sequence_consumer.add_action_to_queue(board.sequence_consumer.create_normal_sequence_action(sequence), true)
		board.sequence_consumer.new_elements_added_flag = board.sequence_consumer.sequence_actions_queue.size() + 1

		finished_piece_special_trigger.emit()


func combine_effect_with(other_piece: PieceUI):
	if other_piece.is_special():
		
		match other_piece.piece_definition.shape:
			piece_definition.shape:
				combined_with = other_piece
				extra_sequence = Sequence.new(board.cross_diagonal_cells_from(cell()), Sequence.Shapes.CrossDiagonal)
				extra_sequence.add_cell(other_piece.cell())
