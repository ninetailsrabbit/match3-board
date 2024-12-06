class_name GridCellUI extends Node2D

signal swapped_piece(from: GridCellUI, to: GridCellUI)
signal swap_rejected(from: GridCellUI, to: GridCellUI)
signal removed_piece(piece: PieceUI)

const GroupName: String = "grid_cells"

@export var column: int
@export var row: int
@export var can_contain_piece: bool = true
@export var cell_size: Vector2 = Vector2(48, 48)
## Texture default path is temporary
@export var draw_background_texture: bool = true
@export var odd_cell_texture: Texture2D = Match3Preloader.OddCellTexture
@export var even_cell_texture: Texture2D = Match3Preloader.EvenCellTexture
@export var empty_cell_texture: Texture2D

#region Neighbours
var neighbour_up: GridCellUI
var neighbour_bottom: GridCellUI
var neighbour_right: GridCellUI
var neighbour_left: GridCellUI
var diagonal_neighbour_top_right: GridCellUI
var diagonal_neighbour_top_left: GridCellUI
var diagonal_neighbour_bottom_right: GridCellUI
var diagonal_neighbour_bottom_left: GridCellUI
#endregion

var selected_background_image: Texture2D
var background_sprite: Sprite2D
var current_piece: PieceUI:
	set(value):
		if value != current_piece:
			if value == null and is_inside_tree():
				removed_piece.emit(current_piece)
				
			current_piece = value
			

func _init(_row: int, _column: int, piece: PieceUI = null, _can_contain_piece: bool = true) -> void:
	assert(row >= 0 and column >= 0, "GridCellUI: A grid cell cannot have a negative column %d or row %d" % [column, row])
	
	row = _row
	column = _column
	current_piece = piece
	can_contain_piece = _can_contain_piece


func _enter_tree() -> void:
	add_to_group(GroupName)
	
	name = "Cell_Column%d_Row%d" % [column, row]
	z_index = 20
	
	prepare_background_sprite()


func change_to_original_background_image() -> void:
	background_sprite.texture = selected_background_image
	
	
func change_background_image(new_image: Texture2D) -> void:
	background_sprite.texture = new_image
	
	
func prepare_background_sprite() -> void:
	if can_contain_piece:
		selected_background_image = even_cell_texture if (column + row) % 2 == 0 else odd_cell_texture
	else:
		selected_background_image = empty_cell_texture
		
	if background_sprite == null:
		background_sprite = Sprite2D.new()
		background_sprite.name = "BackgroundSprite"
		background_sprite.texture = selected_background_image
		background_sprite.z_index = -10
		add_child(background_sprite)
	
	if background_sprite.texture and draw_background_texture:
		var texture_size = background_sprite.texture.get_size()
		background_sprite.scale = Vector2(cell_size.x / texture_size.x, cell_size.y / texture_size.y)
	

#region Position
func board_position() -> Vector2:
	return Vector2(row, column)


func in_same_row_as(other_cell: GridCellUI) -> bool:
	return row == other_cell.row


func in_same_column_as(other_cell: GridCellUI) -> bool:
	return column == other_cell.column


func in_same_position_as(other_cell: GridCellUI) -> bool:
	return in_same_column_as(other_cell) and in_same_row_as(other_cell)


func in_same_grid_position_as(grid_position: Vector2) -> bool:
	return grid_position.x == row and grid_position.y == column


func is_row_neighbour_of(other_cell: GridCellUI) -> bool:
	var left_column: int = column - 1
	var right_column: int = column + 1
	
	return in_same_row_as(other_cell) \
		and [left_column, right_column].any(func(near_column: int): return other_cell.column == near_column)


func is_column_neighbour_of(other_cell: GridCellUI) -> bool:
	var upper_row: int = row - 1
	var bottom_row: int = row + 1

	return in_same_column_as(other_cell) \
		and [upper_row, bottom_row].any(func(near_row: int): return other_cell.row == near_row)


func is_adjacent_to(other_cell: GridCellUI, check_diagonal: bool = false) -> bool:
	return is_row_neighbour_of(other_cell) \
		or is_column_neighbour_of(other_cell) \
		or (check_diagonal and in_diagonal_with(other_cell))
	

func in_diagonal_with(other_cell: GridCellUI) -> bool:
	var diagonal_top_right: Vector2 = Vector2(row - 1, column + 1)
	var diagonal_top_left: Vector2 = Vector2(row - 1, column - 1)
	var diagonal_bottom_right: Vector2 = Vector2(row + 1, column + 1)
	var diagonal_bottom_left: Vector2 = Vector2(row + 1, column - 1)

	return other_cell.in_same_grid_position_as(diagonal_top_right) \
		or other_cell.in_same_grid_position_as(diagonal_top_left) \
		or other_cell.in_same_grid_position_as(diagonal_bottom_right) \
		or other_cell.in_same_grid_position_as(diagonal_bottom_left)


