## Unit tests for MusicEvent and MusicStem
extends "res://tests/test_base.gd"

func run_tests():
	test("Create MusicStem with defaults", test_create_stem)
	test("MusicStem validation", test_stem_validation)
	test("MusicStem parameter control", test_stem_parameter_control)
	test("Create MusicEvent", test_create_event)
	test("MusicEvent validation", test_event_validation)
	test("Beat and bar duration calculation", test_duration_calculation)
	test("BPM variations", test_bpm_variations)
	test("Transition types", test_transition_types)

func test_create_stem():
	var stem = MusicStem.new()
	assert_not_null(stem, "Stem should be created")
	assert_equal(stem.stem_name, "Stem", "Default name should be Stem")
	assert_equal(stem.volume_offset, 0.0, "Default volume should be 0")
	assert_true(stem.default_enabled, "Should be enabled by default")
	assert_false(stem.controlled_by_parameter, "Should not be parameter-controlled by default")

func test_stem_validation():
	var stem = MusicStem.new()

	# Invalid - no stream
	assert_false(stem.is_valid(), "Stem without stream should be invalid")

	# Invalid - no name
	stem.stream = AudioStreamGenerator.new()
	stem.stem_name = ""
	assert_false(stem.is_valid(), "Stem without name should be invalid")

	# Valid
	stem.stem_name = "TestStem"
	assert_true(stem.is_valid(), "Stem with stream and name should be valid")

func test_stem_parameter_control():
	var stem = MusicStem.new()
	stem.stem_name = "IntensityStem"
	stem.stream = AudioStreamGenerator.new()
	stem.controlled_by_parameter = true
	stem.control_parameter = "intensity"
	stem.parameter_threshold = 0.5

	# Test below threshold
	assert_false(stem.should_be_enabled(0.3), "Should be disabled below threshold")

	# Test at threshold
	assert_true(stem.should_be_enabled(0.5), "Should be enabled at threshold")

	# Test above threshold
	assert_true(stem.should_be_enabled(0.8), "Should be enabled above threshold")

	# Test not parameter-controlled (should use default)
	stem.controlled_by_parameter = false
	stem.default_enabled = true
	assert_true(stem.should_be_enabled(0.0), "Should use default when not parameter-controlled")

	stem.default_enabled = false
	assert_false(stem.should_be_enabled(1.0), "Should use default when not parameter-controlled")

func test_create_event():
	var event = MusicEvent.new()
	assert_not_null(event, "Event should be created")
	assert_equal(event.music_name, "New Music", "Default name should be set")
	assert_equal(event.bpm, 120.0, "Default BPM should be 120")
	assert_equal(event.beats_per_bar, 4, "Default beats per bar should be 4")
	assert_array_size(event.stems, 0, "Should have no stems by default")
	assert_true(event.loop_enabled, "Looping should be enabled by default")

func test_event_validation():
	var event = MusicEvent.new()

	# Invalid - no name
	assert_false(event.is_valid(), "Event without name should be invalid")

	# Invalid - no stems
	event.music_name = "TestMusic"
	assert_false(event.is_valid(), "Event without stems should be invalid")

	# Invalid - BPM <= 0
	event.bpm = 0.0
	var stem = MusicStem.new()
	stem.stem_name = "TestStem"
	stem.stream = AudioStreamGenerator.new()
	event.stems = [stem]
	assert_false(event.is_valid(), "Event with BPM <= 0 should be invalid")

	# Valid
	event.bpm = 140.0
	assert_true(event.is_valid(), "Event with name, stems, and valid BPM should be valid")

func test_duration_calculation():
	var event = MusicEvent.new()

	# Test at 60 BPM (1 beat per second)
	event.bpm = 60.0
	assert_almost_equal(event.get_beat_duration(), 1.0, 0.001, "At 60 BPM, beat duration should be 1 second")

	# Test at 120 BPM (2 beats per second)
	event.bpm = 120.0
	assert_almost_equal(event.get_beat_duration(), 0.5, 0.001, "At 120 BPM, beat duration should be 0.5 seconds")

	# Test bar duration
	event.beats_per_bar = 4
	assert_almost_equal(event.get_bar_duration(), 2.0, 0.001, "Bar duration should be 4 beats = 2 seconds at 120 BPM")

	# Test with different time signature
	event.beats_per_bar = 3
	assert_almost_equal(event.get_bar_duration(), 1.5, 0.001, "Bar duration should be 3 beats = 1.5 seconds")

func test_bpm_variations():
	var event = MusicEvent.new()

	# Test low BPM
	event.bpm = 30.0
	assert_almost_equal(event.get_beat_duration(), 2.0, 0.001, "Low BPM (30) should give 2 second beats")

	# Test high BPM
	event.bpm = 240.0
	assert_almost_equal(event.get_beat_duration(), 0.25, 0.001, "High BPM (240) should give 0.25 second beats")

	# Test common BPMs
	event.bpm = 90.0
	assert_almost_equal(event.get_beat_duration(), 0.666666, 0.01, "90 BPM calculation")

	event.bpm = 140.0
	assert_almost_equal(event.get_beat_duration(), 0.428571, 0.01, "140 BPM calculation")

func test_transition_types():
	var event = MusicEvent.new()

	# Test IMMEDIATE transition
	event.default_transition = MusicEvent.TransitionType.IMMEDIATE
	assert_equal(event.default_transition, MusicEvent.TransitionType.IMMEDIATE, "Should be immediate transition")

	# Test BEAT_SYNC transition
	event.default_transition = MusicEvent.TransitionType.BEAT_SYNC
	assert_equal(event.default_transition, MusicEvent.TransitionType.BEAT_SYNC, "Should be beat sync transition")

	# Test BAR_SYNC transition
	event.default_transition = MusicEvent.TransitionType.BAR_SYNC
	assert_equal(event.default_transition, MusicEvent.TransitionType.BAR_SYNC, "Should be bar sync transition")

	# Test CROSSFADE transition
	event.default_transition = MusicEvent.TransitionType.CROSSFADE
	assert_equal(event.default_transition, MusicEvent.TransitionType.CROSSFADE, "Should be crossfade transition")

	# Test crossfade duration
	event.crossfade_duration = 8.0
	assert_equal(event.crossfade_duration, 8.0, "Crossfade duration should be 8 beats")
