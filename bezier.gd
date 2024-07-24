extends Node2D

@export_category("Points")
@export var p0: Vector2
@export var p1: Vector2
@export var p2: Vector2
@export var p3: Vector2

@export var pOther: Vector2

@export_category("Newton-Raphson")
@export var goal_change_delta: float = 0.001
@export var max_trials: float = 15

@export_category("Drawing")
@export var period: int = 30

var bezier_point: Vector2

var cubic_bezier_coefficients: Array[Vector2] = [] # q(t) = At^3 + Bt^2 + Ct+ D
var cb_derivative_coefficients: Array
var perpendicular_distance_coefficients: Array[float]

func _unhandled_input(event):
	pass
	#if event is InputEventMouseMotion:
		#pOther = event.position
		#bezier_point = point_to_bezier(pOther, cubic_bezier_coefficients)
		#queue_redraw()

var held_roots = [] # testing

func _draw():
	var last_point = resolvevec2(cubic_bezier_coefficients, 0.0)
	var point
	for i in range(1, period + 1):
		point = resolvevec2(cubic_bezier_coefficients, i as float / period)
		draw_line(last_point, point, Color.DEEP_PINK, 5.0)
		last_point = point
	bezier_point = point_to_bezier(pOther, cubic_bezier_coefficients)
	draw_line(pOther, bezier_point, Color.DEEP_SKY_BLUE, 5.0)
	draw_circle(pOther, 5, Color.DARK_TURQUOISE)
	
	draw_circle(resolvevec2(cubic_bezier_coefficients, 1), 5, Color.RED)
	for root in held_roots:
		draw_circle(resolvevec2(cubic_bezier_coefficients, root), 5, Color(root, root, root))
	print("Point on Curve: " + str(bezier_point))
	print("MP: " + str(pOther))

func _ready():
	cubic_bezier_coefficients.resize(4)
	cubic_bezier_coefficients[0] =   -p0 + 3*p1 - 3*p2 + p3 # A
	cubic_bezier_coefficients[1] =  3*p0 - 6*p1 + 3*p2 # B
	cubic_bezier_coefficients[2] = -3*p0 + 3*p1 # C
	cubic_bezier_coefficients[3] =    p0 # D
	
	cb_derivative_coefficients = derive(cubic_bezier_coefficients) # q'(t) = Et^2 + Ft + G
	
	perpendicular_distance_coefficients = [] # (pOther - q(t)) . q'(t) = Ht^5 + It^4 + Jt^3 + Kt^2 + Lt + M
	perpendicular_distance_coefficients.resize(6) 
	perpendicular_distance_coefficients[0] = 										 -(cb_derivative_coefficients[0].dot(cubic_bezier_coefficients[0]))
	perpendicular_distance_coefficients[1] = 										 -(cb_derivative_coefficients[0].dot(cubic_bezier_coefficients[1])) - (cb_derivative_coefficients[1].dot(cubic_bezier_coefficients[0]))
	perpendicular_distance_coefficients[2] = 										 -(cb_derivative_coefficients[0].dot(cubic_bezier_coefficients[2])) - (cb_derivative_coefficients[1].dot(cubic_bezier_coefficients[1])) - (cb_derivative_coefficients[2].dot(cubic_bezier_coefficients[0]))
	perpendicular_distance_coefficients[3] = pOther.dot(cb_derivative_coefficients[0]) - (cb_derivative_coefficients[0].dot(cubic_bezier_coefficients[3])) - (cb_derivative_coefficients[1].dot(cubic_bezier_coefficients[2])) - (cb_derivative_coefficients[2].dot(cubic_bezier_coefficients[1]))
	perpendicular_distance_coefficients[4] = pOther.dot(cb_derivative_coefficients[1]) - (cb_derivative_coefficients[1].dot(cubic_bezier_coefficients[3])) - (cb_derivative_coefficients[2].dot(cubic_bezier_coefficients[2]))
	perpendicular_distance_coefficients[5] = pOther.dot(cb_derivative_coefficients[2]) - (cb_derivative_coefficients[2].dot(cubic_bezier_coefficients[3]))


