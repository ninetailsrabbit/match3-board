class_name Match3PieceGenerator extends RefCounted


var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var available_pieces: Array[Match3PieceWeight] = []


func _init() -> void:
	rng.randomize()


func add_pieces(pieces: Array[Match3PieceWeight]) -> void:
	for piece: Match3PieceWeight in pieces:
		add_piece(piece)


func add_piece(piece: Match3PieceWeight) -> void:
	if available_pieces.has(piece):
		return
		
	available_pieces.append(piece)


func roll(except: Array[Match3PieceWeight] = []) -> Match3Piece:
	var available_pieces_to_roll = available_pieces.filter(
		func(piece: Match3PieceWeight): return not except.has(piece))
		
	var selected_piece: Match3Piece
	
	assert(available_pieces_to_roll.size() > 0, "Match3PieceGenerator: No pieces available to roll")
	
	available_pieces_to_roll.shuffle()
	selected_piece = _roll_piece(available_pieces_to_roll, _prepare_weight(available_pieces_to_roll))
	
	while selected_piece == null:
		selected_piece = _roll_piece(available_pieces_to_roll, _prepare_weight(available_pieces_to_roll))
	
	return selected_piece
	

func _prepare_weight(pieces: Array[Match3PieceWeight]) -> float:
	var total_weight: float = 0.0
	
	for piece_weight: Match3PieceWeight in pieces:
		piece_weight.reset_accum_weight()
		
		total_weight += piece_weight.current_weight
		piece_weight.total_accum_weight = total_weight
	
	return total_weight


func _roll_piece(pieces: Array[Match3PieceWeight], total_weight: float) -> Match3Piece:
	var threshold: float = rng.randf_range(0.0, total_weight)
	var selected_piece: Match3Piece
	
	for piece_weight: Match3PieceWeight in pieces:
		if threshold <= piece_weight.total_accum_weight:
			selected_piece = Match3Piece.from_piece(piece_weight.piece)
			break;
	
	return selected_piece
