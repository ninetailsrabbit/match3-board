class_name Match3PieceWeight extends RefCounted

var piece: Match3Piece
var weight: float = 1.0:
	set(value):
		weight = maxf(0.0, value)
		
var current_weight: float = weight
var total_accum_weight: float = 0.0


func _init(_piece: Match3Piece, _weight: float) -> void:
	piece = _piece
	weight = _weight
	current_weight = weight
	
	
func reset_accum_weight() -> void:
	total_accum_weight = 0.0


func change_weight(new_value: float) -> void:
	current_weight = new_value


func change_to_original_weight() -> void:
	current_weight = weight
