class_name PieceUI extends Node2D

signal selected
signal unselected
signal holded
signal released
signal consumed

const GroupName: String = "piece"

## The sprite that represents a texture piece
@export var sprite: Sprite2D
## The sprite that represents an animated texture piece
@export var animated_sprite: AnimatedSprite2D
## The piece definition with all the important data about the behaviour of this piece in the board
@export var piece_definition: PieceDefinitionResource
## The size this piece will have in the board, if this value changes the sprites are prepared again to adapt the regions.
@export var cell_size: Vector2i = Vector2(48, 48):
	set(value):
		if value != cell_size:
			cell_size = value
			_prepare_sprites()
## The texture scale to fit inside a grid cell. This value is usually below 1
## so that the piece does not take up the whole cell and some margin gaps can be seen.
@export var texture_scale: float = 0.85:
	set(value):
		if value != texture_scale:
			texture_scale = value
			_prepare_sprites()
@export_group("Drag")
@export var reset_position_on_release: bool = true
@export var smooth_factor: float = 20.0


var board: Match3Board:
	set(value):
		if value != board:
			board = value
			
			if board:
				cell_size = board.cell_size
				
var mouse_region: Button
var piece_area: Area2D
var detection_area: Area2D
var is_locked: bool = false
var is_holded: bool = false:
	set(value):
		if value != is_holded and not is_locked and is_inside_tree():
			is_holded = value
			
			if is_holded:
				holded.emit()
				board.piece_holded.emit(self)
			else:
				released.emit()
				board.piece_released.emit(self)
var is_selected: bool = false:
	set(value):
		if value != is_selected and not is_locked and is_inside_tree():
			is_selected = value
			
			if is_selected:
				selected.emit()
				board.piece_selected.emit(self)
				
				if is_click_mode_drag():
					piece_area.set_deferred("monitorable", false)
					detection_area.set_deferred("monitoring", true)
			else:
				unselected.emit()
				board.piece_unselected.emit(self)
				
				if is_click_mode_drag():
					piece_area.set_deferred("monitorable", true)
					detection_area.set_deferred("monitoring", false)
		

var original_z_index: int = 0
var current_position: Vector2 = Vector2.ZERO
var m_offset: Vector2 = Vector2.ZERO
var original_global_position: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
		

func _enter_tree() -> void:
	add_to_group(GroupName)
	
	name = "%s-%s" % [piece_definition.type, piece_definition.shape.to_pascal_case()]
	is_selected = false
	z_index = 20
	original_z_index = z_index
	
	if board == null:
		board = get_tree().get_first_node_in_group(Match3Preloader.BoardGroupName)
	
	assert(board is Match3Board, "PieceUI: The piece ui needs a linked Match3Board to be functional. ")
	
	selected.connect(on_piece_selected)
	unselected.connect(on_piece_unselected)
	holded.connect(on_piece_holded)
	released.connect(on_piece_released)
	consumed.connect(on_piece_consumed)
	

func _ready() -> void:
	if sprite == null:
		sprite = Match3BoardPluginUtilities.first_node_of_type(self, Sprite2D.new())
	
	if animated_sprite == null:
		animated_sprite = Match3BoardPluginUtilities.first_node_of_type(self, AnimatedSprite2D.new())
		
	assert(sprite is Sprite2D or animated_sprite is AnimatedSprite2D, "PieceUI: needs an Sprite2D or AnimatedSprite2D defined to be used %s" % name)
	
	set_process(false)
	
	_prepare_sprites()
	prepare_area_detectors()
	_prepare_mouse_region_button()

	original_global_position = global_position
	original_position = position
	

func _process(delta: float) -> void:
	global_position = global_position.lerp(get_global_mouse_position(), smooth_factor * delta) if smooth_factor > 0 else get_global_mouse_position()
	current_position = global_position + m_offset
	

#region Active methods
func match_with(other_piece: PieceUI) -> bool:
	return piece_definition.match_with(other_piece.piece_definition)


func can_be_swapped() -> bool:
	return piece_definition.can_be_swapped


func can_be_moved() -> bool:
	return piece_definition.can_be_moved


func can_be_replaced() -> bool:
	return piece_definition.can_be_replaced


func can_be_shuffled() -> bool:
	return piece_definition.can_be_shuffled


func can_be_triggered() -> bool:
	return piece_definition.can_be_triggered


func detect_near_piece():
	var nearest_piece_area: Dictionary = Match3BoardPluginUtilities.get_nearest_node_by_distance(global_position, detection_area.get_overlapping_areas())
	
	var piece_area = nearest_piece_area.get("target", null)
	
	if piece_area is Area2D:
		return piece_area.get_parent() as PieceUI
		
	return null
	
	
