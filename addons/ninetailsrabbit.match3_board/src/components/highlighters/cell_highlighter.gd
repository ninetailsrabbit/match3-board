class_name CellHighlighter extends Node

@export var highlight_texture: Texture2D = Match3Preloader.HighlightedTexture

@onready var board = get_tree().get_first_node_in_group(Match3Preloader.BoardGroupName)

func _enter_tree() -> void:
	name = "CellHighlighter"


func highlight_cell(grid_cell: GridCellUI) -> void:
	grid_cell.change_background_image(highlight_texture)


func highlight_cells(grid_cells: Array[GridCellUI]) -> void:
	for cell: GridCellUI in grid_cells:
		highlight_cell(cell)


func remove_highlight(grid_cell: GridCellUI) -> void:
	grid_cell.change_to_original_background_image()
	

func highlight_cells_from_origin_cell(origin_cell: GridCellUI, swap_mode: Match3Preloader.BoardMovements = board.swap_mode) -> void:
	match swap_mode:
		Match3Preloader.BoardMovements.Adjacent:
			highlight_cells(origin_cell.available_neighbours(false))
		Match3Preloader.BoardMovements.Cross:
			highlight_cells(board.cross_cells_from(origin_cell))
		Match3Preloader.BoardMovements.Free:
			highlight_cell(origin_cell)
		Match3Preloader.BoardMovements.CrossDiagonal:
			highlight_cells(board.cross_diagonal_cells_from(origin_cell))
	
	
func remove_current_highlighters() -> void:
	for grid_cell: GridCellUI in board.grid_cells_flattened:
		remove_highlight(grid_cell)
