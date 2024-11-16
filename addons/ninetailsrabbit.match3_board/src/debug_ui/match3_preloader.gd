class_name Match3Preloader

#region Shared

class FallMovement:
	var from_cell: GridCellUI
	var to_cell: GridCellUI
	var is_diagonal: bool = false
	
	func _init(_from_cell: GridCellUI, _to_cell: GridCellUI, _is_diagonal: bool = false) -> void:
		from_cell = _from_cell
		to_cell = _to_cell
		is_diagonal = _is_diagonal


#endregion


#region Cell textures
const EvenCellTexture: CompressedTexture2D = preload("res://addons/ninetailsrabbit.match3_board/src/debug_ui/preview_cells/even.png")
const HighlightedTexture: CompressedTexture2D = preload("res://addons/ninetailsrabbit.match3_board/src/debug_ui/preview_cells/highlighted.png")
const OddCellTexture: CompressedTexture2D = preload("res://addons/ninetailsrabbit.match3_board/src/debug_ui/preview_cells/odd.png")
#endregion
