@tool
class_name Match3Preview extends Node2D

@export var button_Generate_Preview: String
@export var board: Match3Board:
	set(value):
		if value != board:
			board = value
			
			if board:
				draw_preview_cells()
			else:
				remove_preview_cells()
			
@export_category("Editor Debug 🪲")
@export var preview_pieces: Array[Texture2D] = []:
	set(value):
			preview_pieces = value
			draw_preview_cells()
			
@export var preview_cell_texture: Texture2D:
	set(value):
		if value != preview_cell_texture:
			preview_cell_texture = value
			draw_preview_cells()

@export var piece_texture_scale: float = 0.85:
	set(value):
		if value != piece_texture_scale:
			piece_texture_scale = value
			draw_preview_cells()
		
@export var cell_texture_scale: float = 1.0:
	set(value):
		if value != cell_texture_scale:
			cell_texture_scale = value
			draw_preview_cells()
		
@export var position_font_size: int = 32:
	set(value):
		if value != position_font_size:
			position_font_size = value
			draw_preview_cells()
			
@export var display_cell_position: bool = true:
	set(value):
		if value != display_cell_position:
			display_cell_position = value
			draw_preview_cells()


func _enter_tree() -> void:
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
			
		for column in board.configuration.grid_width:
			for row in board.configuration.grid_height:
				var cell := draw_preview_cell(column, row)
				add_child(cell)
				Match3BoardPluginUtilities.set_owner_to_edited_scene_root(cell)
				
				if Match3BoardPluginUtilities.remove_falsy_values(preview_pieces).size() > 0:
					var piece :=  draw_preview_piece(cell, column, row)
					add_child(piece)
					Match3BoardPluginUtilities.set_owner_to_edited_scene_root(piece)
					
				if display_cell_position:
					var label := draw_label_cell_position(cell, column, row)
					Match3BoardPluginUtilities.set_owner_to_edited_scene_root(label)
					
	return self
	
	
func draw_preview_cell(column: int, row: int) -> Sprite2D:
	if preview_cell_texture:
		var cell_sprite: Sprite2D = Sprite2D.new()
		
		cell_sprite.name = "Cell(%d,%d)" % [column, row]
		cell_sprite.texture = preview_cell_texture
		var cell_texture_size = cell_sprite.texture.get_size()
		cell_sprite.scale = Vector2(
			board.configuration.cell_size.x / cell_texture_size.x, 
			board.configuration.cell_size.y / cell_texture_size.y
			) * cell_texture_scale
	
		cell_sprite.position = Vector2(board.configuration.cell_size.x * column, board.configuration.cell_size.y * row)
		cell_sprite.z_index = 0
		
		return cell_sprite
		
	return null


func draw_preview_piece(cell: Sprite2D, column: int, row: int) -> Sprite2D:
	var piece_sprite: Sprite2D = Sprite2D.new()
	piece_sprite.name = "Piece(%d,%d)" % [column, row]
	
	piece_sprite.texture = preview_pieces.pick_random()
	var piece_texture_size = piece_sprite.texture.get_size()
	piece_sprite.scale = Vector2(
		board.configuration.cell_size.x / piece_texture_size.x, 
		board.configuration.cell_size.y / piece_texture_size.y
		) * piece_texture_scale
	
	piece_sprite.position = cell.position
	piece_sprite.z_index = 1
	
	return piece_sprite
	

func draw_label_cell_position(cell: Sprite2D, column, row) -> Label:
	var label: Label = Label.new()
	label.z_index = 2
	label.text = "(%d,%d)" % [column, row]
	label.add_theme_font_size_override("font_size", position_font_size)
	cell.add_child(label)
	label.set_anchors_preset(Control.PRESET_CENTER)
	
	return label


func _on_tool_button_pressed(text: String) -> void:
	match text:
		"Generate Preview":
			draw_preview_cells()
