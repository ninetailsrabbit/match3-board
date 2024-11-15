class_name SpecialCrossPiece extends PieceUI


@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	super._ready()
	animation_player.play("idle")
