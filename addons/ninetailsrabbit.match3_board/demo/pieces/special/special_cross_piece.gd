class_name SpecialCrossPiece extends PieceUI

@onready var animation_player: AnimationPlayer = $AnimationPlayer


var extra_sequence: Sequence


func _ready() -> void:
	super._ready()
	animation_player.play("idle")


func on_swap_with(other_piece: PieceUI) -> Sequence:
	return Sequence.new([cell()])


func consume(sequence: Sequence) -> bool:
	if not triggered:
		triggered = true
		board.lock()

		animation_player.play("explode")
		await animation_player.animation_finished
		var cells: Array[GridCellUI] = board.cross_cells_from(cell())
		cells.erase(cell())
		board.sequence_consumer.add_sequence_to_queue(Sequence.new(cells), true)	
	return super.consume(sequence)

