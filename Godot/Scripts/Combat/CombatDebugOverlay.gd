extends Node2D

# CombatDebugOverlay.gd
# Draws a visual representation of the combat lane, player base, and enemy base.
# Reads lane_y and combat_data from its parent CombatGameMode.

const LANE_VISUAL_HEIGHT: float = 40.0
const LANE_COLOR: Color = Color(0.2, 0.8, 0.2, 0.15)
const LANE_BORDER_COLOR: Color = Color(0.2, 0.8, 0.2, 0.6)
const PLAYER_BASE_COLOR: Color = Color(0.2, 0.4, 1.0, 0.8)
const ENEMY_BASE_COLOR: Color = Color(1.0, 0.2, 0.2, 0.8)
const BASE_MARKER_HEIGHT: float = 120.0
const BASE_MARKER_WIDTH: float = 4.0

func _draw() -> void:
	var gamemode := get_parent()
	if gamemode == null:
		return
	var combat_data: Resource = gamemode.combat_data
	if combat_data == null or combat_data.map_data == null:
		push_warning("[CombatDebugOverlay] No combat_data or map_data assigned.")
		return

	var lane_y: float = gamemode.lane_y
	var map_width: float = combat_data.map_data.width
	var enemy_base_x: float = combat_data.map_data.enemy_base_x

	# Draw lane band
	var lane_rect := Rect2(
		Vector2(0.0, lane_y - LANE_VISUAL_HEIGHT / 2.0),
		Vector2(map_width, LANE_VISUAL_HEIGHT)
	)
	draw_rect(lane_rect, LANE_COLOR, true)
	draw_rect(lane_rect, LANE_BORDER_COLOR, false, 1.5)

	# Draw player base marker (x=0)
	var player_base_rect := Rect2(
		Vector2(-BASE_MARKER_WIDTH / 2.0, lane_y - BASE_MARKER_HEIGHT / 2.0),
		Vector2(BASE_MARKER_WIDTH, BASE_MARKER_HEIGHT)
	)
	draw_rect(player_base_rect, PLAYER_BASE_COLOR, true)

	# Draw enemy base marker
	var enemy_base_rect := Rect2(
		Vector2(enemy_base_x - BASE_MARKER_WIDTH / 2.0, lane_y - BASE_MARKER_HEIGHT / 2.0),
		Vector2(BASE_MARKER_WIDTH, BASE_MARKER_HEIGHT)
	)
	draw_rect(enemy_base_rect, ENEMY_BASE_COLOR, true)
