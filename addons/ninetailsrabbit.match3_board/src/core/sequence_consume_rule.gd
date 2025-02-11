class_name Match3SequenceConsumeRule extends RefCounted

var id: StringName
var shapes: Array[Match3Sequence.Shapes] = []
var piece_to_spawn: Match3PieceConfiguration
## Piece IDs order are readed from left to right for horizontal shapes
## and vertical shapes top to bottom (where left is top)
var target_pieces: Array[Match3PieceConfiguration] = []


func _init(_id: StringName, sequence_shapes: Array[Match3Sequence.Shapes], pieces: Array[Match3PieceConfiguration], to_spawn: Match3PieceConfiguration) -> void:
	id = _id
	shapes = sequence_shapes
	target_pieces = pieces
	piece_to_spawn = to_spawn


func meet_conditions(sequence: Match3Sequence) -> bool:
	if not shapes.has(sequence.shape):
		return false
	
	var sequence_pieces: Array[Match3PieceUI] = sequence.normal_pieces()

	if sequence_pieces.size() != target_pieces.size():
		return false
	
	var contain_all_pieces: bool = true
	
	for piece: Match3PieceUI in sequence_pieces:
		if not target_pieces.any(func(piece_conf: Match3PieceConfiguration): return piece_conf.id == piece.id):
			contain_all_pieces = false
			break
		
	return contain_all_pieces
