class_name PieceWeightGenerator


var random: RandomNumberGenerator = RandomNumberGenerator.new()
var available_pieces: Array[PieceDefinitionResource] = []


func _init() -> void:
	random.randomize()


func add_available_pieces(new_pieces: Array[PieceDefinitionResource]) -> void:
	for piece: PieceDefinitionResource in new_pieces:
		add_available_piece(piece)
	

func add_available_piece(new_piece: PieceDefinitionResource) -> void:
	if not available_pieces.has(new_piece):
		available_pieces.append(new_piece)

	
func update_piece(piece: PieceDefinitionResource) -> void:
	var index = available_pieces.find(piece)
	
	if index != -1:
		available_pieces[index] = piece


func roll(except: Array[PieceDefinitionResource] = []) -> PieceDefinitionResource:
	var available_pieces_to_roll = available_pieces.filter(func(piece): return not except.has(piece))
	var selected_piece: PieceDefinitionResource
	
	assert(available_pieces_to_roll.size() > 0, "PieceWeightGenerator: No pieces available to roll")
	
	available_pieces_to_roll.shuffle()
	selected_piece = _roll_piece(available_pieces_to_roll, _prepare_weight(available_pieces_to_roll))
	
	while selected_piece == null:
		selected_piece = _roll_piece(available_pieces_to_roll, _prepare_weight(available_pieces_to_roll))
	
	return selected_piece
	

func _prepare_weight(pieces: Array[PieceDefinitionResource]) -> float:
	var total_weight: float = 0.0
	
	for piece: PieceDefinitionResource in pieces:
		piece.reset_accum_weight()
		
		total_weight += piece.weight
		piece.total_accum_weight = total_weight
	
	return total_weight


func _roll_piece(pieces: Array[PieceDefinitionResource], total_weight: float):
	var roll_result: float = randf_range(0.0, total_weight)
	var selected_piece: PieceDefinitionResource
	
	for piece: PieceDefinitionResource in pieces:
		if roll_result <= piece.total_accum_weight:
			selected_piece = piece.duplicate()
			break;
	
	
	return selected_piece
