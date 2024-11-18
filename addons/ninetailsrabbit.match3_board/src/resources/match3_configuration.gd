class_name Match3Configuration extends Resource

signal changed_swap_mode(from: BoardMovements, to: BoardMovements)
signal changed_click_mode(from: BoardClickMode, to: BoardClickMode)

const MinGridWidth: int = 3
const MinGridHeight: int = 3

enum BoardMovements {
	Adjacent,
	AdjacentWithDiagonals,
	AdjacentOnlyDiagonals,
	Free,
	Row,
	Column,
	Cross,
	CrossDiagonal,
	ConnectLine
}

enum BoardClickMode {
	Selection,
	Drag
}

enum BoardFillModes {
	FallDown,
	Side,
	InPlace
}


## When enabled, the board prepare itself automatically when it's ready on the scene tree
@export var auto_start: bool = true
## The layer value from 1 to 32 that is the amount Godot supports. The inside areas will have this layer value to detect other pieces or be detected.
@export_range(1, 32, 1) var pieces_collision_layer: int = 8
## The swap mode to use on this board, each has its own particularities and can be changed at runtime.
@export var swap_mode:BoardMovements =BoardMovements.Adjacent:
	set(value):
		if value != swap_mode:
			changed_swap_mode.emit(swap_mode, value)
			swap_mode = value
## The click mode defines if the swap is made by select & click or dragging the piece to the desired place
@export var click_mode:BoardClickMode = BoardClickMode.Selection:
	set(value):
		if value != click_mode:
			changed_click_mode.emit(click_mode, value)
			click_mode = value
## The fill mode defines the behaviour when the pieces fall down after a consumed sequence.
@export var input_action_cancel_line_connector: StringName = &"cancel_line_connector"
@export var input_action_consume_line_connector: StringName = &"consume_line_connector"
@export var fill_mode = BoardFillModes.FallDown
## The available pieces this board can generate to be used by the player
@export var available_pieces: Array[PieceWeight] = []
## The available moves when the board is prepared. 
## This is only informative and only emits signals based on the movements used but does not block the board.
@export var available_moves_on_start: int = 25
## When enabled, the matches that could appear in the first board preparation will stay there and be consumed as sequences
@export var allow_matches_on_start: bool = false
## When enabled, the pieces after a failed swap are returned to their original positions before the swap
@export var reset_position_on_swap_failed: bool = true
## When enabled, horizontal matchs between pieces are allowed
@export var horizontal_shape: bool = true
## When enabled, vertical matchs between pieces are allowed
@export var vertical_shape: bool = true
## When enabled, TShape matchs between pieces are allowed
@export var tshape: bool = true
## When enabled, LShape  matchs between pieces are allowed
@export var lshape: bool = true
## The minimum amount of pieces to make a match valid
@export var min_match: int = 3:
	set(value):
		min_match = max(3, value)
## The maximum amount of pieces a match can have.
@export var max_match: int  = 5:
	set(value):
		max_match = max(min_match, value)


func not_disabled_pieces() -> Array[PieceWeight]:
	return available_pieces.filter(func(piece_weight: PieceWeight): return piece_weight.is_disabled)

	
func is_click_mode_selection() -> bool:
	return click_mode == BoardClickMode.Selection
	

func is_click_mode_drag() -> bool:
	return click_mode == BoardClickMode.Drag
	

func is_swap_mode_adjacent() -> bool:
	return swap_mode == BoardMovements.Adjacent
	
	
func is_swap_mode_adjacent_with_diagonals() -> bool:
	return swap_mode == BoardMovements.AdjacentWithDiagonals
	
	
func is_swap_mode_adjacent_only_diagonals() -> bool:
	return swap_mode == BoardMovements.AdjacentOnlyDiagonals
	

func is_swap_mode_free() -> bool:
	return swap_mode == BoardMovements.Free


func is_swap_mode_cross() -> bool:
	return swap_mode == BoardMovements.Cross
	
	
func is_swap_mode_cross_diagonal() -> bool:
	return swap_mode == BoardMovements.CrossDiagonal
	
	
func is_swap_mode_connect_line() -> bool:
	return swap_mode == BoardMovements.ConnectLine
