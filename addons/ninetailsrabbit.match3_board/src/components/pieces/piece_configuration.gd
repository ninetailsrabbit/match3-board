class_name PieceConfiguration extends Resource


@export var id: StringName
@export var name: String
@export_multiline var description: String
@export var shape: String = ""
@export var can_be_actions: Dictionary[String, bool] = {
	"swapped": true,
	"moved": true,
	"consumed": true,
	"triggered": false
}


#region Overridables
func match_with(other_piece: PieceConfiguration) -> bool:
	if not can_be("consumed"):
		return false
		
	return shape == other_piece.shape
#endregion


func can_be(action: String) -> bool:
	return can_be_actions.get(action, false)
