@tool
class_name Match3Preview extends Node2D

@export var test: bool = false:
	set(value):
		test = false
		draw_preview_cells()
@export var board: Match3Board:
	set(value):
		if value != board:
			board = value
			
			if board:
				draw_preview_cells()
			else:
				remove_preview_cells()
			
@export_category("Editor Debug 🪲")
@export var preview_cell_texture: Texture2D
@export var texture_scale: float = 1.0
@export var display_cell_position: bool = true


func _ready() -> void:
	if Engine.is_editor_hint():
		draw_preview_cells()
	else:
		queue_free()


func remove_preview_cells() -> Match3Preview:
	for child in get_children():
			child.free()
			
	return self
		
	
func draw_preview_cells() -> Match3Preview:
	if Engine.is_editor_hint() and board:
		remove_preview_cells()
			
		var cells = []
		
		if cells.is_empty():
			for column in board.configuration.grid_width:
				cells.append([])
				
				for row in board.configuration.grid_height:
					var cell_sprite: Sprite2D = Sprite2D.new()
					var label: Label = Label.new()
					
					if preview_cell_texture:
						cell_sprite.texture = preview_cell_texture
						var texture_size = cell_sprite.texture.get_size()
						cell_sprite.scale = Vector2(board.configuration.cell_size.x / texture_size.x, board.configuration.cell_size.y / texture_size.y) * texture_scale
					
					cell_sprite.position = Vector2(board.configuration.cell_size.x * column, board.configuration.cell_size.y * row)
					
					if display_cell_position:
						label.text = "(%d,%d)" % [column, row]
					
					cell_sprite.add_child(label)
					add_child(cell_sprite)
					Match3BoardPluginUtilities.set_owner_to_edited_scene_root(cell_sprite)
					Match3BoardPluginUtilities.set_owner_to_edited_scene_root(label)
					
	return self
