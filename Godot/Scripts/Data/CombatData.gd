extends Resource
class_name CombatData

# CombatData.gd
# Top-level data asset for a combat encounter.
# Contains the map layout and the enemy deck.
# The player deck is managed separately via progression/meta systems.

@export var map_data: Resource = null   # MapData
@export var enemy_deck: Resource = null # DeckData
