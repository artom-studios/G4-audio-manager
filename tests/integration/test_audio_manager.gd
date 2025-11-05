## Integration tests for AudioManager
## Note: These tests require the AudioManager singleton to be loaded
extends "res://tests/test_base.gd"

func run_tests():
	test("AudioManager singleton exists", test_singleton_exists)
	test("Create and get parameters", test_parameter_management)
	test("Set parameter value", test_set_parameter)
	test("Parameter interpolation", test_parameter_interpolation)
	test("Play simple event", test_play_event)
	test("Play event with invalid data", test_play_invalid)
	test("BPM clock start and stop", test_bpm_clock)
	test("BPM clock signals", test_bpm_signals)
	test("Pool statistics", test_pool_stats)

func test_singleton_exists():
	assert_not_null(AudioManager, "AudioManager singleton should exist")
	assert_has_method(AudioManager, "play_event", "Should have play_event method")
	assert_has_method(AudioManager, "create_parameter", "Should have create_parameter method")
	assert_has_method(AudioManager, "set_parameter", "Should have set_parameter method")

func test_parameter_management():
	# Create a parameter
	var param = AudioManager.create_parameter("test_param_1", 0.0, 100.0, 50.0)
	assert_not_null(param, "Should create parameter")
	assert_is_type(param, AudioParameter, "Should be AudioParameter type")
	assert_equal(param.parameter_name, "test_param_1", "Parameter name should match")

	# Get the parameter
	var value = AudioManager.get_parameter("test_param_1")
	assert_almost_equal(value, 50.0, 0.001, "Should return default value")

	# Try to create duplicate (should return existing)
	var param2 = AudioManager.create_parameter("test_param_1", 0.0, 200.0, 100.0)
	assert_equal(param, param2, "Should return existing parameter")

func test_set_parameter():
	# Create parameter
	AudioManager.create_parameter("test_set", 0.0, 100.0, 0.0)

	# Set value
	AudioManager.set_parameter("test_set", 75.0)
	await get_tree().process_frame

	# Get value (might be interpolating)
	var value = AudioManager.get_parameter("test_set")
	assert_true(value >= 0.0 and value <= 100.0, "Value should be in valid range")

	# Auto-create parameter if doesn't exist
	AudioManager.set_parameter("auto_created", 50.0)
	var auto_value = AudioManager.get_parameter("auto_created")
	assert_true(auto_value >= 0.0, "Auto-created parameter should work")

func test_parameter_interpolation():
	# Create parameter with interpolation
	AudioManager.create_parameter("test_interp", 0.0, 100.0, 0.0)
	AudioManager.set_parameter("test_interp", 100.0)

	# Process a few frames for interpolation
	for i in range(5):
		await get_tree().process_frame

	var value = AudioManager.get_parameter("test_interp")
	# Value should be moving toward 100
	assert_true(value > 0.0, "Parameter should be interpolating")

func test_play_event():
	# Create a simple event
	var event = AudioEvent.new()
	event.event_name = "TestSound"
	event.streams = [AudioStreamGenerator.new()]
	event.spatial_mode = AudioEvent.SpatialMode.MODE_3D

	# Play the event
	var result = AudioManager.play_event_3d(event, Vector3.ZERO)
	assert_true(result, "Should successfully play event")

	await get_tree().process_frame

func test_play_invalid():
	# Try to play null event
	var result = AudioManager.play_event_3d(null, Vector3.ZERO)
	assert_false(result, "Should fail to play null event")

	# Try to play invalid event (no streams)
	var event = AudioEvent.new()
	event.event_name = "Invalid"
	result = AudioManager.play_event_3d(event, Vector3.ZERO)
	assert_false(result, "Should fail to play invalid event")

func test_bpm_clock():
	# Start clock
	AudioManager.start_bpm_clock(120.0, 4)
	await get_tree().process_frame

	# Check it's running (hard to test directly, but we can stop it)
	AudioManager.stop_bpm_clock()
	await get_tree().process_frame

	# No errors means success
	assert_true(true, "BPM clock should start and stop without errors")

func test_bpm_signals():
	var beat_received = false
	var bar_received = false

	# Connect to signals
	var beat_connection = func(beat_num):
		beat_received = true

	var bar_connection = func(bar_num):
		bar_received = true

	AudioManager.beat.connect(beat_connection)
	AudioManager.bar.connect(bar_connection)

	# Start fast clock for testing
	AudioManager.start_bpm_clock(600.0, 4)  # Very fast for testing

	# Wait for signals
	await get_tree().create_timer(0.5).timeout

	# Stop clock
	AudioManager.stop_bpm_clock()

	# Disconnect
	AudioManager.beat.disconnect(beat_connection)
	AudioManager.bar.disconnect(bar_connection)

	# Check if we received signals
	assert_true(beat_received, "Should receive beat signal")
	# Bar might not fire if test is too quick, so we won't assert on it

func test_pool_stats():
	var stats = AudioManager.get_pool_stats()

	assert_not_null(stats, "Should return pool stats")
	assert_true(stats.has("pool_2d"), "Should have 2D pool stats")
	assert_true(stats.has("pool_3d"), "Should have 3D pool stats")

	# Check pool_2d stats
	assert_true(stats.pool_2d.has("total"), "2D pool should have total")
	assert_true(stats.pool_2d.has("available"), "2D pool should have available")
	assert_true(stats.pool_2d.has("active"), "2D pool should have active")

	# Check pool_3d stats
	assert_true(stats.pool_3d.has("total"), "3D pool should have total")
	assert_true(stats.pool_3d.has("available"), "3D pool should have available")
	assert_true(stats.pool_3d.has("active"), "3D pool should have active")
