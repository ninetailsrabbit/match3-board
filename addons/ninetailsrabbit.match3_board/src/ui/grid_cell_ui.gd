class_name Match3GridCellUI extends Node2D

const GroupName: StringName = &"grid_cells"


@export_category("Parameters")
@export var column: int = 0
@export var row: int = 0
@export var can_contain_piece: bool = true
@export var size: Vector2i = Vector2i(48, 48)
@export_category("Textures")
@export var texture_scale: float = 1.0
@export var odd_cell_texture: Texture2D
@export var even_cell_texture: Texture2D
@export var empty_cell_texture: Texture2D


#region Cached neighbours
## The Match3Board assign this values when preparing the cells so that they are always available as a cache.
var neighbour_up: Match3GridCellUI
var neighbour_bottom: Match3GridCellUI
var neighbour_right: Match3GridCellUI
var neighbour_left: Match3GridCellUI
var diagonal_neighbour_top_right: Match3GridCellUI
var diagonal_neighbour_top_left: Match3GridCellUI
var diagonal_neighbour_bottom_right: Match3GridCellUI
var diagonal_neighbour_bottom_left: Match3GridCellUI
#endregion

## Could be Sprite2D or AnimatedSprite2D
var sprite_2d
var piece: Match3PieceUI:
	set(new_piece):
		if piece != new_piece:
			piece = new_piece
			
			if new_piece:
				new_piece.cell = self
				new_piece.tree_exited.connect(func(): piece = null, CONNECT_ONE_SHOT)
			

func _enter_tree() -> void:
	add_to_group(GroupName)
	
	name = "GridCellUI_[%d]_[%d]" % [column, row]


func _ready() -> void:
	_prepare_sprite()
	
	
func _prepare_sprite() -> void:
	sprite_2d = Match3BoardPluginUtilities.first_node_of_type(self, Sprite2D.new())
	
	if sprite_2d == null:
		sprite_2d = Match3BoardPluginUtilities.first_node_of_type(self, AnimatedSprite2D.new())
	
	if sprite_2d is Sprite2D:
		sprite_2d.texture = get_texture()
		sprite_2d.scale = calculate_scale_texture_based_on_cell_size(sprite_2d.texture)
	elif sprite_2d is AnimatedSprite2D:
		sprite_2d.scale = calculate_scale_texture_based_on_cell_size(sprite_2d.get_sprite_2d_frames().get_frame(sprite_2d.animation, sprite_2d.get_frame()))
	

func has_piece() -> bool:
	return piece != null
	

func is_empty() -> bool:
	return piece == null


func remove_piece(queued: bool = false) -> void:
	if has_piece():
		if queued:
			piece.queue_free()
		else:
			piece.free()
		

func can_swap_piece_with_cell(other_cell: Match3GridCellUI) -> bool:
	return other_cell != self \
		and has_piece() \
		and other_cell.has_piece() \
		and piece != other_cell.piece \
		and piece.can_be_swapped \
		and other_cell.piece.can_be_swapped \
		and not piece.is_locked \
		and not other_cell.piece.is_locked


func swap_piece_with_cell(other_cell: Match3GridCellUI) -> bool:
	if can_swap_piece_with_cell(other_cell):
		var current_piece: Match3PieceUI = piece
		piece = other_cell.piece
		other_cell.piece = current_piece
		
		return true
			
	return false
#
#
func calculate_scale_texture_based_on_cell_size(texture: Texture2D) -> Vector2:
	var texture_size = texture.get_size()
	
	return Vector2(size.x / texture_size.x, size.y / texture_size.y) * texture_scale
	
	
func get_texture() -> Texture2D:
	if not can_contain_piece:
		return empty_cell_texture
	
	if even_cell_texture and odd_cell_texture:
		return even_cell_texture if (column + row) % 2 == 0 else odd_cell_texture
	elif even_cell_texture and odd_cell_texture == null:
		return even_cell_texture
	elif odd_cell_texture and even_cell_texture == null:
		return odd_cell_texture
	
	return empty_cell_texture



#region Grid position
func board_position() -> Vector2:
	return Vector2(column, row)


func in_same_row_as(other_cell: Match3GridCellUI) -> bool:
	return row == other_cell.row


func in_same_column_as(other_cell: Match3GridCellUI) -> bool:
	return column == other_cell.column


