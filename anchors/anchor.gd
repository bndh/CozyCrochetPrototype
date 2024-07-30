class_name Anchor extends Resource

@export_category("Anchor Properties")
@export var entry_direction: Vector2 # The direction at which teh mouse should come into the anchor
@export var lenience_angle: float # Angle of lenience concerning the enter direction in radians

func reckons(direction: Vector2) -> bool:
	return abs(direction.angle_to(entry_direction)) <= lenience_angle
