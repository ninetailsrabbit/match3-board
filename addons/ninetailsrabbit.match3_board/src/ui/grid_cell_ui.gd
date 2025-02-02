class_name Match3GridCellUI extends Node2D

const GroupName: StringName = "grid_cells"

@export var size: Vector2i = Vector2i(48, 48)
@export var odd_cell_texture: Texture2D
@export var even_cell_texture: Texture2D
@export var empty_cell_texture: Texture2D

@onready var sprite_2d: Sprite2D = $Sprite2D

var cell: Match3GridCell


func _enter_tree() -> void:
	assert(cell != null, "Match3GridCellUI: This UI Node needs a core grid cell to be usable")
	
	add_to_group(GroupName)
	
	name = "GridCellUI_[%d]_[%d]" % [cell.column, cell.row]


func _ready() -> void:
	sprite_2d.texture = get_texture()
	sprite_2d.scale = calculate_scale_texture_based_cell_size(sprite_2d.texture)


func calculate_scale_texture_based_cell_size(texture: Texture2D) -> Vector2:
	var texture_size = texture.get_size()
	
	return Vector2(size.x / texture_size.x, size.y / texture_size.y)
	
	
func get_texture() -> Texture2D:
	return even_cell_texture if (cell.column + cell.row) % 2 == 0 else odd_cell_texture
