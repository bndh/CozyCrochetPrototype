class_name BezierCurve extends Resource

@export_category("Anchor Generation")
@export var default_lenience_angle: float
var anchor_path: AnchorPath

@export_category("Points")
@export var p0: Vector2: set = set_p0 # TODO Surely there is a more elegant way of doing this... SURELY...
@export var p1: Vector2: set = set_p1
@export var p2: Vector2: set = set_p2
@export var p3: Vector2: set = set_p3

@export_category("Newton-Raphson")
@export var goal_delta: float = 0.001
@export var max_trials: float = 15

var cubic_bezier_coefficients: Array[Vector2] = [] # q(t) = At^3 + Bt^2 + Ct+ D
var cb_derivative_coefficients: Array
var perpendicular_distance_coefficients: Array[float]

func _init(p0: Vector2 = Vector2(-1, -1), p1: Vector2 = Vector2(-1, -1), p2: Vector2 = Vector2(-1, -1), p3: Vector2 = Vector2(-1, -1), 
		   goal_delta: float = 0.001, max_trials: float = 15, 
		   default_lenience_angle: float = 45):
	self.p0 = p0
	self.p1 = p1
	self.p2 = p2
	self.p3 = p3
	
	self.goal_delta = goal_delta
	self.max_trials = max_trials
	
	self.default_lenience_angle = default_lenience_angle
	update_curve_coefficients()
	
func set_p0(point: Vector2):
	p0 = point
	update_curve_coefficients()
	generate_anchor_path()
func set_p1(point: Vector2):
	p1 = point
	update_curve_coefficients()
	generate_anchor_path()
func set_p2(point: Vector2):
	p2 = point
	update_curve_coefficients()
	generate_anchor_path()
func set_p3(point: Vector2):
	p3 = point
	update_curve_coefficients()
	generate_anchor_path()

func update_curve_coefficients(): # TODO Is this _really_ the best way to do this?
	cubic_bezier_coefficients.resize(4)
	cubic_bezier_coefficients[0] =   -p0 + 3*p1 - 3*p2 + p3 # A
	cubic_bezier_coefficients[1] =  3*p0 - 6*p1 + 3*p2 # B
	cubic_bezier_coefficients[2] = -3*p0 + 3*p1 # C
	cubic_bezier_coefficients[3] =    p0 # D
	
	cb_derivative_coefficients = Equation.derivevec2(cubic_bezier_coefficients) # q'(t) = Et^2 + Ft + G

func generate_anchor_path():
	var anchors: Array[FulfillableAnchor] = []
	
	var isolations := [
		func (coefficients: Array[Vector2]): return Equation.isolatevec2_x(coefficients), 
		func (coefficients: Array[Vector2]): return Equation.isolatevec2_y(coefficients)
	]
	
	var isolated_coefficients: Array
	var roots: Array[float]
	var direction: Vector2
	for i in isolations.size():
		isolated_coefficients = isolations[i].call(cb_derivative_coefficients)
		if isolated_coefficients[0] == 0:
			roots.append(Equation.solve_linear(isolated_coefficients[1], isolated_coefficients[2]))
		else:
			roots.append_array(Equation.solve_quadratic(isolated_coefficients[0], isolated_coefficients[1], isolated_coefficients[2]))
	
	roots.sort_custom(func (a, b): return a < b)
	roots = roots.filter(func (root): return root >= 0 && root <= 1)
	
	for root in roots:
		direction = Equation.resolvevec2(cb_derivative_coefficients, root) # TODO Add in a curvature modifier for the lenience angle
		anchors.append(FulfillableAnchor.new(direction, default_lenience_angle))
	
	self.anchor_path = AnchorPath.new(anchors)

