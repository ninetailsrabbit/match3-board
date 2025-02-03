class_name Match3PieceUI extends Node2D

signal selected
signal drag_started
signal drag_ended

const GroupName: StringName = &"pieces"
const SpecialGroupName: StringName = &"special-pieces"
const ObstacleGroupName: StringName = &"obstacle-pieces"

@export_category("Visual")
@export var texture_scale: float = 0.85
@export_category("Drag&Drop")
@export var reset_position_on_drag_release: bool = true
@export var drag_smooth_factor: float = 20.0

var piece: Match3Piece
var original_z_index: int = 0

var mouse_region: Button
var current_position: Vector2 = Vector2.ZERO
var m_offset: Vector2 = Vector2.ZERO

var is_locked: bool = false
var drag_enabled: bool = false:
	set(value):
		drag_enabled = value
		
		if is_inside_tree():
			set_process(drag_enabled and not is_locked)
	
## Could be Sprite2D or AnimatedSprite2D
var sprite: Node2D


func _enter_tree() -> void:
	assert(piece != null, "Match3PieceUI: The Piece UI needs the core piece to get the information to be usable")
	
	add_to_group(GroupName)
	
	if piece.is_special():
		add_to_group(SpecialGroupName)
	elif piece.is_obstacle():
		add_to_group(ObstacleGroupName)
	
	name = "%s_%s" % [piece.id, piece.shape]
	z_index = 10
	original_z_index = z_index
	

func _ready() -> void:
	_prepare_sprite()
	
	await get_tree().process_frame
	
	_create_mouse_region_button()
	
	set_process(drag_enabled and not is_locked)


func _process(delta: float) -> void:
	if drag_enabled:
		global_position = global_position.lerp(get_global_mouse_position(), drag_smooth_factor * delta) if drag_smooth_factor > 0 else get_global_mouse_position()
		current_position = global_position + m_offset
	

func lock() -> void:
	is_locked = true


func unlock() -> void:
	is_locked = false


func enable_drag() -> void:
	drag_enabled = true
	
	
func disable_drag() -> void:
	drag_enabled = false


func calculate_texture_scale(texture: Texture2D, size: Vector2i = Vector2i(48, 48)) -> Vector2:
	var texture_size = texture.get_size()
	
	return Vector2(size.x / texture_size.x, size.y / texture_size.y) * texture_scale


func _create_mouse_region_button() -> void:
	if mouse_region == null:
		mouse_region = Button.new()
		mouse_region.self_modulate.a8 = 0 ## TODO - CHANGE TO 0 WHEN FINISH DEBUG
	
	var sprite = Match3BoardPluginUtilities.first_node_of_type(self, Sprite2D.new())
	
	if sprite == null:
		sprite = Match3BoardPluginUtilities.first_node_of_type(self, AnimatedSprite2D.new())
	
	assert(sprite != null, "Match3PieceUI: %s needs to have a Sprite2D or AnimatedSprite2D as child to create the mouse region" % name)
	
	sprite.add_child(mouse_region)
	
	mouse_region.position = Vector2.ZERO
	mouse_region.anchors_preset = Control.PRESET_FULL_RECT
	
	mouse_region.pressed.connect(on_mouse_region_pressed)
	mouse_region.button_down.connect(on_mouse_region_holded)
	mouse_region.button_up.connect(on_mouse_region_released)


func _prepare_sprite() -> void:
	sprite = Match3BoardPluginUtilities.first_node_of_type(self, Sprite2D.new())
	
	if sprite == null:
		sprite = Match3BoardPluginUtilities.first_node_of_type(self, AnimatedSprite2D.new())
	
	assert(sprite != null, "Match3PieceUI: %s needs to have a Sprite2D or AnimatedSprite2D as child to create the mouse region" % name)
	
	if sprite is Sprite2D:
		sprite.scale = calculate_texture_scale(sprite.texture)
	elif sprite is AnimatedSprite2D:
		sprite.scale = calculate_texture_scale(sprite.get_sprite_frames().get_frame(sprite.animation, sprite.get_frame()))
	

#region Overridables
func match_with(other_piece: PieceUI) -> bool:
	if other_piece.is_obstacle():
		return false
		
	return piece.equals_to(other_piece.piece)

#endregion


#region Signal callbacks
func on_mouse_region_pressed() -> void:
	if is_locked:
		return
	
	selected.emit()

func on_mouse_region_holded() -> void:
	if is_locked:
		return
		
	drag_started.emit()


func on_mouse_region_released() -> void:
	if is_locked:
		return
		
	drag_ended.emit()

#endregion
