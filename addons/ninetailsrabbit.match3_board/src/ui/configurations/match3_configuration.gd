class_name Match3BoardConfiguration extends Resource

const MinGridWidth: int = 3
const MinGridHeight: int = 3

## Piece scenes that contains or inherits the PieceUI script
@export var available_pieces: Array[Match3PieceConfiguration] = []
@export_group("Size 🔲")
@export var grid_width: int = 8:
		set(value):
			if grid_width != value:
				grid_width = maxi(MinGridWidth, value)
				
@export var grid_height: int = 7:
		set(value):
			if grid_height != value:
				grid_height = maxi(MinGridHeight, value)
			
@export var cell_size: Vector2i = Vector2i(48, 48)
@export var cell_offset: Vector2i = Vector2i(25, 25)



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

#endregion

@export_group("Modes")
## The swap mode to use on this board, each has its own particularities and can be changed at runtime.
@export var swap_mode: BoardMovements = BoardMovements.Adjacent
## The click mode defines if the swap is made by select & click or dragging the piece to the desired place
@export var click_mode: BoardSelectionMode = BoardSelectionMode.Click
## The fill mode defines how the pieces are redrawed into the board.
@export var fill_mode = BoardFillModes.FallDown

@export_group("Start")
@export var auto_start: bool = true
## The minimum amount of pieces to make a match valid
@export var min_match: int = 3:
	set(value):
		min_match = max(3, value)
## The maximum amount of pieces a match can have.
@export var max_match: int  = 5:
	set(value):
		max_match = max(min_match, value)
## This is only informative and only emits signals based on the movements used but does not block the board.
@export var available_moves_on_start: int = 25
## When enabled, the matches that could appear in the first board preparation will stay there and be consumed as sequences
@export var allow_matches_on_start: bool = false

@export_group("Sequences")
## When enabled, horizontal matchs between pieces are allowed
@export var horizontal_shape: bool = true
## When enabled, vertical matchs between pieces are allowed
@export var vertical_shape: bool = true
## When enabled, TShape matchs between pieces are allowed
@export var tshape: bool = true
## When enabled, LShape  matchs between pieces are allowed
@export var lshape: bool = true
## The minimum amount of pieces to make a match valid



#region Information
func click_mode_is_selection() -> bool:
	return click_mode == BoardSelectionMode.Click
	

func click_mode_is_drag() -> bool:
	return click_mode == BoardSelectionMode.Drag
	

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

#endregion
