## Unit tests for LayeredAudioEvent and AudioLayer
extends "res://tests/test_base.gd"

func run_tests():
	test("Create AudioLayer with defaults", test_create_layer)
	test("AudioLayer volume calculation", test_layer_volume)
	test("AudioLayer validation", test_layer_validation)
	test("Create LayeredAudioEvent", test_create_event)
	test("LayeredAudioEvent validation", test_event_validation)
	test("Get layer volumes at parameter value", test_get_layer_volumes)
	test("Layer crossfading behavior", test_crossfade_behavior)

func test_create_layer():
	var layer = AudioLayer.new()
	assert_not_null(layer, "Layer should be created")
	assert_equal(layer.layer_name, "Layer", "Default name should be Layer")
	assert_equal(layer.volume_offset, 0.0, "Default volume offset should be 0")
	assert_equal(layer.pitch_offset, 1.0, "Default pitch offset should be 1")
	assert_not_null(layer.fade_curve, "Fade curve should be created")

func test_layer_volume():
	var layer = AudioLayer.new()
	layer.parameter_min = 0.0
	layer.parameter_max = 100.0
	layer.volume_offset = 0.0

	# Test below range
	var vol = layer.get_volume_at_parameter(-10.0)
	assert_equal(vol, -80.0, "Volume below range should be -80dB (muted)")

	# Test above range
	vol = layer.get_volume_at_parameter(150.0)
	assert_equal(vol, -80.0, "Volume above range should be -80dB (muted)")

	# Test within range (at middle)
	vol = layer.get_volume_at_parameter(50.0)
	assert_true(vol > -80.0, "Volume within range should not be muted")

	# Test at min edge
	vol = layer.get_volume_at_parameter(0.0)
	assert_true(vol > -80.0, "Volume at min edge should not be muted")

	# Test at max edge
	vol = layer.get_volume_at_parameter(100.0)
	assert_true(vol > -80.0, "Volume at max edge should not be muted")

func test_layer_validation():
	var layer = AudioLayer.new()

	# Invalid - no stream
	assert_false(layer.is_valid(), "Layer without stream should be invalid")

	# Invalid - no name
	layer.stream = AudioStreamGenerator.new()
	layer.layer_name = ""
	assert_false(layer.is_valid(), "Layer without name should be invalid")

	# Valid
	layer.layer_name = "TestLayer"
	assert_true(layer.is_valid(), "Layer with stream and name should be valid")

func test_create_event():
	var event = LayeredAudioEvent.new()
	assert_not_null(event, "Event should be created")
	assert_equal(event.event_name, "New Layered Event", "Default name should be set")
	assert_equal(event.control_parameter, "", "Default parameter should be empty")
	assert_array_size(event.layers, 0, "Should have no layers by default")
	assert_equal(event.crossfade_time, 0.3, "Default crossfade time should be 0.3")

func test_event_validation():
	var event = LayeredAudioEvent.new()

	# Invalid - no name
	assert_false(event.is_valid(), "Event without name should be invalid")

	# Invalid - no control parameter
	event.event_name = "TestEvent"
	assert_false(event.is_valid(), "Event without control parameter should be invalid")

	# Invalid - no layers
	event.control_parameter = "test_param"
	assert_false(event.is_valid(), "Event without layers should be invalid")

	# Create valid layers
	var layer1 = AudioLayer.new()
	layer1.layer_name = "Layer1"
	layer1.stream = AudioStreamGenerator.new()
	layer1.parameter_min = 0.0
	layer1.parameter_max = 50.0

	var layer2 = AudioLayer.new()
	layer2.layer_name = "Layer2"
	layer2.stream = AudioStreamGenerator.new()
	layer2.parameter_min = 40.0
	layer2.parameter_max = 100.0

	event.layers = [layer1, layer2]

	# Valid
	assert_true(event.is_valid(), "Event with all requirements should be valid")

func test_get_layer_volumes():
	var event = LayeredAudioEvent.new()
	event.event_name = "TestEvent"
	event.control_parameter = "test"

	# Create layers with different ranges
	var layer1 = AudioLayer.new()
	layer1.layer_name = "Low"
	layer1.stream = AudioStreamGenerator.new()
	layer1.parameter_min = 0.0
	layer1.parameter_max = 40.0

	var layer2 = AudioLayer.new()
	layer2.layer_name = "Mid"
	layer2.stream = AudioStreamGenerator.new()
	layer2.parameter_min = 30.0
	layer2.parameter_max = 70.0

	var layer3 = AudioLayer.new()
	layer3.layer_name = "High"
	layer3.stream = AudioStreamGenerator.new()
	layer3.parameter_min = 60.0
	layer3.parameter_max = 100.0

	event.layers = [layer1, layer2, layer3]

	# Test at low value (0)
	var volumes = event.get_layer_volumes(0.0)
	assert_array_size(volumes, 3, "Should return volume for all layers")
	assert_true(volumes[0] > -80.0, "Layer 1 should be audible")
	assert_equal(volumes[1], -80.0, "Layer 2 should be muted")
	assert_equal(volumes[2], -80.0, "Layer 3 should be muted")

	# Test at high value (100)
	volumes = event.get_layer_volumes(100.0)
	assert_equal(volumes[0], -80.0, "Layer 1 should be muted")
	assert_equal(volumes[1], -80.0, "Layer 2 should be muted")
	assert_true(volumes[2] > -80.0, "Layer 3 should be audible")

	# Test at overlap (50)
	volumes = event.get_layer_volumes(50.0)
	# Layers 2 and 3 should be audible
	assert_equal(volumes[0], -80.0, "Layer 1 should be muted at 50")
	assert_true(volumes[1] > -80.0, "Layer 2 should be audible at 50")
	assert_true(volumes[2] > -80.0, "Layer 3 should be audible at 50")

func test_crossfade_behavior():
	var event = LayeredAudioEvent.new()
	event.event_name = "CrossfadeTest"
	event.control_parameter = "intensity"
	event.crossfade_time = 1.0

	# Create two layers that overlap
	var layer1 = AudioLayer.new()
	layer1.layer_name = "A"
	layer1.stream = AudioStreamGenerator.new()
	layer1.parameter_min = 0.0
	layer1.parameter_max = 60.0

	var layer2 = AudioLayer.new()
	layer2.layer_name = "B"
	layer2.stream = AudioStreamGenerator.new()
	layer2.parameter_min = 40.0
	layer2.parameter_max = 100.0

	event.layers = [layer1, layer2]

	# In overlap region (50), both should be audible
	var volumes = event.get_layer_volumes(50.0)
	assert_true(volumes[0] > -80.0, "Layer A should be audible in overlap")
	assert_true(volumes[1] > -80.0, "Layer B should be audible in overlap")

	# Crossfade time affects smoothness, not which layers are active
	event.crossfade_time = 0.1
	volumes = event.get_layer_volumes(50.0)
	assert_true(volumes[0] > -80.0, "Layer A still audible with fast crossfade")
	assert_true(volumes[1] > -80.0, "Layer B still audible with fast crossfade")