func in_same_position_as(other_cell: Match3GridCellUI) -> bool:
	return in_same_column_as(other_cell) and in_same_row_as(other_cell)


func in_same_grid_position_as(grid_position: Vector2) -> bool:
	return grid_position.x == column and grid_position.y == row

#endregion

#region Neighbours
func is_row_neighbour_of(other_cell: Match3GridCellUI) -> bool:
	var left_column: int = column - 1
	var right_column: int = column + 1
	
	return in_same_row_as(other_cell) \
		and [left_column, right_column].any(func(near_column: int): 
			return other_cell.column == near_column)


func is_column_neighbour_of(other_cell: Match3GridCellUI) -> bool:
	var upper_row: int = row - 1
	var bottom_row: int = row + 1

	return in_same_column_as(other_cell) \
		and [upper_row, bottom_row].any(func(near_row: int): return other_cell.row == near_row)


func is_adjacent_to(other_cell: Match3GridCellUI, check_diagonal: bool = false) -> bool:
	return is_row_neighbour_of(other_cell) \
		or is_column_neighbour_of(other_cell) \
		or (check_diagonal and in_diagonal_with(other_cell))
	
	
func is_diagonal_adjacent_to(other_cell: Match3GridCellUI) -> bool:
	return is_adjacent_to(other_cell, true)


func in_diagonal_with(other_cell: Match3GridCellUI) -> bool:
	var diagonal_top_right: Vector2 = Vector2(row - 1, column + 1)
	var diagonal_top_left: Vector2 = Vector2(row - 1, column - 1)
	var diagonal_bottom_right: Vector2 = Vector2(row + 1, column + 1)
	var diagonal_bottom_left: Vector2 = Vector2(row + 1, column - 1)

	return other_cell.in_same_grid_position_as(diagonal_top_right) \
		or other_cell.in_same_grid_position_as(diagonal_top_left) \
		or other_cell.in_same_grid_position_as(diagonal_bottom_right) \
		or other_cell.in_same_grid_position_as(diagonal_bottom_left)


func neighbours() -> Dictionary:
	return {
		"up": neighbour_up,
		"bottom": neighbour_bottom,
		"right": neighbour_right,
		"left": neighbour_left,
		"diagonal_top_right": diagonal_neighbour_top_right,
		"diagonal_top_left": diagonal_neighbour_top_left,
		"diagonal_bottom_right": diagonal_neighbour_bottom_right,
		"diagonal_bottom_left": diagonal_neighbour_bottom_left,
	}
	

func is_top_left_corner() -> bool:
	return neighbour_up == null and neighbour_left == null \
		and neighbour_bottom is Match3GridCellUI and neighbour_right is Match3GridCellUI
		

func is_top_right_corner() -> bool:
	return neighbour_up == null and neighbour_right == null \
		and neighbour_bottom is Match3GridCellUI and neighbour_left is Match3GridCellUI
		

func is_bottom_left_corner() -> bool:
	return neighbour_bottom == null and neighbour_left == null \
		and neighbour_up is Match3GridCellUI and neighbour_right is Match3GridCellUI
		

func is_bottom_right_corner() -> bool:
	return neighbour_bottom == null and neighbour_right == null \
		and neighbour_up is Match3GridCellUI and neighbour_left is Match3GridCellUI


func is_top_border() -> bool:
	return (is_top_left_corner() or is_top_right_corner()) \
		or (neighbour_up == null and neighbour_bottom is Match3GridCellUI and neighbour_right is Match3GridCellUI and neighbour_left is Match3GridCellUI)
		

func is_bottom_border() -> bool:
	return (is_bottom_left_corner() or is_bottom_right_corner()) \
	or (neighbour_bottom == null and neighbour_up is Match3GridCellUI and neighbour_right is Match3GridCellUI and neighbour_left is Match3GridCellUI)
		

func is_right_border() -> bool:
	return (is_top_right_corner() or is_bottom_right_corner()) \
		or (neighbour_right == null and neighbour_up is Match3GridCellUI and neighbour_bottom is Match3GridCellUI and neighbour_left is Match3GridCellUI)
					
	
func is_left_border() -> bool:
	return (is_top_left_corner() or is_bottom_left_corner()) \
		or (neighbour_left == null and neighbour_up is Match3GridCellUI and neighbour_bottom is Match3GridCellUI and neighbour_right is Match3GridCellUI)
#endregion
