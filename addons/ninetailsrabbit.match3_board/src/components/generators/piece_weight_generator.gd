class_name PieceWeightGenerator


var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var available_pieces: Array[PieceWeight] = []

## This dictionary is to map the piece weight that holds a scene with the corresponding id.
## This is useful to not need change the id on both resources but only on the final scene.
## Dictionary[StringName, PieceWeight]
var piece_id_mapper: Dictionary = {}


func _init() -> void:
	rng.randomize()


func add_available_pieces(new_pieces: Array[PieceWeight]) -> void:
	for piece: PieceWeight in new_pieces:
		add_available_piece(piece)
	

func add_available_piece(new_piece: PieceWeight) -> void:
	if not available_pieces.has(new_piece):
		available_pieces.append(new_piece)

	
func update_piece(piece: PieceWeight) -> void:
	var index = available_pieces.find(piece)
	
	if index != -1:
		available_pieces[index] = piece


func roll(except: Array[PieceWeight] = []) -> PieceUI:
	var available_pieces_to_roll = available_pieces.filter(func(piece: PieceWeight): return not except.has(piece))
	var selected_piece: PieceUI
	
	assert(available_pieces_to_roll.size() > 0, "PieceWeightGenerator: No pieces available to roll")
	
	available_pieces_to_roll.shuffle()
	selected_piece = _roll_piece(available_pieces_to_roll, _prepare_weight(available_pieces_to_roll))
	
	while selected_piece == null:
		selected_piece = _roll_piece(available_pieces_to_roll, _prepare_weight(available_pieces_to_roll))
	
	return selected_piece
	

func _prepare_weight(pieces: Array[PieceWeight]) -> float:
	var total_weight: float = 0.0
	
	for piece_weight: PieceWeight in pieces:
		piece_weight.reset_accum_weight()
		
		total_weight += piece_weight.current_weight
		piece_weight.total_accum_weight = total_weight
	
	return total_weight


func _roll_piece(pieces: Array[PieceWeight], total_weight: float):
	var roll_result: float = rng.randf_range(0.0, total_weight)
	var selected_piece: PieceUI
	
	for piece_weight: PieceWeight in pieces:
		if roll_result <= piece_weight.total_accum_weight:
			selected_piece = piece_weight.piece_scene.instantiate()
			
			if not piece_id_mapper.has(selected_piece.piece_definition.id):
				piece_id_mapper[selected_piece.piece_definition.id] = piece_weight
				
			break;
	
	return selected_piece