func reset_position() -> void:
	if is_inside_tree() and reset_position_on_release:
		global_position = original_global_position
		position = original_position


func lock() -> void:
	is_locked = true
	is_selected = false


func unlock() -> void:
	is_locked = false
	
func is_click_mode_selection() -> bool:
	return board.is_click_mode_selection()
	

func is_click_mode_drag() -> bool:
	return board.is_click_mode_drag()
#endregion

#region Preparation methods
func _prepare_mouse_region_button() -> void:
	if mouse_region == null:
		mouse_region = Button.new()
		mouse_region.self_modulate.a8 = 100 ## TODO - CHANGE TO 0 WHEN FINISH DEBUG
	
	if sprite is Sprite2D and animated_sprite == null:
		sprite.add_child(mouse_region)
		
	elif sprite == null and animated_sprite is AnimatedSprite2D:
		animated_sprite.add_child(mouse_region)
	else:
		push_error("PieceUI: %s needs to have a sprite defined to create the mouse region" % name)
		
	mouse_region.position = Vector2.ZERO
	mouse_region.anchors_preset = Control.PRESET_FULL_RECT
	mouse_region.pressed.connect(on_mouse_region_pressed)
	mouse_region.button_down.connect(on_mouse_region_holded)
	mouse_region.button_up.connect(on_mouse_region_released)


func _prepare_sprites() -> void:
	if sprite is Sprite2D and animated_sprite == null:
		_prepare_sprite()
		
	elif sprite == null and animated_sprite is AnimatedSprite2D:
		_prepare_animated_sprite()
	else:
		push_error("PieceUI: %s needs to have a sprite defined for it to be used" % name)


func _prepare_sprite() -> void:
	if is_inside_tree() and sprite is Sprite2D:
		var texture_size = sprite.texture.get_size()
		sprite.scale = Vector2(cell_size.x / texture_size.x, cell_size.y / texture_size.y) * texture_scale
		

func _prepare_animated_sprite() -> void:
	if is_inside_tree() and animated_sprite is AnimatedSprite2D:
		var texture_size = animated_sprite.get_sprite_frames().get_frame(animated_sprite.animation, animated_sprite.get_frame())
		animated_sprite.scale = Vector2(cell_size.x / texture_size.x, cell_size.y / texture_size.y) * texture_scale


func prepare_area_detectors() -> void:
	piece_area = Area2D.new()
	piece_area.name = "PieceArea"
	var piece_area_collision = CollisionShape2D.new()
	piece_area_collision.name = "PieceAreaCollisionShape"
	var piece_area_collision_shape = RectangleShape2D.new()
	piece_area_collision.shape = piece_area_collision_shape
	piece_area.add_child(piece_area_collision)
	
	detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	var detection_area_collision = CollisionShape2D.new()
	detection_area_collision.name = "DetectionAreaCollisionShape"
	
	var detection_area_collision_shape = RectangleShape2D.new()
	detection_area_collision.shape = detection_area_collision_shape
	
	detection_area.add_child(detection_area_collision)
	
	piece_area.collision_layer = pow(2, board.pieces_collision_layer - 1)
	piece_area.collision_mask = 0
	piece_area.monitoring = false
	piece_area.monitorable = true
	
	detection_area.collision_layer = 0
	detection_area.collision_mask = piece_area.collision_layer
	detection_area.monitoring = false ## Deactivated on initialization, it will active when piece is selected
	detection_area.monitorable = false
	
	piece_area_collision.shape.size =  board.cell_size - Vector2i.ONE * (board.cell_size.x / 2)
	detection_area_collision.shape.size = board.cell_size / 2
	

	add_child(piece_area)
	add_child(detection_area)

#endregion


#region Signal callbacks
func on_mouse_region_pressed() -> void:
	if is_click_mode_selection():
		is_selected = !is_selected


func on_mouse_region_holded() -> void:
	if is_click_mode_drag():
		is_selected = true
		is_holded = true
		
		if is_inside_tree():
			z_index = original_z_index + 100
			z_as_relative = false
			m_offset = transform.origin - get_global_mouse_position()
			set_process(true)

	
func on_mouse_region_released() -> void:
	if is_click_mode_drag():
		reset_position()

		is_selected = false
		is_holded = false
		z_index = original_z_index
		z_as_relative = true
		
		set_process(false)
#endregion
	

#region Overridables
func on_piece_selected() -> void:
	pass
	
	
func on_piece_unselected() -> void:
	pass
	
	
func on_piece_holded() -> void:
	pass
	
	
func on_piece_released() -> void:
	pass
	
	
func on_piece_consumed() -> void:
	pass
#endregion
