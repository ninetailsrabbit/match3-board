class_name Match3Piece extends RefCounted

signal locked
signal unlocked

enum PieceType {
	Normal,
	Special,
	Obstacle
}

var id: StringName
var type: PieceType = PieceType.Normal
var shape: StringName = &""

var can_be_swapped: bool = true
var can_be_moved: bool = true
var can_be_shuffled: bool = true
var can_be_triggered: bool = false
var can_be_replaced: bool = true
var can_be_consumed: bool = true


var is_locked: bool = false:
	set(value):
		if value != is_locked:
			is_locked = value
			
			if is_locked:
				locked.emit()
			else:
				unlocked.emit()


func _init(_id: StringName, _shape: StringName, _type: PieceType = PieceType.Normal) -> void:
	id = _id
	shape = _shape
	type = _type


func equals_to(other_piece: Match3Piece) -> bool:
	return same_type_as(other_piece) and same_shape_as(other_piece)


func same_type_as(other_piece: Match3Piece) -> bool:
	return type == other_piece.type 


func same_shape_as(other_piece: Match3Piece) -> bool:
	return shape == other_piece.shape 


#region Behaviour configuration
func with_swapped(enabled: bool) -> Match3Piece:
	can_be_swapped = enabled
	
	return self


func with_moved(enabled: bool) -> Match3Piece:
	can_be_moved = enabled
	
	return self


func with_shuffled(enabled: bool) -> Match3Piece:
	can_be_shuffled = enabled
	
	return self


func with_triggered(enabled: bool) -> Match3Piece:
	can_be_triggered = enabled
	
	return self


func with_replaced(enabled: bool) -> Match3Piece:
	can_be_replaced = enabled
	
	return self
	
func with_consumed(enabled: bool) -> Match3Piece:
	can_be_consumed = enabled
	
	return self

#endregion

#region Types
func is_normal() -> bool:
	return type == PieceType.Normal


func is_special() -> bool:
	return type == PieceType.Special


func is_obstacle() -> bool:
	return type == PieceType.Obstacle

#endregion
