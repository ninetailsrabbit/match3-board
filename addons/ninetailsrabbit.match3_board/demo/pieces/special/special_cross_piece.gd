class_name SpecialCrossPiece extends PieceUI

@onready var animation_player: AnimationPlayer = $AnimationPlayer


var extra_sequence: Sequence
var is_diagonal: bool = false


func _ready() -> void:
	super._ready()
	animation_player.play("idle")


func on_swap_with(other_piece: PieceUI) -> Sequence:
	if other_piece is SpecialCrossPiece and is_diagonal == false and other_piece.is_diagonal == false:
		is_diagonal = true
		return Sequence.new([cell(), other_piece.cell()])
	return Sequence.new([cell()])


func consume(sequence: Sequence) -> bool:
	if not triggered:
		triggered = true
		board.lock()

		animation_player.play("explode")
		await animation_player.animation_finished
		var cells: Array[GridCellUI] = board.cross_cells_from(cell())

		if is_diagonal:
			cells = board.cross_diagonal_cells_from(cell())

		cells.erase(cell())
		board.sequence_consumer.add_pieces_to_queue(cells.map(func(cell: GridCellUI) -> PieceUI: return cell.current_piece), true)
	return super.consume(sequence)
