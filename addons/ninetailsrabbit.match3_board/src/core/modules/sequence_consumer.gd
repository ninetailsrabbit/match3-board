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


func consume_sequence(sequence: Match3Sequence) -> Match3SequenceConsumeResult:
	var found_rule: Match3SequenceConsumeRule = null
	
	for rule: Match3SequenceConsumeRule in rules.values():
		if rule.meet_conditions(sequence):
			found_rule = rule
			break
	
	if found_rule:
		var result: Match3SequenceConsumeResult = null
		## TODO - SEE HOW TO SPLIT COMBOS WHEN THE SEQUENCE IS MORE COMPLEX THAN SIMILAR PIECES
		if sequence.all_pieces_are_the_same():
			return Match3SequenceConsumeResult.new([
				Match3SequenceConsumeCombo.new(sequence, found_rule.piece_to_spawn)
				])
		
	return  Match3SequenceConsumeResult.new([Match3SequenceConsumeCombo.new(sequence)])

#region Data container classes
class Match3SequenceConsumeResult:
	var sequence_size: int
	var combos: Array[Match3SequenceConsumeCombo]
	
	func _init(sequence_combos: Array[Match3SequenceConsumeCombo]) -> void:
		sequence_size = sequence_combos.reduce(func(accum, combo): return accum + combo.size(), 0)
		combos = sequence_combos
	
	
	func unique_pieces() -> Array[Match3Piece]:
		var pieces: Array[Match3Piece] = []
		
		for combo: Match3SequenceConsumeCombo in combos:
			pieces.append(combo.piece)
		
		pieces.assign(Match3BoardPluginUtilities.remove_duplicates(pieces))
		
		return pieces


class Match3SequenceConsumeCombo:
	var sequence: Match3Sequence
	var special_piece_to_spawn: Match3Piece
	
	
	func _init(_sequence: Match3Sequence, piece_to_spawn: Match3Piece = null) -> void:
		sequence = _sequence
		special_piece_to_spawn = piece_to_spawn
	
	
	func size() -> int:
		return sequence.size()

#endregion
