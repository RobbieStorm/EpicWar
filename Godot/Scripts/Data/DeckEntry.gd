extends Resource
class_name DeckEntry

# DeckEntry.gd
# A single slot in a deck — which unit type and how many can be on the field.

@export var unit_data: UnitData = null
@export var population_cap: int = 5
