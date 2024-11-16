class_name SpecialCrossPiece extends PieceUI


@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	super._ready()
	animation_player.play("idle")


func on_requested_piece_special_trigger() -> void:
	var sequence: Sequence = Sequence.new(board.cross_cells_from(board.grid_cell_from_piece(self)), Sequence.Shapes.Cross)
	sequence.add_cell(board.grid_cell_from_piece(self))
	board.lock()
	
	animation_player.play("explode")
	await animation_player.animation_finished
	
	finished_piece_special_trigger.emit()
	
	board.consume_requested.emit(sequence)
	board.unlock()
