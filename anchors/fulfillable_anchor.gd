class_name FulfillableAnchor extends Anchor

var fulfilment_position := Vector2(-1, -1) # As we work in screen space we will never get a coordinate of (-1, -1), so this is an appropriate null value

func admisses(direction: Vector2, position: Vector2) -> bool:
	var admission: bool = reckons(direction)
	if admission:
		fulfilment_position = position
	return admission
