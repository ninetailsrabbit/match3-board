class_name Match3PieceUI extends Node2D

const GroupName: StringName = &"pieces"
const SpecialGroupName: StringName = &"special-pieces"
const ObstacleGroupName: StringName = &"obstacle-pieces"

@export var texture_scale: float = 0.85


var piece: Match3Piece
var original_z_index: int = 0


func _enter_tree() -> void:
	add_to_group(GroupName)
	
	if piece.is_special():
		add_to_group(SpecialGroupName)
	elif piece.is_obstacle():
		add_to_group(ObstacleGroupName)
	
	z_index = 10
	original_z_index = z_index
	
	
func _ready() -> void:
	assert(piece != null, "Match3PieceUI: The Piece UI needs the core piece to get the information to be usable")
	
	name = "%s_%s" % [piece.id, piece.shape]
	
	## TODO - TEMPORARY FOR TESTING PURPOSES, This should be in a custom scene that inherits from this
	$Sprite2D.scale = calculate_scale_texture_based_on_size($Sprite2D.texture)


func calculate_scale_texture_based_on_size(texture: Texture2D, size: Vector2i = Vector2i(48, 48)) -> Vector2:
	var texture_size = texture.get_size()
	
	return Vector2(size.x / texture_size.x, size.y / texture_size.y) * texture_scale
	

#region Overridables
func match_with(other_piece: PieceUI) -> bool:
	if other_piece.is_obstacle():
		return false
		
	return piece.equals_to(other_piece.piece)

#endregion
