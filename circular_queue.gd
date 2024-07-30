class_name CircularQueue

var queue: Array = []
var front_index := -1
var rear_index := -1

func _init(size: int):
	queue.resize(size)

func enqueue(item: Variant) -> bool:
	if is_full():
		return false # Failure; no space
	elif is_empty():
		front_index = increment_cyclically(front_index, max_size())
	rear_index = increment_cyclically(rear_index, max_size())
	queue[rear_index] = item
	return true

func destructive_enqueue(item: Variant) -> bool:
	if is_full() || is_empty():
		front_index = increment_cyclically(front_index, max_size())
	rear_index = increment_cyclically(rear_index, max_size())
	queue[rear_index] = item
	return is_full() # Destructive removal occurred in this case

func pop_front() -> Variant:
	if is_empty():
		return null
	var item = queue[front_index]
	if front_index == rear_index:
			front_index = increment_cyclically(front_index, max_size())
	else:
		front_index = -1
		rear_index = -1
	return item

func dequeue() -> bool:
	return pop_front() != null

func reset():
	front_index = -1
	rear_index = -1

func map(callable: Callable) -> Array:
	var altered_array := []
	altered_array.resize(size())
	
	var index: int
	var altered_item: Variant
	for i in range(front_index, front_index + size()):
		index = i % max_size()
		altered_item = callable.call(queue[index])
		altered_array[i - front_index] = altered_item
	
	return altered_array

func peek() -> Variant:
	return queue[front_index]

func size() -> int:
	if front_index == -1:
		return 0
	
	if front_index <= rear_index:
		return rear_index - front_index + 1
	else:
		return (queue.size() - front_index) + (rear_index - 1) 

func max_size() -> int:
	return queue.size()

func is_full() -> bool:
	return increment_cyclically(rear_index, max_size()) == front_index

func is_empty() -> bool:
	return front_index == -1

func increment_cyclically(i: int, max: int) -> int:
	return (i + 1) % max

func decrement_cyclically(i: int, max: int) -> int:
	return mod_negative(i - 1, max)

func mod_negative(num: int, max: int) -> int:
	return ((num % max) + max) % max
