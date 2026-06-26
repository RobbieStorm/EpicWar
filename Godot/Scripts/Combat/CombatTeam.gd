extends Node
class_name CombatTeam

# CombatTeam.gd
# Container for one side of a battle — player or enemy.
# Owns the deck, spawn position, and will eventually own the base and spawned pawns.
# Created and configured by CombatGameMode at startup.

var faction: GameTypes.Faction = GameTypes.Faction.PLAYER
var deck: DeckData = null
var spawn_position: Vector2 = Vector2.ZERO

var _spawner: PawnSpawner = null

func _ready() -> void:
	_spawner = PawnSpawner.new()
	_spawner.name = "PawnSpawner"
	add_child(_spawner)
	print("[CombatTeam] %s team ready at spawn position %s." % [GameTypes.Faction.keys()[faction], spawn_position])
