## Integration tests for MusicManager
## Note: These tests require the MusicManager singleton to be loaded
extends "res://tests/test_base.gd"

func run_tests():
	test("MusicManager singleton exists", test_singleton_exists)
	test("Play music event", test_play_music)
	test("Stop music", test_stop_music)
	test("Music signals", test_music_signals)
	test("Stem control", test_stem_control)
	test("Query current music state", test_query_state)

func test_singleton_exists():
	assert_not_null(MusicManager, "MusicManager singleton should exist")
	assert_has_method(MusicManager, "play_music", "Should have play_music method")
	assert_has_method(MusicManager, "stop_music", "Should have stop_music method")
	assert_has_method(MusicManager, "set_stem_enabled", "Should have set_stem_enabled method")

func test_play_music():
	# Create a simple music event
	var music = MusicEvent.new()
	music.music_name = "TestMusic"
	music.bpm = 120.0
	music.beats_per_bar = 4

	# Create stems
	var stem1 = MusicStem.new()
	stem1.stem_name = "Drums"
	stem1.stream = AudioStreamGenerator.new()
	stem1.default_enabled = true

	var stem2 = MusicStem.new()
	stem2.stem_name = "Bass"
	stem2.stream = AudioStreamGenerator.new()
	stem2.default_enabled = true

	music.stems = [stem1, stem2]

	# Play music
	var result = MusicManager.play_music(music)
	assert_true(result, "Should successfully play music")

	await get_tree().process_frame

	# Clean up
	MusicManager.stop_music(0.0)
	await get_tree().process_frame

func test_stop_music():
	# Create and play music
	var music = MusicEvent.new()
	music.music_name = "StopTest"
	music.bpm = 120.0

	var stem = MusicStem.new()
	stem.stem_name = "Test"
	stem.stream = AudioStreamGenerator.new()
	music.stems = [stem]

	MusicManager.play_music(music)
	await get_tree().process_frame

	assert_true(MusicManager.is_playing(), "Music should be playing")

	# Stop music
	MusicManager.stop_music(0.0)
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for cleanup

	assert_false(MusicManager.is_playing(), "Music should be stopped")

func test_music_signals():
	var music_started_received = false
	var music_stopped_received = false
	var started_name = ""
	var stopped_name = ""

	# Connect to signals
	var start_connection = func(name):
		music_started_received = true
		started_name = name

	var stop_connection = func(name):
		music_stopped_received = true
		stopped_name = name

	MusicManager.music_started.connect(start_connection)
	MusicManager.music_stopped.connect(stop_connection)

	# Create and play music
	var music = MusicEvent.new()
	music.music_name = "SignalTest"
	music.bpm = 120.0

	var stem = MusicStem.new()
	stem.stem_name = "Test"
	stem.stream = AudioStreamGenerator.new()
	music.stems = [stem]

	MusicManager.play_music(music)
	await get_tree().process_frame

	assert_true(music_started_received, "Should receive music_started signal")
	assert_equal(started_name, "SignalTest", "Signal should pass correct name")

	# Stop music
	MusicManager.stop_music(0.0)
	await get_tree().process_frame
	await get_tree().process_frame

	assert_true(music_stopped_received, "Should receive music_stopped signal")
	assert_equal(stopped_name, "SignalTest", "Signal should pass correct name")

	# Disconnect
	MusicManager.music_started.disconnect(start_connection)
	MusicManager.music_stopped.disconnect(stop_connection)

func test_stem_control():
	# Create music with multiple stems
	var music = MusicEvent.new()
	music.music_name = "StemTest"
	music.bpm = 120.0

	var stem1 = MusicStem.new()
	stem1.stem_name = "Always"
	stem1.stream = AudioStreamGenerator.new()
	stem1.default_enabled = true

	var stem2 = MusicStem.new()
	stem2.stem_name = "Toggle"
	stem2.stream = AudioStreamGenerator.new()
	stem2.default_enabled = false

	music.stems = [stem1, stem2]

	# Play music
	MusicManager.play_music(music)
	await get_tree().process_frame

	# Enable stem
	MusicManager.set_stem_enabled("Toggle", true, 0.0)
	await get_tree().process_frame

	# Disable stem
	MusicManager.set_stem_enabled("Toggle", false, 0.0)
	await get_tree().process_frame

	# Try invalid stem (should not crash)
	MusicManager.set_stem_enabled("NonExistent", true, 0.0)
	await get_tree().process_frame

	# Clean up
	MusicManager.stop_music(0.0)
	await get_tree().process_frame
	await get_tree().process_frame

	assert_true(true, "Stem control should work without errors")

func test_query_state():
	# Initially not playing
	assert_false(MusicManager.is_playing(), "Should not be playing initially")
	assert_equal(MusicManager.get_current_music_name(), "", "Should have no current music")

	# Create and play music
	var music = MusicEvent.new()
	music.music_name = "QueryTest"
	music.bpm = 120.0

	var stem = MusicStem.new()
	stem.stem_name = "Test"
	stem.stream = AudioStreamGenerator.new()
	music.stems = [stem]

	MusicManager.play_music(music)
	await get_tree().process_frame

	# Query state
	assert_true(MusicManager.is_playing(), "Should be playing")
	assert_equal(MusicManager.get_current_music_name(), "QueryTest", "Should return current music name")

	var beat = MusicManager.get_current_beat()
	var bar = MusicManager.get_current_bar()
	assert_true(beat >= 0, "Beat should be non-negative")
	assert_true(bar >= 0, "Bar should be non-negative")

	# Clean up
	MusicManager.stop_music(0.0)
	await get_tree().process_frame
	await get_tree().process_frame

	assert_false(MusicManager.is_playing(), "Should not be playing after stop")