func point_to_bezier(point: Vector2, bezier_coefficients: Array[Vector2]):
	var root_intervals := isolate_roots(perpendicular_distance_coefficients, 0, 1)
	
	#print("Equation: " + equation_string(perpendicular_distance_coefficients, 5))
	#var root_intervals: Array[Array] = isolate_roots(perpendicular_distance_coefficients, 0, 1)
	#var pruned_intervals: Array[Array] = []
	#var resolved_left: float
	#var resolved_right: float
	#for root_interval in root_intervals:
		#resolved_left = resolve(perpendicular_distance_coefficients, root_interval[0], 5)
		#resolved_right = resolve(perpendicular_distance_coefficients, root_interval[1], 5)
		#if resolved_left > 0 && resolved_right < 0: # Just doing the opposite! TODO fix
			#pruned_intervals.append(root_interval)
	
	var closest_point := resolvevec2(cubic_bezier_coefficients, 0)
	var closest_distance := closest_point.distance_squared_to(pOther)
	var closest_root
	var new_point
	var point_distance
	var root
	for root_interval in root_intervals:
		root = newton_raphson(perpendicular_distance_coefficients, (root_interval[0] + root_interval[1]) / 2, 0.0001, 30)
		print("Root at: " + str(root))
		held_roots.append(root)
		new_point = resolvevec2(cubic_bezier_coefficients, root)
		point_distance = new_point.distance_squared_to(pOther)
		print("===== BEFORE =====")
		print("Closest Root: " + str(closest_root))
		print("Closest Distance: " + str(closest_distance))
		print("Closest Point: " + str(closest_point))
		if point_distance < closest_distance:
			closest_point = new_point
			closest_distance = point_distance
			closest_root = root
		print("===== AFTER =====")
		print("Closest Root: " + str(closest_root))
		print("Closest Distance: " + str(closest_distance))
		print("Closest Point: " + str(closest_point))
	new_point = resolvevec2(cubic_bezier_coefficients, 1)
	point_distance = new_point.distance_squared_to(pOther)
	if point_distance < closest_distance:
		closest_point = new_point
		closest_distance = closest_distance
		closest_root = 1
	
	print("Closest root: " + str(closest_root))
	
	return closest_point

func derive(base_coefficients: Array) -> Array:
	var derivative_coefficients := []
	derivative_coefficients.resize(base_coefficients.size() - 1)
	for i in base_coefficients.size() - 1:
		derivative_coefficients[i] = (base_coefficients.size() - 1 - i) * base_coefficients[i]
	return derivative_coefficients

func derivef(base_coefficients: Array[float]) -> Array[float]:
	var derivative_coefficients: Array[float] = []
	derivative_coefficients.resize(base_coefficients.size() - 1)
	for i in base_coefficients.size() - 1:
		derivative_coefficients[i] = (base_coefficients.size() - 1 - i) * base_coefficients[i]
	return derivative_coefficients

func resolvevec2(coefficients: Array[Vector2], value: float, degree: int = coefficients.size() - 1) -> Vector2:
	var result: Vector2 = Vector2(0, 0)
	for e in coefficients.size():
		result += coefficients[e] * pow(value, degree - e)
	return result

func resolvef(coefficients: Array[float], value: float, degree: int = coefficients.size() - 1) -> float:
	var result: float = 0
	for e in coefficients.size():
		result += coefficients[e] * pow(value, degree - e)
	return result

const signs := {-1.0: "-", 0.0: "+", 1.0: "+"}
func equation_string(coefficients: Array[float], degree: int = coefficients.size() - 1):
	var equation_string := str(coefficients[0]) + "x^" + str(degree)
	var sign_string: String
	var coefficient_string: String
	var exponent_string: String
	for e in range(1, coefficients.size()):
		sign_string = signs.get(sign(coefficients[e]))
		coefficient_string = str(coefficients[e]).substr(1) if sign_string == "-" else str(coefficients[e])
		exponent_string = "^" + str(degree - e) if degree - e > 1 else ""
		equation_string += " " + str(sign_string) + " " + str(coefficient_string) + ("x" if degree - e > 0 else "") + exponent_string
	return equation_string

func isolate_roots(coefficients: Array[float], initial_lower: float, initial_upper: float) -> Array[Array]:
	var points: Array[Array] = []
	check(coefficients, derivef(coefficients), initial_lower, initial_upper, points)
	return points

func check(coefficients: Array[float], derivative_coefficients: Array[float], lower_bound: float, upper_bound: float, points: Array[Array]):
	var roots = sturm_sequence(coefficients, derivative_coefficients, lower_bound, upper_bound)
	#print("Found " + str(roots) + " roots in (" + str(lower_bound) + ", " + str(upper_bound) + "]")
	if roots > 1:
		var mid = (lower_bound + upper_bound) / 2
		check(coefficients, derivative_coefficients, lower_bound, mid, points)
		check(coefficients, derivative_coefficients, mid, upper_bound, points)
	elif roots == 1:
		points.append([lower_bound, upper_bound])

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
	sturm_signs[0][0] = sign(resolvef(base_coefficients, lower_bound, degree))
	sturm_signs[0][1] = sign(resolvef(derivative_coefficients, lower_bound, degree - 1))
	sturm_signs[1][0] = sign(resolvef(base_coefficients, upper_bound, degree))
	sturm_signs[1][1] = sign(resolvef(derivative_coefficients, upper_bound, degree - 1))
	
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

func newton_raphson(coefficients: Array[float], initial_approximation: float, goal_change_delta: float, max_trials: int = 10, degree: int = coefficients.size() - 1) -> float:
	var derivative_coefficients := derivef(coefficients)
	var last_approximation = initial_approximation
	var current_approximation
	var temp
	var count = 0
	while(true):
		current_approximation = last_approximation - resolvef(coefficients, last_approximation, degree) / resolvef(derivative_coefficients, last_approximation, degree - 1)
		count += 1
		if abs(last_approximation - current_approximation) <= goal_change_delta || count == max_trials:
			break
		last_approximation = current_approximation
	return current_approximation
