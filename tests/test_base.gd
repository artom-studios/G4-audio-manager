## TestBase - Base class for all unit tests
## Provides assertion methods and test management
extends Node

var tests_passed: int = 0
var tests_failed: int = 0
var current_test_name: String = ""

## Test results
var test_results: Array[Dictionary] = []

func _ready():
	print("\n" + "=".repeat(60))
	print("Running Tests: %s" % get_script().resource_path.get_file())
	print("=".repeat(60))

	run_tests()

	print_results()

## Override this in child classes to run specific tests
func run_tests():
	pass

## Run a single test
func test(test_name: String, test_func: Callable):
	current_test_name = test_name
	print("\n[TEST] %s" % test_name)

	var result = {
		"name": test_name,
		"passed": true,
		"errors": []
	}

	test_func.call()

	if result.passed:
		tests_passed += 1
		print("  ✓ PASSED")

	test_results.append(result)

## Assertions
func assert_true(condition: bool, message: String = ""):
	if not condition:
		fail("Expected true, got false. %s" % message)

func assert_false(condition: bool, message: String = ""):
	if condition:
		fail("Expected false, got true. %s" % message)

func assert_equal(actual, expected, message: String = ""):
	if actual != expected:
		fail("Expected %s, got %s. %s" % [expected, actual, message])

func assert_not_equal(actual, expected, message: String = ""):
	if actual == expected:
		fail("Expected values to be different, both are %s. %s" % [actual, message])

func assert_null(value, message: String = ""):
	if value != null:
		fail("Expected null, got %s. %s" % [value, message])

func assert_not_null(value, message: String = ""):
	if value == null:
		fail("Expected non-null value. %s" % message)

func assert_almost_equal(actual: float, expected: float, epsilon: float = 0.001, message: String = ""):
	if abs(actual - expected) > epsilon:
		fail("Expected ~%s, got %s (epsilon: %s). %s" % [expected, actual, epsilon, message])

func assert_in_range(value: float, min_val: float, max_val: float, message: String = ""):
	if value < min_val or value > max_val:
		fail("Expected value in range [%s, %s], got %s. %s" % [min_val, max_val, value, message])

func assert_is_type(value, expected_type, message: String = ""):
	if not is_instance_of(value, expected_type):
		fail("Expected type %s, got %s. %s" % [expected_type, type_string(typeof(value)), message])

func assert_has_method(object: Object, method_name: String, message: String = ""):
	if not object.has_method(method_name):
		fail("Object does not have method '%s'. %s" % [method_name, message])

func assert_array_size(array: Array, expected_size: int, message: String = ""):
	if array.size() != expected_size:
		fail("Expected array size %s, got %s. %s" % [expected_size, array.size(), message])

## Mark test as failed
func fail(message: String):
	tests_failed += 1
	print("  ✗ FAILED: %s" % message)

	# Find current test result and mark it as failed
	for result in test_results:
		if result.name == current_test_name:
			result.passed = false
			result.errors.append(message)
			break

## Print final results
func print_results():
	print("\n" + "=".repeat(60))
	print("Test Results")
	print("=".repeat(60))
	print("Passed: %d" % tests_passed)
	print("Failed: %d" % tests_failed)
	print("Total:  %d" % (tests_passed + tests_failed))

	if tests_failed > 0:
		print("\nFailed Tests:")
		for result in test_results:
			if not result.passed:
				print("  - %s" % result.name)
				for error in result.errors:
					print("    • %s" % error)

	print("=".repeat(60))

	if tests_failed == 0:
		print("✓ ALL TESTS PASSED!")
	else:
		print("✗ SOME TESTS FAILED")

	print("=".repeat(60) + "\n")

## Get summary for test runner
func get_summary() -> Dictionary:
	return {
		"test_class": get_script().resource_path.get_file(),
		"passed": tests_passed,
		"failed": tests_failed,
		"total": tests_passed + tests_failed,
		"results": test_results
	}
