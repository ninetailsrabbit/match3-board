class_name CellHighlighter extends Node

const GroupName: String = "cell-highlighter"

@export var highlight_texture: Texture2D = Match3Preloader.HighlightedTexture

@onready var board: Match3Board = get_tree().get_first_node_in_group(Match3Board.BoardGroupName)

func _enter_tree() -> void:
	name = "CellHighlighter"


func highlight_cell(grid_cell: GridCellUI) -> void:
	grid_cell.change_background_image(highlight_texture)


func highlight_cells(grid_cells: Array[GridCellUI]) -> void:
	for cell: GridCellUI in grid_cells:
		highlight_cell(cell)


func remove_highlight(grid_cell: GridCellUI) -> void:
	grid_cell.change_to_original_background_image()
	

func highlight_cells_from_origin_cell(origin_cell: GridCellUI, swap_mode: Match3Configuration.BoardMovements = board.configuration.swap_mode) -> void:
	match swap_mode:
		Match3Configuration.BoardMovements.Adjacent:
			highlight_cells(origin_cell.available_neighbours(false))
		Match3Configuration.BoardMovements.AdjacentWithDiagonals:
			highlight_cells(origin_cell.available_neighbours(true))
		Match3Configuration.BoardMovements.AdjacentOnlyDiagonals:
			highlight_cells(origin_cell.diagonal_neighbours())
		Match3Configuration.BoardMovements.Free:
			highlight_cell(origin_cell)
		Match3Configuration.BoardMovements.Row:
			highlight_cells(board.grid_cells_from_row(origin_cell.row))
		Match3Configuration.BoardMovements.Column:
			highlight_cells(board.grid_cells_from_column(origin_cell.column))
		Match3Configuration.BoardMovements.Cross:
			highlight_cells(board.cross_cells_from(origin_cell))
		Match3Configuration.BoardMovements.CrossDiagonal:
			highlight_cells(board.cross_diagonal_cells_from(origin_cell))
				

func remove_current_highlighters() -> void:
	for grid_cell: GridCellUI in board.grid_cells_flattened:
		remove_highlight(grid_cell)
