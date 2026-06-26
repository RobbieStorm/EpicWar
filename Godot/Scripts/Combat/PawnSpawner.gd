extends Node
class_name PawnSpawner

# PawnSpawner.gd
# Runs a timer and populates pawns up to their population cap for a CombatTeam.
# Reads deck and spawn position from its parent CombatTeam.

@export var spawn_interval: float = 2.0

var _team: CombatTeam = null
var _timer: Timer = null

func _ready() -> void:
	_team = get_parent() as CombatTeam
	if _team == null:
		push_warning("[PawnSpawner] Parent is not a CombatTeam.")
		return
	if _team.deck == null:
		push_warning("[PawnSpawner] CombatTeam has no deck assigned.")
		return

	_timer = Timer.new()
	_timer.name = "SpawnTimer"
	_timer.wait_time = spawn_interval
	_timer.autostart = true
	_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_timer)
	print("[PawnSpawner] Ready for %s team. Spawn interval: %.1fs." % [GameTypes.Faction.keys()[_team.faction], spawn_interval])


func _on_spawn_timer_timeout() -> void:
	for entry in _team.deck.entries:
		var deck_entry := entry as DeckEntry
		if deck_entry == null or deck_entry.unit_data == null:
			continue
		var live_count := _get_live_pawn_count(deck_entry.unit_data)
		if live_count < deck_entry.population_cap:
			_spawn_pawn(deck_entry)


func _get_live_pawn_count(unit_data: UnitData) -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("Pawns"):
		var pawn := node as Pawn
		if pawn == null:
			continue
		if pawn.unit_data == unit_data and pawn.faction == _team.faction:
			count += 1
	return count


func _spawn_pawn(deck_entry: DeckEntry) -> void:
	if deck_entry.unit_data.scene == null:
		push_warning("[PawnSpawner] UnitData '%s' has no scene assigned." % deck_entry.unit_data.display_name)
		return

	var pawn := deck_entry.unit_data.scene.instantiate() as Pawn
	if pawn == null:
		push_warning("[PawnSpawner] Scene for '%s' did not instantiate as a Pawn." % deck_entry.unit_data.display_name)
		return

	_team.add_child(pawn)
	pawn.global_position = _team.spawn_position
	pawn.initialize(deck_entry.unit_data, _team.faction)

	# Issue default advance from base based on faction direction
	var advance_direction := 1.0 if _team.faction == GameTypes.Faction.PLAYER else -1.0
	var advance_x := _team.spawn_position.x + advance_direction * deck_entry.unit_data.default_advance_distance
	pawn.move_to(advance_x)
	print("[PawnSpawner] Spawned '%s' for %s team. Global position: %s." % [deck_entry.unit_data.display_name, GameTypes.Faction.keys()[_team.faction], pawn.global_position])
