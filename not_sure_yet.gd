extends Node2D

@export_category("Path")
@export var anchor_path: AnchorPath

@export_category("Draw")
@export var rectangle_size := 10

var fulfilment_positions: Array[Vector2]

func _ready():
	pass

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var evaluation_state := anchor_path.evaluate(event.relative, event.position)
		print(evaluation_state)
		queue_redraw()

func _draw():
	for anchor in anchor_path.anchors:
		if anchor.fulfilment_position:
			draw_rect(get_rect(anchor.fulfilment_position), Color.AQUA)

func get_rect(position: Vector2):
	var half_size := rectangle_size / 2
	return Rect2(
		position.x - half_size,
		position.y - half_size,
		rectangle_size,
		rectangle_size
	)
