extends Node2D

@onready var match_3_board: Match3Board = $Match3Board



func _ready() -> void:
	match_3_board.change_sequence_consumer(DemoSequenceConsumer.new())
