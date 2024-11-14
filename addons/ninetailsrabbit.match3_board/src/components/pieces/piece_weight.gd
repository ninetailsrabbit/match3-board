class_name PieceWeight extends Resource

@export var weight: float = 1.0
@export var piece_scene: PackedScene


var current_weight: float = weight
var total_accum_weight: float = 0.0


func reset_accum_weight() -> void:
	total_accum_weight = 0.0


func change_weight(new_value: float) -> void:
	current_weight = new_value


func change_to_original_weight() -> void:
	current_weight = weight