func closest_point_to_bezier(pOther: Vector2, bezier_coefficients: Array[Vector2]): # TODO Implement pruning if still necessary/practical with method other than sturm
	var perpendicular_distance_coefficients: Array[float] = find_distance_coefficients(pOther)
	var root_intervals := isolate_roots(perpendicular_distance_coefficients, 0, 1)	
	return closest_point_from_intervals(pOther, root_intervals)

func find_distance_coefficients(pOther: Vector2) -> Array[float]:
	perpendicular_distance_coefficients = [] # (pOther - q(t)) . q'(t) = Ht^5 + It^4 + Jt^3 + Kt^2 + Lt + M
	perpendicular_distance_coefficients.resize(6)
	
	perpendicular_distance_coefficients[0] = 										   - (cb_derivative_coefficients[0].dot(cubic_bezier_coefficients[0]))
	perpendicular_distance_coefficients[1] = 										   - (cb_derivative_coefficients[0].dot(cubic_bezier_coefficients[1])) - (cb_derivative_coefficients[1].dot(cubic_bezier_coefficients[0]))
	perpendicular_distance_coefficients[2] = 										   - (cb_derivative_coefficients[0].dot(cubic_bezier_coefficients[2])) - (cb_derivative_coefficients[1].dot(cubic_bezier_coefficients[1])) - (cb_derivative_coefficients[2].dot(cubic_bezier_coefficients[0]))
	perpendicular_distance_coefficients[3] = pOther.dot(cb_derivative_coefficients[0]) - (cb_derivative_coefficients[0].dot(cubic_bezier_coefficients[3])) - (cb_derivative_coefficients[1].dot(cubic_bezier_coefficients[2])) - (cb_derivative_coefficients[2].dot(cubic_bezier_coefficients[1]))
	perpendicular_distance_coefficients[4] = pOther.dot(cb_derivative_coefficients[1]) - (cb_derivative_coefficients[1].dot(cubic_bezier_coefficients[3])) - (cb_derivative_coefficients[2].dot(cubic_bezier_coefficients[2]))
	perpendicular_distance_coefficients[5] = pOther.dot(cb_derivative_coefficients[2]) - (cb_derivative_coefficients[2].dot(cubic_bezier_coefficients[3]))
	
	for i in range(perpendicular_distance_coefficients.size() - 1, -1, -1): # TODO Verify if this normalisation step is necessary
		perpendicular_distance_coefficients[i] /= perpendicular_distance_coefficients[0]
		
	return perpendicular_distance_coefficients

func isolate_roots(coefficients: Array[float], initial_lower: float, initial_upper: float) -> Array[Array]:
	var points: Array[Array] = []
	check_for_roots(coefficients, Equation.derivef(coefficients), initial_lower, initial_upper, points)
	return points

func check_for_roots(coefficients: Array[float], derivative_coefficients: Array[float], lower_bound: float, upper_bound: float, points: Array[Array]):
	var roots = sturm_sequence(coefficients, derivative_coefficients, lower_bound, upper_bound)
	if roots > 1:
		var mid = (lower_bound + upper_bound) / 2
		check_for_roots(coefficients, derivative_coefficients, lower_bound, mid, points)
		check_for_roots(coefficients, derivative_coefficients, mid, upper_bound, points)
	elif roots == 1:
		points.append([lower_bound, upper_bound])

