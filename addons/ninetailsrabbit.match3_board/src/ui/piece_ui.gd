class_name Match3PieceUI extends Node2D

const GroupName: StringName = &"pieces"
const SpecialGroupName: StringName = &"special-pieces"
const ObstacleGroupName: StringName = &"obstacle-pieces"


var piece: Match3Piece


func _enter_tree() -> void:
	add_to_group(GroupName)
	
	if piece.is_special():
		add_to_group(SpecialGroupName)
	elif piece.is_obstacle():
		add_to_group(ObstacleGroupName)
	
	
func _ready() -> void:
	assert(piece != null, "Match3PieceUI: The Piece UI needs the core piece to get the information to be usable")
	
	name = "%s_%s" % [piece.id, piece.shape]


#region Overridables
func match_with(other_piece: PieceUI) -> bool:
	if other_piece.is_obstacle():
		return false
		
	return piece.equals_to(other_piece.piece)
