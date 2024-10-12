class_name CellHighlighter extends Node

@export var highlight_texture: Texture2D = Match3Preloader.HighlightedTexture

@onready var board = get_tree().get_first_node_in_group(Match3Preloader.BoardGroupName)

func _enter_tree() -> void:
	name = "CellHighlighter"


func highlight_cell(grid_cell: GridCellUI) -> void:
	grid_cell.change_background_image(highlight_texture)
	
	
func highlight_cells(origin_cell: GridCellUI, swap_mode = board.swap_mode) -> void:
	match swap_mode:
		Match3Preloader.BoardMovements.Adjacent:
			for grid_cell: GridCellUI in origin_cell.available_neighbours(false):
				highlight_cell(grid_cell)
		Match3Preloader.BoardMovements.Cross:
			for grid_cell: GridCellUI in board.cross_cells_from(origin_cell):
				highlight_cell(grid_cell)
		Match3Preloader.BoardMovements.Free:
			highlight_cell(origin_cell)
		Match3Preloader.BoardMovements.CrossDiagonal:
			for grid_cell: GridCellUI in board.cross_diagonal_cells_from(origin_cell):
				highlight_cell(grid_cell)
	
	
func remove_current_highlighters() -> void:
	for grid_cell: GridCellUI in board.grid_cells_flattened:
		grid_cell.change_to_original_background_image()
