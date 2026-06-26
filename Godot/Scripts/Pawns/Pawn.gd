extends CharacterBody2D
class_name Pawn

# Pawn.gd
# Pure shell for all units — player-team and AI-team alike.
# Stats and identity are injected at spawn time via initialize().

enum SelectionState { NONE, SELECTED, TARGETED }

var faction: GameTypes.Faction = GameTypes.Faction.PLAYER
var selection_state: SelectionState = SelectionState.NONE

# Runtime stats — populated by initialize()
var unit_data: UnitData = null
var current_health: float = 0.0

@export var y_offset_range: float = 30.0
@export var move_target_x_variance: float = 20.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite2D

var _target_x: float = 0.0
var _is_moving: bool = false
var _sprite_initial_sprite_x: float = 0.0

const Z_SORT_SCALE: int = 10000

func _ready() -> void:
	add_to_group("Pawns")
	_sprite_initial_sprite_x = _sprite.offset.x
	print("[Pawn] '%s' ready at position %s, faction: %s." % [name, global_position, GameTypes.Faction.keys()[faction]])


func initialize(data: UnitData, pawn_faction: GameTypes.Faction) -> void:
	unit_data = data
	faction = pawn_faction
	current_health = data.max_health
	_sprite.position.y += randf_range(-y_offset_range, y_offset_range)
	print("[Pawn] '%s' initialized as '%s' faction: %s (hp: %s, speed: %s) at %s" % [name, data.display_name, GameTypes.Faction.keys()[faction], current_health, data.move_speed, global_position])


func move_to(target_x: float) -> void:
	_target_x = target_x + randf_range(-move_target_x_variance, move_target_x_variance)
	_is_moving = true
	print("[Pawn] '%s' moving to x: %.1f" % [name, _target_x])


func _process(delta: float) -> void:
	if unit_data != null:
		z_index = (unit_data.sort_order * Z_SORT_SCALE) + int(global_position.y + _sprite.position.y)

	if not _is_moving or unit_data == null:
		return

	var distance_to_target := _target_x - global_position.x
	if abs(distance_to_target) < 2.0:
		global_position.x = _target_x
		_is_moving = false
		return

	var move_delta: float = sign(distance_to_target) * unit_data.move_speed * delta
	_sprite.flip_h = distance_to_target < 0.0
	_sprite.offset.x = _sprite_initial_sprite_x * sign(distance_to_target)
	if abs(move_delta) > abs(distance_to_target):
		global_position.x = _target_x
		_is_moving = false
	else:
		global_position.x += move_delta


func set_selection_state(new_state: SelectionState) -> void:
	print("[Pawn] '%s' selection state: %s -> %s" % [name, SelectionState.keys()[selection_state], SelectionState.keys()[new_state]])
	selection_state = new_state
	queue_redraw()


func _draw() -> void:
	if selection_state == SelectionState.NONE:
		return

	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape == null:
		push_warning("[Pawn] '%s' _draw: collision shape is not RectangleShape2D." % name)
		return

	var shape_half_size := rectangle_shape.size / 2.0
	var collider_offset := collision_shape.position
	var selection_rect := Rect2(collider_offset - shape_half_size, rectangle_shape.size)

	match selection_state:
		SelectionState.SELECTED:
			draw_rect(selection_rect, Color(0, 1, 0), false, 2.0)
		SelectionState.TARGETED:
			draw_rect(selection_rect, Color(1, 0, 0), false, 2.0)
