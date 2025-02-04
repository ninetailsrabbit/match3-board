class_name SequenceConsumeRule extends Resource


@export var id: StringName
@export var shapes: Array[Match3Sequence.Shapes] = []
@export var piece_to_spawn: Match3PieceConfiguration
## Piece IDs order are readed from left to right for horizontal shapes
## and vertical shapes top to bottom (where left is top)
@export var target_pieces: Array[Match3PieceConfiguration] = []
