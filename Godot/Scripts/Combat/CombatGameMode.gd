extends Node
class_name CombatGameMode

# CombatGameMode.gd
# Owns and coordinates all combat systems — player input, win/loss conditions,
# spawn logic, etc. Sits in the CombatMap scene as the authority on combat rules.

const LANE_VISUAL_HEIGHT: float = 40.0
const BASE_MARKER_WIDTH: float = 6.0
const BASE_MARKER_HEIGHT: float = 120.0

@export var lane_y: float = -100.0
@export var combat_data: Resource = null  # CombatData
@export var player_deck: Resource = null  # DeckData

func _ready() -> void:
	if combat_data == null:
		push_warning("[CombatGameMode] No combat_data assigned.")
		return

	_spawn_lane_visuals()
	_create_teams()
	print("[CombatGameMode] Ready. Map width: %s, Lane Y: %s" % [combat_data.map_data.width, lane_y])


func _create_teams() -> void:
	var player_team := CombatTeam.new()
	player_team.name = "PlayerTeam"
	player_team.faction = GameTypes.Faction.PLAYER
	player_team.deck = player_deck as DeckData
	player_team.spawn_position = Vector2(0.0, lane_y)
	add_child(player_team)

	var enemy_team := CombatTeam.new()
	enemy_team.name = "EnemyTeam"
	enemy_team.faction = GameTypes.Faction.ENEMY
	enemy_team.deck = combat_data.enemy_deck as DeckData
	enemy_team.spawn_position = Vector2(combat_data.map_data.enemy_base_x, lane_y)
	add_child(enemy_team)

	print("[CombatGameMode] Teams created. Player spawn: %s, Enemy spawn: %s." % [player_team.spawn_position, enemy_team.spawn_position])


func _spawn_lane_visuals() -> void:
	var map_width: float = combat_data.map_data.width
	var enemy_base_x: float = combat_data.map_data.enemy_base_x

	# Lane band
	_spawn_box(
		Vector2(map_width / 2.0, lane_y),
		Vector2(map_width, LANE_VISUAL_HEIGHT),
		Color(0.2, 0.8, 0.2, 0.15),
		"LaneBand"
	)

	# Player base marker (always at x = 0)
	_spawn_box(
		Vector2(0.0, lane_y),
		Vector2(BASE_MARKER_WIDTH, BASE_MARKER_HEIGHT),
		Color(0.2, 0.4, 1.0, 0.8),
		"PlayerBaseMarker"
	)

	# Enemy base marker
	_spawn_box(
		Vector2(enemy_base_x, lane_y),
		Vector2(BASE_MARKER_WIDTH, BASE_MARKER_HEIGHT),
		Color(1.0, 0.2, 0.2, 0.8),
		"EnemyBaseMarker"
	)


func _spawn_box(center: Vector2, size: Vector2, color: Color, box_name: String) -> void:
	var half: Vector2 = size / 2.0
	var polygon: Polygon2D = Polygon2D.new()
	polygon.name = box_name
	polygon.color = color
	polygon.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2( half.x, -half.y),
		Vector2( half.x,  half.y),
		Vector2(-half.x,  half.y),
	])
	polygon.position = center
	get_parent().add_child.call_deferred(polygon)
	print("[CombatGameMode] Spawned visual box '%s' at %s size %s" % [box_name, center, size])
