class_name Match3PieceConfiguration extends Resource

@export var scene: PackedScene
@export var id: StringName
@export var name: String
@export_multiline var description: String
@export var weight: Match3PieceWeight
## The type of this piece, refers to behaviour
@export var type: Match3PieceUI.PieceType = Match3PieceUI.PieceType.Normal
## A piece can share a behaviour (type) but with different shape so they are not strictly equals
@export var shape: StringName = &""
@export var color: Color = Color.BLACK
@export var priority: int = 0:
	set(value):
		priority = maxi(0, value)
@export var pieces_collision_layer: int = 8:
	set(value):
		pieces_collision_layer = clampi(value, 0, 32)
@export var can_be_swapped: bool = true
@export var can_be_moved: bool = true
@export var can_be_shuffled: bool = true
@export var can_be_triggered: bool = false
@export var can_be_replaced: bool = true
@export var can_be_consumed: bool = true


func is_normal() -> bool:
	return type == Match3Piece.PieceType.Normal


func is_special() -> bool:
	return type == Match3Piece.PieceType.Special


func is_obstacle() -> bool:
	return type == Match3Piece.PieceType.Obstacle
