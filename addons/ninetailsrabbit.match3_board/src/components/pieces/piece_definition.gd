class_name PieceDefinitionResource extends Resource

enum PieceType {
	Normal,
	Special,
	Obstacle
}

@export var id: StringName
@export var name: String
@export_multiline var description: String
## The type of this piece, refers to behaviour
@export var type: PieceType = PieceType.Normal
## A piece can share a behaviour (type) but with different shape so they are not strictly equals
@export var shape: String = ""
@export var can_be_swapped: bool = true
@export var can_be_moved: bool = true
@export var can_be_shuffled: bool = true
@export var can_be_triggered: bool = false
@export var can_be_replaced: bool = true
@export var can_be_consumed: bool = true


#region Overridables
func match_with(other_piece: PieceDefinitionResource) -> bool:
	if not can_be_consumed:
		return false
		
	match type:
		PieceType.Normal:
			return (type == other_piece.type and shape == other_piece.shape) or (other_piece.is_special() and shape == other_piece.shape)
		PieceType.Special:
			return shape == other_piece.shape
		PieceType.Obstacle:
			return false
		_:
			return false
#endregion


func is_normal() -> bool:
	return type == PieceType.Normal


func is_special() -> bool:
	return type == PieceType.Special


func is_obstacle() -> bool:
	return type == PieceType.Obstacle
