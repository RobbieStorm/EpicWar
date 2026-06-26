extends Resource
class_name UnitData

# UnitData.gd
# Defines a unit type — stats, visuals reference, and identity.
# Shared between player and enemy units; balancing is done via separate assets.

@export var display_name: String = ""
@export var sort_order: int = 0
@export var scene: PackedScene = null  # The Pawn scene shell to instantiate

# Stats
@export var max_health: float = 100.0
@export var move_speed: float = 80.0
@export var damage: float = 10.0
@export var attack_range: float = 50.0
@export var attack_speed: float = 1.0  # Attacks per second
@export var default_advance_distance: float = 200.0
