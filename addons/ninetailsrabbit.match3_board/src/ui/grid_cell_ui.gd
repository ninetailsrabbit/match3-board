class_name Match3GridCellUI extends Node2D

const GroupName: StringName = "grid_cells"

@export var size: Vector2i = Vector2i(48, 48)
@export var odd_cell_texture: Texture2D
@export var even_cell_texture: Texture2D
@export var empty_cell_texture: Texture2D


var cell: Match3GridCell


func _enter_tree() -> void:
	assert(cell != null, "Match3GridCellUI: This UI Node needs a core grid cell to be usable")
	
	add_to_group(GroupName)
	
	name = "GridCellUI_[%d]_[%d]" % [cell.column, cell.row]
