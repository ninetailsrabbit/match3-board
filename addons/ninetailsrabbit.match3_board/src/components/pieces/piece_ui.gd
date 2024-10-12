class_name PieceUI extends Node2D

signal selected
signal unselected

const GroupName: String = "piece"

@export var piece_definition: PieceDefinitionResource
@export var cell_size: Vector2i = Vector2(48, 48)
@export var texture_scale: float = 0.85

var board
var is_locked: bool = false
var is_selected: bool = false:
	set(value):
		if value != is_selected and not is_locked and is_inside_tree():
			is_selected = value
			
			if is_selected:
				selected.emit()
				board.piece_selected.emit(self as PieceUI)
			else:
				unselected.emit()
				board.piece_unselected.emit(self as PieceUI)


func _enter_tree() -> void:
	add_to_group(GroupName)
	
	name = "%s-%s" % [piece_definition.type, piece_definition.shape.to_pascal_case()]
	is_selected = false
	z_index = 20
	
	if board == null:
		board = get_tree().get_first_node_in_group(Match3Preloader.BoardGroupName)


func prepare_sprite(sprite: Sprite2D) -> void:
	sprite.texture = piece_definition.image
	var texture_size = sprite.texture.get_size()
	sprite.scale = Vector2(cell_size.x / texture_size.x, cell_size.y / texture_size.y) * texture_scale
	

func match_with(other_piece:PieceUI) -> bool:
	return piece_definition.match_with(other_piece.piece_definition)


func can_be_swapped() -> bool:
	return piece_definition.can_be_swapped


func can_be_moved() -> bool:
	return piece_definition.can_be_moved


func can_be_replaced() -> bool:
	return piece_definition.can_be_replaced


func can_be_shuffled() -> bool:
	return piece_definition.can_be_shuffled


func can_be_triggered() -> bool:
	return piece_definition.can_be_triggered


func lock() -> void:
	is_locked = true
	

func unlock() -> void:
	is_locked = false