func is_top_left_corner() -> bool:
	return neighbour_up == null and neighbour_left == null \
		and neighbour_bottom is GridCellUI and neighbour_right is GridCellUI
		

func is_top_right_corner() -> bool:
	return neighbour_up == null and neighbour_right == null \
		and neighbour_bottom is GridCellUI and neighbour_left is GridCellUI
		

func is_bottom_left_corner() -> bool:
	return neighbour_bottom == null and neighbour_left == null \
		and neighbour_up is GridCellUI and neighbour_right is GridCellUI
		

func is_bottom_right_corner() -> bool:
	return neighbour_bottom == null and neighbour_right == null \
		and neighbour_up is GridCellUI and neighbour_left is GridCellUI


func is_top_border() -> bool:
	return neighbour_up == null \
  		and neighbour_bottom is GridCellUI and neighbour_right is GridCellUI and neighbour_left is GridCellUI
		

func is_bottom_border() -> bool:
	return neighbour_bottom == null \
  		and neighbour_up is GridCellUI and neighbour_right is GridCellUI and neighbour_left is GridCellUI
		

func is_right_border() -> bool:
	return neighbour_right == null \
  		and neighbour_up is GridCellUI and neighbour_bottom is GridCellUI and neighbour_left is GridCellUI
					
	
func is_left_border() -> bool:
	return neighbour_left == null \
  		and neighbour_up is GridCellUI and neighbour_bottom is GridCellUI and neighbour_right is GridCellUI
#endregion

#region Piece related
func is_empty() -> bool:
	return current_piece == null
	

func has_piece() -> bool:
	return is_instance_valid(current_piece) and current_piece != null
	

func assign_piece(new_piece: PieceUI, overwrite: bool = false) -> void:
	if overwrite:
		replace_piece(new_piece)
	
	elif can_contain_piece and is_empty():
		current_piece = new_piece


func replace_piece(new_piece: PieceUI) -> PieceUI:
	var previous_piece = remove_piece()
	assign_piece(new_piece)
	
	return previous_piece if is_instance_valid(previous_piece) else null
	

func remove_piece():
	if has_piece():
		var previous_piece = current_piece
		current_piece = null
			
		return previous_piece
	
	return null


func swap_piece_with(other_cell: GridCellUI) -> bool:
	if can_swap_piece_with(other_cell):
		var previous_piece: PieceUI = current_piece
		var new_piece = other_cell.current_piece
		
		remove_piece()
		assign_piece(new_piece)
		
		other_cell.remove_piece()
		other_cell.assign_piece(previous_piece)
		
		swapped_piece.emit(self, other_cell)
		
		return true
		
	swap_rejected.emit(self, other_cell)
	
	return false


func available_neighbours(include_diagonals: bool = false) -> Array[GridCellUI]:
	var neighbours: Array[GridCellUI] = []
	
	if include_diagonals:
		neighbours.assign(Match3BoardPluginUtilities.remove_falsy_values([
			neighbour_up,
			neighbour_bottom,
			neighbour_right,
			neighbour_left,
			diagonal_neighbour_top_right,
			diagonal_neighbour_top_left,
			diagonal_neighbour_bottom_right,
			diagonal_neighbour_bottom_left
		]))
	else:
		neighbours.assign(Match3BoardPluginUtilities.remove_falsy_values([
			neighbour_up,
			neighbour_bottom,
			neighbour_right,
			neighbour_left,
		]))
	
	return neighbours


func diagonal_neighbours() -> Array[GridCellUI]:
	var neighbours: Array[GridCellUI] = []
	
	neighbours.assign(Match3BoardPluginUtilities.remove_falsy_values([
			diagonal_neighbour_top_right,
			diagonal_neighbour_top_left,
			diagonal_neighbour_bottom_right,
			diagonal_neighbour_bottom_left
		]))
	
	return neighbours


func can_swap_piece_with(other_cell: GridCellUI) -> bool:
	return other_cell != self \
		and other_cell.has_piece() \
		and has_piece() \
		and can_contain_piece \
		and other_cell.can_contain_piece \
		and not current_piece.is_locked() \
		and not other_cell.current_piece.is_locked() \
		and other_cell.current_piece != current_piece \
		and current_piece.can_be("swapped") and other_cell.current_piece.can_be("swapped")

#endregion
