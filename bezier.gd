extends Node

@export_category("Points")
@export var p0: Vector2
@export var p1: Vector2
@export var p2: Vector2
@export var p3: Vector2

@export var pOther: Vector2

func _ready():
	var cubic_bezier_coefficients: Array[Vector2] = [] # q(t) = At^3 + Bt^2 + Ct+ D
	cubic_bezier_coefficients.resize(4)
	cubic_bezier_coefficients[0] =   -p0 + 3*p1 - 3*p2 + p3 # A
	cubic_bezier_coefficients[1] =  3*p0 - 6*p1 + 3*p2 # B
	cubic_bezier_coefficients[2] = -3*p0 + 3*p1 # C
	cubic_bezier_coefficients[3] =    p0 # D
	
	var cb_derivative_coefficients: Array = derive(cubic_bezier_coefficients) # q'(t) = Et^2 + Ft + G
	
	var perpendicular_distance_coefficients: Array[float] = [] # (pOther - q(t)) . q'(t) = Ht^5 + It^4 + Jt^3 + Kt^2 + Lt + M
	perpendicular_distance_coefficients.resize(6) 
	perpendicular_distance_coefficients[0] = 										 -(cb_derivative_coefficients[0].dot(cubic_bezier_coefficients[0]))
	perpendicular_distance_coefficients[1] = 										 -(cb_derivative_coefficients[0].dot(cubic_bezier_coefficients[1])) - (cb_derivative_coefficients[1].dot(cubic_bezier_coefficients[0]))
	perpendicular_distance_coefficients[2] = 										 -(cb_derivative_coefficients[0].dot(cubic_bezier_coefficients[2])) - (cb_derivative_coefficients[1].dot(cubic_bezier_coefficients[1])) - (cb_derivative_coefficients[2].dot(cubic_bezier_coefficients[0]))
	perpendicular_distance_coefficients[3] = pOther.dot(cb_derivative_coefficients[0]) - (cb_derivative_coefficients[0].dot(cubic_bezier_coefficients[3])) - (cb_derivative_coefficients[1].dot(cubic_bezier_coefficients[2])) - (cb_derivative_coefficients[2].dot(cubic_bezier_coefficients[1]))
	perpendicular_distance_coefficients[4] = pOther.dot(cb_derivative_coefficients[1]) - (cb_derivative_coefficients[1].dot(cubic_bezier_coefficients[3])) - (cb_derivative_coefficients[2].dot(cubic_bezier_coefficients[2]))
	perpendicular_distance_coefficients[5] = pOther.dot(cb_derivative_coefficients[2]) - (cb_derivative_coefficients[2].dot(cubic_bezier_coefficients[3]))
	
	

func derive(base_coefficients: Array) -> Array:
	var derivative_coefficients := []
	derivative_coefficients.resize(base_coefficients.size() - 1)
	for i in base_coefficients.size() - 1:
		derivative_coefficients[i] = (base_coefficients.size() - 1 - i) * base_coefficients[i]
	return derivative_coefficients

func resolve(coefficients: Array, value: float, degree: int) -> float:
	var result := 0
	for e in coefficients.size():
		result += coefficients[e] * pow(value, coefficients.size() - 1 - e)
	return result

func sturm_sequence(base_coefficients: Array[float], lower_bound: float, upper_bound: float) -> int:
	var degree = base_coefficients.size() - 1
	var derivative_coefficients := derive(base_coefficients)
	
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
	sturm_signs[0][0] = sign(resolve(base_coefficients, lower_bound, degree))
	sturm_signs[0][1] = sign(resolve(derivative_coefficients, lower_bound, degree - 1))
	sturm_signs[1][0] = sign(resolve(base_coefficients, upper_bound, degree))
	sturm_signs[1][1] = sign(resolve(derivative_coefficients, upper_bound, degree - 1))
	
	var sturm_values: Array[float] = []
	sturm_values.resize(2)
	
	var Ti: float
	var Mi: float
	
	for i in range(2, degree + 1): # We derive the base equation until we get a constant term, which will occur after derivations equal to the degree
		Ti = calculated_as[i - 2][0] / calculated_as[i - 1][0]
		Mi = (calculated_as[i - 2][1] - Ti * calculated_as[i - 1][1]) / calculated_as[i - 1][0]
		
		for j in degree + 1 - i: # Sigma notation is inclusive so we have to + 1 to ensure consistency here
			calculated_as[i][j] = -(calculated_as[i - 2][j + 2] - Mi * calculated_as[i - 1][j + 1] - Ti * calculated_as[i - 1][j + 2])
			sturm_values[0] += calculated_as[i][j] * pow(lower_bound, degree - i - j)
			sturm_values[1] += calculated_as[i][j] * pow(upper_bound, degree - i - j)
		
		sturm_signs[0][i] = sign(resolve(sturm_values, lower_bound, degree - i))
		sturm_signs[1][i] = sign(resolve(sturm_values, upper_bound, degree - i))
	
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








