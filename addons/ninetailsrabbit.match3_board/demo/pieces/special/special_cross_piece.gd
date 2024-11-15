class_name SpecialCrossPiece extends PieceUI


@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	super._ready()
	animation_player.play("idle")


func on_requested_piece_special_trigger() -> void:
	var sequence: Sequence = Sequence.new(board.cross_cells_from(board.grid_cell_from_piece(self)), Sequence.Shapes.Cross)
	board.lock()
	
	animation_player.play("explode")
	await animation_player.animation_finished
	board.unlock()
	
	board.consume_requested.emit(sequence)
