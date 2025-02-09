class_name Match3GridCellUI extends Node2D

const GroupName: StringName = &"grid_cells"

@export var size: Vector2i = Vector2i(48, 48)
@export var texture_scale: float = 1.0
@export var odd_cell_texture: Texture2D
@export var even_cell_texture: Texture2D
@export var empty_cell_texture: Texture2D

## TODO - Extra nodes needs to be defined on a custom scene that inherits from this to avoid dependencies
@onready var sprite_2d: Sprite2D = $Sprite2D

var cell: Match3GridCell:
	set(value):
		if value != cell:
			cell = value
			
			if cell:
				cell.removed_piece.connect(on_removed_core_piece)
			
var piece_ui: Match3PieceUI:
	set(new_piece):
		piece_ui = new_piece
		
		if new_piece:
			new_piece.original_cell_position = position


func _enter_tree() -> void:
	assert(cell != null, "Match3GridCellUI: This UI Node needs a core grid cell to be usable")
	
	add_to_group(GroupName)
	
	name = "GridCellUI_[%d]_[%d]" % [cell.column, cell.row]


func _ready() -> void:
	## TODO - This sprite setup it's done actually in a custom scene that inherits from this cell ui
	sprite_2d.texture = get_texture()
	sprite_2d.scale = calculate_scale_texture_based_cell_size(sprite_2d.texture)


func has_piece() -> bool:
	return piece_ui != null
	

func is_empty() -> bool:
	return piece_ui == null


func can_swap_piece_with(other_cell: Match3GridCellUI) -> bool:
	return piece_ui and other_cell.piece_ui and cell.can_swap_piece_with_cell(other_cell.cell)


func swap_piece_with(other_cell: Match3GridCellUI) -> bool:
	if piece_ui and other_cell.piece_ui and cell.swap_piece_with_cell(other_cell.cell):
		var current_piece_ui: Match3PieceUI = piece_ui
		piece_ui = other_cell.piece_ui
		other_cell.piece_ui = current_piece_ui
		
		return true
			
	return false


func calculate_scale_texture_based_cell_size(texture: Texture2D) -> Vector2:
	var texture_size = texture.get_size()
	
	return Vector2(size.x / texture_size.x, size.y / texture_size.y) * texture_scale
	
	
func get_texture() -> Texture2D:
	if not cell.can_contain_piece:
		return empty_cell_texture
	
	return even_cell_texture if (cell.column + cell.row) % 2 == 0 else odd_cell_texture


func on_removed_core_piece(piece: Match3Piece) -> void:
	if is_instance_valid(piece_ui) and piece_ui.piece.id == piece.id and not piece_ui.is_queued_for_deletion():
		piece_ui.queue_free()
