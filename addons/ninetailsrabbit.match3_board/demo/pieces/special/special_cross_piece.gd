class_name SpecialCrossPiece extends PieceUI

@onready var animation_player: AnimationPlayer = $AnimationPlayer


var extra_sequence: Sequence


func _ready() -> void:
	super._ready()
	animation_player.play("idle")


func on_requested_piece_special_trigger() -> void:
	if not triggered:
		triggered = true
		
		board.lock()
		
		var sequence: Sequence = Sequence.new(board.cross_cells_from(cell()), Sequence.Shapes.Cross)
		
		if extra_sequence:
			sequence = sequence.combine_with(extra_sequence)
		
		sequence.add_cell(cell())
		
		animation_player.play("explode")
		await animation_player.animation_finished
		
		finished_piece_special_trigger.emit()
		
		board.consume_requested.emit(sequence)


func combine_effect_with(other_piece: PieceUI):
	if other_piece.is_special():
		
		match other_piece.piece_definition.shape:
			piece_definition.shape:
				combined_with = other_piece
				extra_sequence = Sequence.new(board.cross_diagonal_cells_from(cell()), Sequence.Shapes.CrossDiagonal)
				extra_sequence.add_cell(other_piece.cell())
