class_name Match3SequenceConsumer extends RefCounted


var board: Board
## Dictionary with structure <RuleId, SequenceConsumeRule>
var rules: Dictionary = {}


func _init(_board: Board, consume_rules: Dictionary = {}):
	board = _board
	rules = consume_rules


func add_sequence_consume_rules(rules: Array[Match3SequenceConsumeRule]) -> Match3SequenceConsumer:
	for rule: Match3SequenceConsumeRule in rules:
		add_sequence_consume_rule(rule)
	
	return self
	
	
func add_sequence_consume_rule(rule: Match3SequenceConsumeRule) -> Match3SequenceConsumer:
	rules.get_or_add(rule.id, rule)
	
	return self


func consume_sequence(sequence: Match3Sequence) -> void:
	pass


#region Data container classes
class Match3SequenceConsumeResult:
	var sequence_size: int
	var combos: Array[Match3SequenceConsumeCombo]
	
	func _init(sequence_combos: Array[Match3SequenceConsumeCombo]) -> void:
		sequence_size = sequence_combos.reduce(func(accum, combo): return accum + combo.size, 0)
		combos = sequence_combos
	
	
	func unique_pieces() -> Array[Match3Piece]:
		var pieces: Array[Match3Piece] = []
		
		for combo: Match3SequenceConsumeCombo in combos:
			pieces.append(combo.piece)
		
		pieces.assign(Match3BoardPluginUtilities.remove_duplicates(pieces))
		
		return pieces


class Match3SequenceConsumeCombo:
	var piece: Match3Piece
	var size: int
	var special_piece_to_spawn: Match3Piece
	
	func _init(_piece: Match3Piece, combo_size: int, special_piece: Match3Piece) -> void:
		piece = _piece
		size = combo_size
		special_piece_to_spawn = special_piece

#endregion
