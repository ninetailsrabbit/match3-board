extends Node2D

#@onready var match_3_board: Match3Board = $Match3Board
@onready var state_label: Label = $StateLabel
@onready var match_3_board: Match3Board = $Match3Board



func _ready() -> void:
	state_label.text = "WaitForInput"
	
	match_3_board.state_changed.connect(on_state_changed)
	

func on_state_changed(from: Match3Board.BoardState, to: Match3Board.BoardState) -> void:
	var from_state: String = ""
	var to_state: String = ""
	
	if from == Match3Board.BoardState.WaitForInput:
		from_state = "WaitForInput"
	elif from == Match3Board.BoardState.Consume:
		from_state = "Consume"
	elif from == Match3Board.BoardState.SpecialConsume:
		from_state = "SpecialConsume"
	elif from == Match3Board.BoardState.Fall:
		from_state = "Fall"
	elif from == Match3Board.BoardState.Fill:
		from_state = "Fill"
		
	if to == Match3Board.BoardState.WaitForInput:
		to_state = "WaitForInput"
	elif to == Match3Board.BoardState.Consume:
		to_state = "Consume"
	elif to == Match3Board.BoardState.SpecialConsume:
		to_state = "SpecialConsume"
	elif to == Match3Board.BoardState.Fall:
		to_state = "Fall"
	elif to == Match3Board.BoardState.Fill:
		to_state = "Fill"
	
	state_label.text = "%s -> [%s]" % [from_state, to_state]
