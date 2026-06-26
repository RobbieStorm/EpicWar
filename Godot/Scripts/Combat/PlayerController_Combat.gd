extends Node2D

# PlayerController_Combat.gd
# Handles player input during combat — drag selection of pawns and camera panning.
# Child of CombatGameMode. Pulls camera and map data from parent at startup.

const BORDER_OFFSET: float = 500.0
const MINIMUM_VELOCITY: float = 0.5

@export var drag_threshold: float = 5.0
@export var camera_speed: float = 600.0
@export var camera_acceleration: float = 1800.0
@export var camera_friction: float = 1200.0
@export var camera_border_zone: float = 300.0
@export var move_spread_distance: float = 60.0

var _camera: Camera2D = null
var _border_left: float = BORDER_OFFSET
var _border_right: float = 0.0
var _camera_velocity: float = 0.0

var _drag_start_screen: Vector2 = Vector2.ZERO
var _drag_end_screen: Vector2 = Vector2.ZERO
var _is_dragging: float = false

var _canvas_layer: CanvasLayer
var _draw_node: Node2D

func _ready() -> void:
	_canvas_layer = CanvasLayer.new()
	add_child(_canvas_layer)

	_draw_node = Node2D.new()
	_draw_node.draw.connect(_on_draw_selection)
	_canvas_layer.add_child(_draw_node)

	# Pull camera and map data from parent CombatGameMode
	var gamemode := get_parent()
	if gamemode == null:
		push_warning("[PlayerController_Combat] No parent CombatGameMode found.")
		return

	_camera = get_node_or_null("../../Camera2D")
	if _camera == null:
		push_warning("[PlayerController_Combat] Camera2D not found — check scene structure.")
	else:
		_camera.position.x = _border_left
		print("[PlayerController_Combat] Camera acquired: %s, initialized at location %.1f" % [_camera.name, _camera.position.x])

	if gamemode.combat_data and gamemode.combat_data.map_data:
		_border_right = gamemode.combat_data.map_data.width - BORDER_OFFSET
		print("[PlayerController_Combat] Border right set to %.1f from map data." % _border_right)
	else:
		push_warning("[PlayerController_Combat] Could not read map width from CombatGameMode — border right defaults to 0.")

	print("[PlayerController_Combat] Ready.")


func _process(delta: float) -> void:
	_handle_camera(delta)


func _handle_camera(delta: float) -> void:
	if _camera == null:
		return

	var input_direction := Input.get_axis("Left", "Right")
	if input_direction != 0.0:
		_camera_velocity = move_toward(_camera_velocity, input_direction * camera_speed, camera_acceleration * delta)
	else:
		_camera_velocity = move_toward(_camera_velocity, 0.0, camera_friction * delta)

	# Snap to zero to avoid micro movement
	if abs(_camera_velocity) < MINIMUM_VELOCITY:
		_camera_velocity = 0.0

	if _camera_velocity == 0.0:
		return

	# Compute border resistance using smoothstep for a satisfying ease-out
	var border_factor := 1.0
	var camera_x := _camera.position.x
	if _camera_velocity < 0.0:
		var distance_to_left_border := camera_x - _border_left
		if distance_to_left_border < camera_border_zone:
			border_factor = smoothstep(0.0, camera_border_zone, distance_to_left_border)
	elif _camera_velocity > 0.0:
		var distance_to_right_border := _border_right - camera_x
		if distance_to_right_border < camera_border_zone:
			border_factor = smoothstep(0.0, camera_border_zone, distance_to_right_border)

	var previous_camera_x := _camera.position.x
	var effective_velocity := _camera_velocity * border_factor

	_camera.position.x += effective_velocity * delta
	_camera.position.x = clamp(_camera.position.x, _border_left, _border_right)

	# Only kill velocity when moving into the border, not away from it
	if _camera.position.x <= _border_left and _camera_velocity < 0.0:
		_camera_velocity = 0.0
	elif _camera.position.x >= _border_right and _camera_velocity > 0.0:
		_camera_velocity = 0.0

	#if abs(_camera.position.x - previous_camera_x) > 0.01:
	#	print("[PlayerController_Combat] Camera pos: %.1f  raw velocity: %.1f  effective velocity: %.1f" % [_camera.position.x, _camera_velocity, effective_velocity])


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button_event.pressed:
				_drag_start_screen = mouse_button_event.position
				_drag_end_screen = mouse_button_event.position
				_is_dragging = false
				print("[PlayerController_Combat] Mouse down at screen pos %s" % _drag_start_screen)
			else:
				print("[PlayerController_Combat] Mouse up. Was dragging: %s" % _is_dragging)
				_finish_selection()
				_is_dragging = false
				_draw_node.queue_redraw()
		elif mouse_button_event.button_index == MOUSE_BUTTON_RIGHT and mouse_button_event.pressed:
			_issue_move_command(mouse_button_event.position)

	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_drag_end_screen = event.position
			if not _is_dragging:
				if _drag_start_screen.distance_to(_drag_end_screen) >= drag_threshold:
					_is_dragging = true
					print("[PlayerController_Combat] Drag started.")
			_draw_node.queue_redraw()


