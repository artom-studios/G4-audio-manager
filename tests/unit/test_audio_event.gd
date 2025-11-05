## Unit tests for AudioEvent
extends "res://tests/test_base.gd"

func run_tests():
	test("Create event with default values", test_create_default)
	test("Event validation", test_validation)
	test("Random stream selection", test_random_stream)
	test("Sequential stream selection", test_sequential_stream)
	test("Volume randomization", test_volume_randomization)
	test("Pitch randomization", test_pitch_randomization)
	test("Cooldown system", test_cooldown)
	test("Display name", test_display_name)
	test("Playback modes", test_playback_modes)

func test_create_default():
	var event = AudioEvent.new()
	assert_not_null(event, "Event should be created")
	assert_equal(event.event_name, "New Audio Event", "Default name should be set")
	assert_equal(event.category, "Uncategorized", "Default category should be Uncategorized")
	assert_array_size(event.streams, 0, "Should have no streams by default")
	assert_equal(event.bus_name, "Master", "Default bus should be Master")
	assert_equal(event.spatial_mode, AudioEvent.SpatialMode.MODE_3D, "Default should be 3D mode")

func test_validation():
	var event = AudioEvent.new()

	# Invalid - no streams
	assert_false(event.is_valid(), "Event without streams should be invalid")

	# Create a simple audio stream for testing
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100

	# Valid - has stream and name
	event.streams = [stream]
	assert_true(event.is_valid(), "Event with stream should be valid")

	# Invalid - no name
	event.event_name = ""
	assert_false(event.is_valid(), "Event without name should be invalid")

func test_random_stream():
	var event = AudioEvent.new()
	event.playback_mode = AudioEvent.PlaybackMode.RANDOM

	# Create test streams
	var stream1 = AudioStreamGenerator.new()
	var stream2 = AudioStreamGenerator.new()
	var stream3 = AudioStreamGenerator.new()
	event.streams = [stream1, stream2, stream3]

	# Get multiple random streams
	var results = {}
	for i in range(30):
		var stream = event.get_random_stream()
		assert_not_null(stream, "Should return a stream")

		var idx = event.streams.find(stream)
		results[idx] = results.get(idx, 0) + 1

	# Check that we got variety (probabilistic test)
	assert_true(results.size() > 1, "Should return different streams randomly")

func test_sequential_stream():
	var event = AudioEvent.new()
	event.playback_mode = AudioEvent.PlaybackMode.SEQUENTIAL

	var stream1 = AudioStreamGenerator.new()
	var stream2 = AudioStreamGenerator.new()
	var stream3 = AudioStreamGenerator.new()
	event.streams = [stream1, stream2, stream3]

	# Get sequential streams
	var s1 = event.get_random_stream()
	var s2 = event.get_random_stream()
	var s3 = event.get_random_stream()
	var s4 = event.get_random_stream()  # Should wrap around

	assert_equal(s1, stream1, "First call should return first stream")
	assert_equal(s2, stream2, "Second call should return second stream")
	assert_equal(s3, stream3, "Third call should return third stream")
	assert_equal(s4, stream1, "Fourth call should wrap to first stream")

func test_volume_randomization():
	var event = AudioEvent.new()
	event.volume_min = -6.0
	event.volume_max = 0.0

	# Get multiple random volumes
	var all_in_range = true
	var has_variation = false
	var last_volume = event.get_random_volume_db()

	for i in range(20):
		var volume = event.get_random_volume_db()

		# Check range
		if volume < event.volume_min or volume > event.volume_max:
			all_in_range = false

		# Check for variation
		if not is_equal_approx(volume, last_volume):
			has_variation = true

		last_volume = volume

	assert_true(all_in_range, "All volumes should be in range")
	assert_true(has_variation, "Should have volume variation")

func test_pitch_randomization():
	var event = AudioEvent.new()
	event.pitch_min = 0.9
	event.pitch_max = 1.1

	# Get multiple random pitches
	var all_in_range = true
	var has_variation = false
	var last_pitch = event.get_random_pitch()

	for i in range(20):
		var pitch = event.get_random_pitch()

		# Check range
		if pitch < event.pitch_min or pitch > event.pitch_max:
			all_in_range = false

		# Check for variation
		if not is_equal_approx(pitch, last_pitch):
			has_variation = true

		last_pitch = pitch

	assert_true(all_in_range, "All pitches should be in range")
	assert_true(has_variation, "Should have pitch variation")

func test_cooldown():
	var event = AudioEvent.new()
	event.cooldown_time = 0.5  # 500ms cooldown

	# Should be able to play initially
	assert_true(event.can_play(), "Should be able to play initially")

	# Mark as played
	event.mark_played()

	# Should not be able to play immediately after
	assert_false(event.can_play(), "Should not be able to play during cooldown")

	# Wait for cooldown (simulate time passing)
	await get_tree().create_timer(0.6).timeout

	# Should be able to play again
	assert_true(event.can_play(), "Should be able to play after cooldown")

func test_display_name():
	var event = AudioEvent.new()

	# Test with custom name
	event.event_name = "Explosion"
	assert_equal(event.get_display_name(), "Explosion", "Should return custom name")

	# Test with empty name
	event.event_name = ""
	event.resource_path = "res://audio/test_event.tres"
	var display = event.get_display_name()
	assert_not_equal(display, "", "Should return filename when name is empty")

func test_playback_modes():
	var event = AudioEvent.new()

	# Test ONE_SHOT mode
	event.playback_mode = AudioEvent.PlaybackMode.ONE_SHOT
	assert_equal(event.playback_mode, AudioEvent.PlaybackMode.ONE_SHOT, "Should be one-shot mode")

	# Test LOOPING mode
	event.playback_mode = AudioEvent.PlaybackMode.LOOPING
	assert_equal(event.playback_mode, AudioEvent.PlaybackMode.LOOPING, "Should be looping mode")

	# Test RANDOM mode
	event.playback_mode = AudioEvent.PlaybackMode.RANDOM
	assert_equal(event.playback_mode, AudioEvent.PlaybackMode.RANDOM, "Should be random mode")

	# Test SEQUENTIAL mode
	event.playback_mode = AudioEvent.PlaybackMode.SEQUENTIAL
	assert_equal(event.playback_mode, AudioEvent.PlaybackMode.SEQUENTIAL, "Should be sequential mode")
