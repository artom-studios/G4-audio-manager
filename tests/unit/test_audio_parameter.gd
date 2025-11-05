## Unit tests for AudioParameter
extends "res://tests/test_base.gd"

func run_tests():
	test("Create parameter with default values", test_create_default)
	test("Set and get parameter value", test_set_get_value)
	test("Parameter value clamping", test_value_clamping)
	test("Parameter interpolation", test_interpolation)
	test("Normalized value calculation", test_normalized_value)
	test("Parameter validation", test_validation)
	test("Parameter types", test_parameter_types)

func test_create_default():
	var param = AudioParameter.new()
	assert_not_null(param, "Parameter should be created")
	assert_equal(param.parameter_name, "", "Default name should be empty")
	assert_equal(param.min_value, 0.0, "Default min should be 0")
	assert_equal(param.max_value, 100.0, "Default max should be 100")
	assert_equal(param.default_value, 0.0, "Default value should be 0")
	assert_equal(param.current_value, 0.0, "Current value should be 0")

func test_set_get_value():
	var param = AudioParameter.new()
	param.parameter_name = "test_param"
	param.min_value = 0.0
	param.max_value = 100.0
	param.default_value = 50.0
	param.current_value = 50.0
	param.target_value = 50.0

	# Set value
	param.set_value(75.0)
	assert_equal(param.target_value, 75.0, "Target value should be set to 75")

	# Get value
	var value = param.get_value()
	assert_equal(value, param.current_value, "Get should return current value")

func test_value_clamping():
	var param = AudioParameter.new()
	param.min_value = 0.0
	param.max_value = 100.0

	# Test upper clamp
	param.set_value(150.0)
	assert_equal(param.target_value, 100.0, "Value should be clamped to max")

	# Test lower clamp
	param.set_value(-50.0)
	assert_equal(param.target_value, 0.0, "Value should be clamped to min")

	# Test within range
	param.set_value(50.0)
	assert_equal(param.target_value, 50.0, "Value within range should not be clamped")

func test_interpolation():
	var param = AudioParameter.new()
	param.parameter_name = "test"
	param.min_value = 0.0
	param.max_value = 100.0
	param.current_value = 0.0
	param.target_value = 0.0
	param.interpolation_speed = 10.0

	# Set target
	param.set_value(100.0)
	assert_equal(param.target_value, 100.0, "Target should be 100")

	# Update with small delta - should interpolate towards target
	param.update(0.1)
	assert_true(param.current_value > 0.0, "Value should have increased")
	assert_true(param.current_value < 100.0, "Value should not reach target yet")

	# Update multiple times to reach target
	for i in range(20):
		param.update(0.1)

	assert_almost_equal(param.current_value, 100.0, 0.1, "Should reach target after enough updates")

func test_normalized_value():
	var param = AudioParameter.new()
	param.min_value = 0.0
	param.max_value = 100.0
	param.current_value = 0.0

	# Test at min
	assert_almost_equal(param.get_normalized(), 0.0, 0.001, "Normalized should be 0 at min")

	# Test at middle
	param.current_value = 50.0
	assert_almost_equal(param.get_normalized(), 0.5, 0.001, "Normalized should be 0.5 at middle")

	# Test at max
	param.current_value = 100.0
	assert_almost_equal(param.get_normalized(), 1.0, 0.001, "Normalized should be 1 at max")

	# Test with different range
	param.min_value = 20.0
	param.max_value = 80.0
	param.current_value = 50.0
	assert_almost_equal(param.get_normalized(), 0.5, 0.001, "Normalized should work with any range")

func test_validation():
	var param = AudioParameter.new()

	# Invalid - no name
	param.parameter_name = ""
	assert_false(param.is_valid(), "Parameter without name should be invalid")

	# Invalid - max <= min
	param.parameter_name = "test"
	param.min_value = 100.0
	param.max_value = 0.0
	assert_false(param.is_valid(), "Parameter with max <= min should be invalid")

	# Valid
	param.min_value = 0.0
	param.max_value = 100.0
	assert_true(param.is_valid(), "Parameter with name and valid range should be valid")

func test_parameter_types():
	var param = AudioParameter.new()

	# Test continuous type (default)
	param.parameter_type = AudioParameter.ParameterType.CONTINUOUS
	assert_equal(param.parameter_type, AudioParameter.ParameterType.CONTINUOUS, "Should be continuous type")

	# Test discrete type
	param.parameter_type = AudioParameter.ParameterType.DISCRETE
	assert_equal(param.parameter_type, AudioParameter.ParameterType.DISCRETE, "Should be discrete type")

	# Test labeled type
	param.parameter_type = AudioParameter.ParameterType.LABELED
	param.labeled_values = ["Low", "Medium", "High"]
	assert_equal(param.parameter_type, AudioParameter.ParameterType.LABELED, "Should be labeled type")
	assert_array_size(param.labeled_values, 3, "Should have 3 labeled values")