func _finish_selection() -> void:
	var live_pawns := get_tree().get_nodes_in_group("Pawns")

	for node in live_pawns:
		var pawn := node as Pawn
		if pawn == null:
			continue
		if pawn.selection_state == Pawn.SelectionState.SELECTED:
			pawn.set_selection_state(Pawn.SelectionState.NONE)

	if not _is_dragging:
		print("[PlayerController_Combat] No drag — no selection made.")
		return

	var viewport := get_viewport()
	var canvas_transform := viewport.get_canvas_transform()
	var world_start := canvas_transform.affine_inverse() * _drag_start_screen
	var world_end := canvas_transform.affine_inverse() * _drag_end_screen
	var top_left := Vector2(min(world_start.x, world_end.x), min(world_start.y, world_end.y))
	var bottom_right := Vector2(max(world_start.x, world_end.x), max(world_start.y, world_end.y))
	var world_rect := Rect2(top_left, bottom_right - top_left)

	print("[PlayerController_Combat] Selection world rect: %s" % world_rect)

	var selected_count := 0
	for node in live_pawns:
		var pawn := node as Pawn
		if pawn == null:
			continue
		var collision_shape := pawn.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if collision_shape == null:
			push_warning("[PlayerController_Combat] Pawn %s has no CollisionShape2D." % pawn.name)
			continue
		var rectangle_shape := collision_shape.shape as RectangleShape2D
		if rectangle_shape == null:
			push_warning("[PlayerController_Combat] Pawn %s collision shape is not RectangleShape2D." % pawn.name)
			continue
		var shape_half_size := rectangle_shape.size / 2.0
		var collider_position := pawn.global_position + collision_shape.position
		var pawn_rect := Rect2(collider_position - shape_half_size, rectangle_shape.size)
		print("[PlayerController_Combat] Pawn '%s' rect: %s — intersects: %s" % [pawn.name, pawn_rect, world_rect.intersects(pawn_rect)])
		if world_rect.intersects(pawn_rect):
			pawn.set_selection_state(Pawn.SelectionState.SELECTED)
			selected_count += 1

	print("[PlayerController_Combat] %d pawn(s) selected." % selected_count)


func _issue_move_command(screen_position: Vector2) -> void:
	var canvas_transform := get_viewport().get_canvas_transform()
	var world_x := (canvas_transform.affine_inverse() * screen_position).x

	# Gather selected player pawns, sorted by current x position
	var selected_pawns: Array[Pawn] = []
	for node in get_tree().get_nodes_in_group("Pawns"):
		var pawn := node as Pawn
		if pawn == null:
			continue
		if pawn.faction == GameTypes.Faction.PLAYER and pawn.selection_state == Pawn.SelectionState.SELECTED:
			selected_pawns.append(pawn)

	if selected_pawns.is_empty():
		return

	selected_pawns.sort_custom(func(first_pawn: Pawn, second_pawn: Pawn) -> bool:
		return first_pawn.global_position.x < second_pawn.global_position.x
	)

	# Spread pawns around the target x — centred on the click
	var pawn_count := selected_pawns.size()
	for index in pawn_count:
		var offset := (index - (pawn_count - 1) / 2.0) * move_spread_distance
		selected_pawns[index].move_to(world_x + offset)

	print("[PlayerController_Combat] Move command issued to %d pawn(s) toward x: %.1f" % [pawn_count, world_x])


func _on_draw_selection() -> void:
	if not _is_dragging:
		return
	var top_left := Vector2(min(_drag_start_screen.x, _drag_end_screen.x), min(_drag_start_screen.y, _drag_end_screen.y))
	var selection_size := Vector2(abs(_drag_end_screen.x - _drag_start_screen.x), abs(_drag_end_screen.y - _drag_start_screen.y))
	var selection_rect := Rect2(top_left, selection_size)
	_draw_node.draw_rect(selection_rect, Color(0, 1, 0, 0.15), true)
	_draw_node.draw_rect(selection_rect, Color(0, 1, 0, 0.8), false, 1.5)
