class_name Equation

static func derive(base_coefficients: Array) -> Array:
	var derivative_coefficients := []
	derivative_coefficients.resize(base_coefficients.size() - 1)
	for i in base_coefficients.size() - 1:
		derivative_coefficients[i] = (base_coefficients.size() - 1 - i) * base_coefficients[i]
	return derivative_coefficients

static func derivef(base_coefficients: Array[float]) -> Array[float]:
	var derivative_coefficients: Array[float] = []
	derivative_coefficients.resize(base_coefficients.size() - 1)
	for i in base_coefficients.size() - 1:
		derivative_coefficients[i] = (base_coefficients.size() - 1 - i) * base_coefficients[i]
	return derivative_coefficients

static func derivevec2(base_coefficients: Array[Vector2]) -> Array[Vector2]:
	var derivative_coefficients: Array[Vector2] = []
	derivative_coefficients.resize(base_coefficients.size() - 1)
	for i in base_coefficients.size() - 1:
		derivative_coefficients[i] = (base_coefficients.size() - 1 - i) * base_coefficients[i]
	return derivative_coefficients

static func resolvef(coefficients: Array[float], value: float, degree: int = coefficients.size() - 1) -> float:
	var result: float = 0
	for e in coefficients.size():
		result += coefficients[e] * pow(value, degree - e)
	return result

static func resolvevec2(coefficients: Array[Vector2], value: float, degree: int = coefficients.size() - 1) -> Vector2:
	var result: Vector2 = Vector2(0, 0)
	for e in coefficients.size():
		result += coefficients[e] * pow(value, degree - e)
	return result

static func isolatevec2_x(coefficients: Array[Vector2]) -> Array:
	return coefficients.map(func (vector_coefficient): return vector_coefficient.x)

static func isolatevec2_y(coefficients: Array[Vector2]) -> Array:
	return coefficients.map(func (vector_coefficient): return vector_coefficient.y)

static func solve_quadratic(a: float, b: float, c: float) -> Array[float]:
	var solutions: Array[float] = []
	
	var discriminant: float
	for i in range(-1, 2, 2):
		discriminant = (b*b) - (4 * a * c)
		if discriminant >= 0:
			solutions.append((-b + i * sqrt(discriminant)) / (2 * a))
	
	return solutions

static func solve_linear(m: float, c: float) -> float:
	return -c / m

const signs := {-1.0: "-", 0.0: "+", 1.0: "+"}
static func equation_string(coefficients: Array, degree: int = coefficients.size() - 1) -> String:
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
