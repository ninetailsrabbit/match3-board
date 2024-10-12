class_name Match3Preloader

#region Shared
const BoardGroupName: String = "match3-board"

class FallMovement:
	var from_cell: GridCellUI
	var to_cell: GridCellUI
	var is_diagonal: bool = false
	
	func _init(_from_cell: GridCellUI, _to_cell: GridCellUI, _is_diagonal: bool = false) -> void:
		from_cell = _from_cell
		to_cell = _to_cell
		is_diagonal = _is_diagonal


enum BoardState {
	WaitForInput,
	Fill,
	Consume
}

enum BoardMovements {
	Adjacent,
	Free,
	Cross,
	CrossDiagonal,
	ConnectLine
}

enum BoardFillModes {
	FallDown,
	Side,
	InPlace
}
#endregion	

#region Textures
const BlueGem = preload("res://addons/ninetailsrabbit.match3_board/src/debug_ui/preview_pieces/blue_gem.png")
const GreenGem = preload("res://addons/ninetailsrabbit.match3_board/src/debug_ui/preview_pieces/green_gem.png")
const PurpleGem = preload("res://addons/ninetailsrabbit.match3_board/src/debug_ui/preview_pieces/purple_gem.png")
const YellowGem = preload("res://addons/ninetailsrabbit.match3_board/src/debug_ui/preview_pieces/yellow_gem.png")
#endregion

#region Cell textures
const EvenCellTexture = preload("res://addons/ninetailsrabbit.match3_board/src/debug_ui/preview_cells/even.png")
const HighlightedTexture = preload("res://addons/ninetailsrabbit.match3_board/src/debug_ui/preview_cells/highlighted.png")
const OddCellTexture = preload("res://addons/ninetailsrabbit.match3_board/src/debug_ui/preview_cells/odd.png")
#endregion
#region Pieces
const CrossPieceScene = preload("res://addons/ninetailsrabbit.match3_board/src/components/pieces/swap_mode/cross_piece.tscn")
const LineConnectorPieceScene = preload("res://addons/ninetailsrabbit.match3_board/src/components/pieces/swap_mode/line_connector_piece.tscn")
const SwapPieceScene = preload("res://addons/ninetailsrabbit.match3_board/src/components/pieces/swap_mode/swap_piece.tscn")
#endregion
