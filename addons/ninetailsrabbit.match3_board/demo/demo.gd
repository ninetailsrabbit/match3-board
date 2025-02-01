extends Node2D

#@onready var match_3_board: Match3Board = $Match3Board
@onready var state_label: Label = $StateLabel



func _ready() -> void:
	state_label.text = "WaitForInput"
	
	var g1 = Match3GridCell.new(0, 0)
	var g2 = Match3GridCell.new(0, 1)
	
	var p1 = Match3Piece.new("pie", "triangle")
	var p2 = Match3Piece.new("bub", "square")
	
	g1.assigned_new_piece.connect(func(piece: Match3Piece): print("assigned new piece ", piece.id))
	g1.replaced_piece.connect(func(old_piece: Match3Piece, piece: Match3Piece): print("replaced piece ", old_piece.id, piece.id))
	g2.removed_piece.connect(func(piece: Match3Piece): print("removed piece: ", piece.id))
	
	g1.assign_piece(p1)
	g2.assign_piece(p2)
	
	print(g1.piece.id, g2.piece.id)
	
	g1.swap_piece_with_cell(g2)
	print(g1.piece.id, g2.piece.id)
	
	
	g2.remove_piece()
	print("removed g2 piece: ", g2.piece)
	
	var board: Board = Board.new(9, 9, 30, true)
	
	#match_3_board.change_sequence_consumer(DemoSequenceConsumer.new())
	#match_3_board.state_changed.connect(on_state_changed)
	

func on_state_changed(from: Match3Board.BoardState, to: Match3Board.BoardState) -> void:
	var from_state: String = ""
	var to_state: String = ""
	
	if from == Match3Board.BoardState.WaitForInput:
		from_state = "WaitForInput"
	elif from == Match3Board.BoardState.Consume:
		from_state = "Consume"
	elif from == Match3Board.BoardState.Fill:
		from_state = "Fill"
		
	if to == Match3Board.BoardState.WaitForInput:
		to_state = "WaitForInput"
	elif to == Match3Board.BoardState.Consume:
		to_state = "Consume"
	elif to == Match3Board.BoardState.Fill:
		to_state = "Fill"
	
	state_label.text = "%s -> [%s]" % [from_state, to_state]
