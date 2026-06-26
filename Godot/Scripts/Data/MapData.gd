extends Resource
class_name MapData

# MapData.gd
# Data describing the combat map layout.
# Player base is always at Vector2(0, lane_y) — lane_y lives in CombatGameMode.
# Enemy base x position is stored here since it can vary per map.

@export var width: float = 2000.0
@export var enemy_base_x: float = 2000.0
