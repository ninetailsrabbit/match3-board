class_name Match3BoardConfiguration extends Resource

const MinGridWidth: int = 3
const MinGridHeight: int = 3

#region Board movements
enum BoardMovements {
	## Piece can be moved on adjacent pieces (not diagonals)
	Adjacent,
	## Piece can be moved on adjacent pieces including diagonals
	AdjacentWithDiagonals,
	## Piece can be moved on diagonal adjacent pieces
	AdjacentDiagonals,
	## Piece can be freely move into any other piece in the board (not obstacles)
	Free,
	## Piece can be moved in the row it belongs
	Row,
	## Piece can be moved in the column it belongs
	Column,
	## Piece can be moved in the row & column it belongs
	Cross,
	## Piece can be moved in a diagonal cross move
	CrossDiagonal,
	## Piece can be moved connecting it with similar adjacent pieces
	ConnectLine
}

enum BoardSelectionMode {
	## The piece can be clicked or touch once to select & unselect
	Click,
	## Piece can be dragged keeping the input action and releasing it when not
	Drag
}

enum BoardFillModes {
	## Pieces fall down to fill the empty cells
	FallDown,
	## Pieces still fall down but the empty cell sides are taking into account
	Side,
	## Pieces appears in the same place they were removed
	InPlace
}

enum AnimationFlow {
	## Consume the sequences one by one
	Serial,
	## Consume the sequences in parallel
	Parallel
}

#endregion

## Piece scenes that contains or inherits the PieceUI script
@export var available_pieces: Array[Match3PieceConfiguration] = []
@export var available_special_pieces: Array[Match3PieceConfiguration] = []
@export var pieces_collision_layer: int = 8
@export_group("Size 🔲")
@export var grid_width: int = 7:
		set(value):
			if grid_width != value:
				grid_width = maxi(MinGridWidth, value)
				
@export var grid_height: int = 8:
		set(value):
			if grid_height != value:
				grid_height = maxi(MinGridHeight, value)
			
@export var cell_size: Vector2i = Vector2i(48, 48)
@export var cell_offset: Vector2i = Vector2i(25, 25)
@export var grid_cell_scene: PackedScene = preload("res://addons/ninetailsrabbit.match3_board/src/ui/match_3_grid_cell_ui.tscn")

@export_group("Modes")
## The swap mode to use on this board, each has its own particularities and can be changed at runtime.
@export var swap_mode: BoardMovements = BoardMovements.Adjacent
## The click mode defines if the swap is made by select & click or dragging the piece to the desired place
@export var selection_mode: BoardSelectionMode = BoardSelectionMode.Click
## The fill mode defines how the pieces are redrawed into the board.
@export var fill_mode: BoardFillModes = BoardFillModes.FallDown

@export_group("Start")
## Draws automatically the cells & pieces when the board is ready on the scene tree
@export var auto_start: bool = true
## The minimum amount of pieces to make a match valid
@export var min_match: int = 3:
	set(value):
		min_match = maxi(3, value)
## The maximum amount of pieces a match can have.
@export var max_match: int  = 5:
	set(value):
		max_match = maxi(min_match, value)
## Set to -1 for infinite moves in the board. This is only informative and only emits signals based on the movements used but does not block the board.
@export var available_moves_on_start: int = 25
## When enabled, the matches that could appear in the first board preparation will stay there and be consumed as sequences
@export var allow_matches_on_start: bool = false

@export_group("Sequences")
## Set the rules to spawn new special pieces in the board 
@export var sequence_rules: Array[SequenceConsumeRule] = []

## When enabled, horizontal matchs between pieces are allowed
@export var horizontal_shape: bool = true
## When enabled, vertical matchs between pieces are allowed
@export var vertical_shape: bool = true
## When enabled, TShape matchs between pieces are allowed
@export var tshape: bool = true
## When enabled, LShape  matchs between pieces are allowed
@export var lshape: bool = true
## The minimum amount of pieces to make a match valid

@export_group("Animations")
## Set the animation type when consuming sequences
@export var sequence_animation: AnimationFlow = AnimationFlow.Parallel
## Set the animation type when falling pieces
@export var fall_animation: AnimationFlow = AnimationFlow.Parallel
## Set the animation type when filling the board with new pieces
@export var fill_animation: AnimationFlow = AnimationFlow.Parallel

#region Information
func click_mode_is_selection() -> bool:
	return selection_mode == BoardSelectionMode.Click
	

func click_mode_is_drag() -> bool:
	return selection_mode == BoardSelectionMode.Drag
	

func fill_mode_is_fall_down() -> bool:
	return fill_mode == BoardFillModes.FallDown
	

func fill_mode_is_side() -> bool:
	return fill_mode == BoardFillModes.Side
	
	
func fill_mode_is_in_place() -> bool:
	return fill_mode == BoardFillModes.InPlace
	

func swap_mode_is_adjacent() -> bool:
	return swap_mode == BoardMovements.Adjacent
	
	
func swap_mode_is_adjacent_with_diagonals() -> bool:
	return swap_mode == BoardMovements.AdjacentWithDiagonals
	
	
func swap_mode_is_adjacent_only_diagonals() -> bool:
	return swap_mode == BoardMovements.AdjacentDiagonals
	

func swap_mode_is_free() -> bool:
	return swap_mode == BoardMovements.Free


func swap_mode_is_row() -> bool:
	return swap_mode == BoardMovements.Row


func swap_mode_is_column() -> bool:
	return swap_mode == BoardMovements.Column
	
	
func swap_mode_is_cross() -> bool:
	return swap_mode == BoardMovements.Cross
	
	
func swap_mode_is_cross_diagonal() -> bool:
	return swap_mode == BoardMovements.CrossDiagonal
	
	
func swap_mode_is_connect_line() -> bool:
	return swap_mode == BoardMovements.ConnectLine


func sequence_animation_is_serial() -> bool:
	return sequence_animation == AnimationFlow.Serial
	

func sequence_animation_is_parallel() -> bool:
	return sequence_animation == AnimationFlow.Parallel


func fall_animation_is_serial() -> bool:
	return fall_animation == AnimationFlow.Serial
	

func fall_animation_is_parallel() -> bool:
	return fall_animation == AnimationFlow.Parallel
	

func fill_animation_is_serial() -> bool:
	return fill_animation == AnimationFlow.Serial
	

func fill_animation_is_parallel() -> bool:
	return fill_animation == AnimationFlow.Parallel
#endregion
