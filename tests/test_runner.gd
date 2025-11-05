## TestRunner - Runs all unit and integration tests
extends Node

## Test files to run
var test_files: Array[String] = [
	# Unit tests
	"res://tests/unit/test_audio_parameter.gd",
	"res://tests/unit/test_audio_event.gd",
	"res://tests/unit/test_layered_audio_event.gd",
	"res://tests/unit/test_music_event.gd",
	"res://tests/unit/test_audio_pool.gd",

	# Integration tests (require singletons)
	"res://tests/integration/test_audio_manager.gd",
	"res://tests/integration/test_music_manager.gd",
]

var all_results: Array[Dictionary] = []
var total_passed: int = 0
var total_failed: int = 0
var current_test_index: int = 0

func _ready():
	print("\n" + "=".repeat(70))
	print("G4 AUDIO SYSTEM - TEST SUITE")
	print("=".repeat(70))
	print("Running %d test suites...\n" % test_files.size())

	run_next_test()

func run_next_test():
	if current_test_index >= test_files.size():
		print_final_results()
		get_tree().quit()
		return

	var test_path = test_files[current_test_index]
	print("\n" + "-".repeat(70))
	print("Loading: %s" % test_path.get_file())
	print("-".repeat(70))

	# Load and instantiate test
	var test_script = load(test_path)
	if test_script:
		var test_instance = test_script.new()
		add_child(test_instance)

		# Wait for test to complete
		await get_tree().create_timer(0.1).timeout

		# Collect results
		var summary = test_instance.get_summary()
		all_results.append(summary)
		total_passed += summary.passed
		total_failed += summary.failed

		# Clean up
		test_instance.queue_free()

		# Wait a bit before next test
		await get_tree().create_timer(0.2).timeout
	else:
		print("ERROR: Could not load test file: %s" % test_path)

	current_test_index += 1
	run_next_test()

func print_final_results():
	print("\n" + "=".repeat(70))
	print("FINAL TEST RESULTS")
	print("=".repeat(70))

	# Print summary by test file
	for result in all_results:
		var status_icon = "✓" if result.failed == 0 else "✗"
		print("%s %s - Passed: %d, Failed: %d" % [
			status_icon,
			result.test_class,
			result.passed,
			result.failed
		])

	print("-".repeat(70))
	print("Total Passed: %d" % total_passed)
	print("Total Failed: %d" % total_failed)
	print("Total Tests:  %d" % (total_passed + total_failed))

	if total_failed > 0:
		print("\n" + "!".repeat(70))
		print("FAILED TESTS:")
		for result in all_results:
			if result.failed > 0:
				print("\n%s:" % result.test_class)
				for test_result in result.results:
					if not test_result.passed:
						print("  ✗ %s" % test_result.name)
						for error in test_result.errors:
							print("    - %s" % error)
		print("!".repeat(70))

	print("\n" + "=".repeat(70))
	if total_failed == 0:
		print("✓✓✓ ALL TESTS PASSED! ✓✓✓")
	else:
		print("✗✗✗ %d TEST(S) FAILED ✗✗✗" % total_failed)
	print("=".repeat(70) + "\n")

	# Return exit code
	if total_failed > 0:
		OS.exit_code = 1
	else:
		OS.exit_code = 0