# TODO Replace with more efficient algorithm
func sturm_sequence(base_coefficients: Array[float], derivative_coefficients: Array[float], lower_bound: float, upper_bound: float) -> int:
	var degree = base_coefficients.size() - 1
	
	var calculated_as: Array[Array] = []
	calculated_as.resize(degree + 1)
	for i in degree + 1:
		calculated_as[i].resize(degree - i + 2)
		calculated_as[i][degree - i + 1] = 0 # This pre-set index exists to account for the a_j+2 call in the a_j^(i) equation
	for j in base_coefficients.size():
		calculated_as[0][j] = base_coefficients[j]
		calculated_as[1][j] = (degree - j) * base_coefficients[j]
	
	var sturm_signs := []
	sturm_signs.resize(2)
	for i in sturm_signs.size():
		sturm_signs[i] = []
	for i in 2:
		sturm_signs[i].resize(degree + 1)
	sturm_signs[0][0] = sign(Equation.resolvef(base_coefficients, lower_bound, degree))
	sturm_signs[0][1] = sign(Equation.resolvef(derivative_coefficients, lower_bound, degree - 1))
	sturm_signs[1][0] = sign(Equation.resolvef(base_coefficients, upper_bound, degree))
	sturm_signs[1][1] = sign(Equation.resolvef(derivative_coefficients, upper_bound, degree - 1))
	
	var sturm_values: Array[float] = []
	sturm_values.resize(2)
	
	var Ti: float
	var Mi: float
	
	for i in range(2, degree + 1): # We derive the base equation until we get a constant term, which will occur after derivations equal to the degree
		sturm_values.fill(0)
		Ti = calculated_as[i - 2][0] / calculated_as[i - 1][0]
		Mi = (calculated_as[i - 2][1] - Ti * calculated_as[i - 1][1]) / calculated_as[i - 1][0]
		
		for j in degree + 1 - i: # Sigma notation is inclusive so we have to + 1 to ensure consistency here
			calculated_as[i][j] = -(calculated_as[i - 2][j + 2] - Mi * calculated_as[i - 1][j + 1] - Ti * calculated_as[i - 1][j + 2])
			sturm_values[0] += calculated_as[i][j] * pow(lower_bound, degree - i - j)
			sturm_values[1] += calculated_as[i][j] * pow(upper_bound, degree - i - j)
		
		sturm_signs[0][i] = sign(sturm_values[0])
		sturm_signs[1][i] = sign(sturm_values[1])
	
	var new_sign: int
	var last_sign: int
	var sign_changes := [0, 0]
	for i in 2:
		last_sign = sturm_signs[i][0]
		for j in range(1, sturm_signs[i].size()):
			new_sign = sign(sturm_signs[i][j])
			if new_sign != last_sign && new_sign != 0:
				last_sign = new_sign
				sign_changes[i] += 1
	
	return abs(sign_changes[0] - sign_changes[1])

func newton_raphson(coefficients: Array[float], initial_approximation: float, goal_delta: float, max_trials: int = 10, degree: int = coefficients.size() - 1) -> float:
	var derivative_coefficients := Equation.derivef(coefficients)
	var last_approximation = initial_approximation
	var current_approximation
	var temp
	var count = 0
	while(true):
		current_approximation = last_approximation - Equation.resolvef(coefficients, last_approximation, degree) / Equation.resolvef(derivative_coefficients, last_approximation, degree - 1)
		count += 1
		if abs(last_approximation - current_approximation) <= goal_delta || count == max_trials:
			break
		last_approximation = current_approximation
	return current_approximation

func closest_point_from_intervals(pOther: Vector2, root_intervals: Array[Array]) -> Vector2:
	var closest_point := Equation.resolvevec2(cubic_bezier_coefficients, 0)
	var closest_distance := closest_point.distance_squared_to(pOther)
	var closest_root
	var new_point
	var point_distance
	var root
	for root_interval in root_intervals:
		root = newton_raphson(perpendicular_distance_coefficients, (root_interval[0] + root_interval[1]) / 2, 0.0001, 30)
		new_point = Equation.resolvevec2(cubic_bezier_coefficients, root)
		point_distance = new_point.distance_squared_to(pOther)
		
		if point_distance < closest_distance:
			closest_point = new_point
			closest_distance = point_distance
			closest_root = root
	
	new_point = Equation.resolvevec2(cubic_bezier_coefficients, 1)
	point_distance = new_point.distance_squared_to(pOther)
	if point_distance < closest_distance:
		closest_point = new_point
		closest_distance = closest_distance
		closest_root = 1
	
	return closest_point
