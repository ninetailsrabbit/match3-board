class_name Match3SequenceConsumeRule extends RefCounted

var id: StringName
var piece_to_spawn: Match3Piece
## Piece IDs order are readed from left to right for horizontal shapes
## and vertical shapes top to bottom (where left is top)
var pieces_order: Array[StringName] = []


func _init(_id: StringName, order: Array[StringName], to_spawn: Match3Piece) -> void:
	id = _id
	pieces_order = order
	piece_to_spawn = to_spawn


func meet_conditions(sequence: Match3Sequence) -> bool:
	var piece_ids: Array[StringName] = sequence.normal_pieces().map(func(piece: Match3Piece): return piece.id)
	
	if piece_ids.size() != pieces_order.size():
		return false
	
	for index: int in pieces_order.size():
		if piece_ids[index] != pieces_order[index]:
			return false
	
	return true
