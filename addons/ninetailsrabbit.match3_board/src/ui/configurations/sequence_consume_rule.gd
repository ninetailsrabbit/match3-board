class_name SequenceConsumeRule extends Resource


@export var id: StringName
## The rules are ordered by priority, rules with higher priority values are checked first
@export var priority: int = 0:
	set(value):
		priority = maxi(0, value)
@export var shapes: Array[Match3Sequence.Shapes] = []
@export var piece_to_spawn: Match3PieceConfiguration
## Piece IDs order are readed from left to right for horizontal shapes
## and vertical shapes top to bottom (where left is top)
@export var target_pieces: Array[Match3PieceConfiguration] = []


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
