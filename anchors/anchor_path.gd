class_name AnchorPath extends Resource

@export_category("Anchors")
@export var anchors: Array[FulfillableAnchor]
var anchor_index := 0
var bridge := Anchor.new()

@export_category("Sampling")
@export var sample_num: int: set = set_sample_num # Used to set the initial size of the sampling array
var samples: CircularQueue
var average_direction: Vector2

func set_sample_num(num: int):
	samples = CircularQueue.new(5)
	sample_num = num

func evaluate(direction: Vector2, position: Vector2) -> Eval.EvaluationState:
	if anchor_index == anchors.size():
		return Eval.EvaluationState.COMPLETE # Completed this anchor path
	
	samples.destructive_enqueue({"direction": direction, "position": position})
	if !samples.is_full() || anchor_index >= anchors.size():
		return Eval.EvaluationState.SAMPLING # Still approaching sample requirement
	
	var directions: Array = samples.map(func (dictionary): return dictionary.direction)
	average_direction = average(directions)
	
	if anchors[anchor_index].admisses(average_direction, samples.peek().position): # samples.peek() will always be the oldest item in the array
		anchor_index += 1
		if is_complete():
			return Eval.EvaluationState.COMPLETE
			
		update_bridge()
		return Eval.EvaluationState.SUCCESS
	else:
		if bridge:
			if bridge.reckons(average_direction):
				return Eval.EvaluationState.BRIDGING
		
		reset()
		return Eval.EvaluationState.FAILURE

func update_bridge(previous_anchor: Anchor = anchors[anchor_index - 1], new_anchor: Anchor = anchors[anchor_index]):
	var rotation_direction: int = sign(previous_anchor.entry_direction.cross(new_anchor.entry_direction))
	
	var difference_angle: float = abs(previous_anchor.entry_direction.angle_to(new_anchor.entry_direction))
	var bridge_angle: float = difference_angle + 2 * new_anchor.lenience_angle
	var rotation_angle: float = (difference_angle + new_anchor.lenience_angle) - (bridge_angle / 2)
	
	bridge.entry_direction = previous_anchor.entry_direction.rotated(rotation_angle * rotation_direction)
	bridge.lenience_angle = bridge_angle / 2

func get_last_fulfilled_position():
	return anchors[anchor_index - 1].fulfilment_position

func average(items: Array) -> Vector2:
	var sum = items.reduce(func (accumulated, item): return accumulated + item, Vector2(0,0))
	return sum / items.size()
 
func is_complete() -> bool:
	return anchor_index == anchors.size()

func reset():
	for i in range(anchor_index + 1):
		anchors[i].fulfilment_position = Vector2(-1, -1)
	anchor_index = 0
