@tool
extends EditorInspectorPlugin

## Custom inspector for AudioEvent resources
## Provides enhanced editing experience for sound designers

var editor_plugin: EditorPlugin

func _can_handle(object: Object) -> bool:
	return object is AudioEvent or object is LayeredAudioEvent or object is MusicEvent or object is AudioSnapshot

func _parse_end(object: Object) -> void:
	# Add custom controls at the end of the inspector

	# Test playback section
	var test_container = VBoxContainer.new()
	test_container.add_theme_constant_override("separation", 8)

	var separator = HSeparator.new()
	test_container.add_child(separator)

	var label = Label.new()
	label.text = "Audio Testing"
	label.add_theme_font_size_override("font_size", 16)
	test_container.add_child(label)

	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 8)

	# Test button
	var test_button = Button.new()
	test_button.text = "▶ Test Playback"
	test_button.pressed.connect(_on_test_pressed.bind(object))
	button_container.add_child(test_button)

	# Stop button
	var stop_button = Button.new()
	stop_button.text = "■ Stop"
	stop_button.pressed.connect(_on_stop_pressed.bind(object))
	button_container.add_child(stop_button)

	test_container.add_child(button_container)

	# Parameter controls for layered/music events
	if object is LayeredAudioEvent or object is MusicEvent:
		var param_label = Label.new()
		param_label.text = "Parameter Control (for testing)"
		param_label.add_theme_font_size_override("font_size", 12)
		test_container.add_child(param_label)

		var param_container = HBoxContainer.new()

		var param_name_label = Label.new()
		param_name_label.text = "Value:"
		param_container.add_child(param_name_label)

		var param_slider = HSlider.new()
		param_slider.min_value = 0.0
		param_slider.max_value = 1.0
		param_slider.step = 0.01
		param_slider.value = 0.0
		param_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		param_slider.value_changed.connect(_on_param_changed.bind(object))
		param_container.add_child(param_slider)

		var param_value_label = Label.new()
		param_value_label.text = "0.00"
		param_value_label.custom_minimum_size = Vector2(50, 0)
		param_slider.value_changed.connect(func(val): param_value_label.text = "%.2f" % val)
		param_container.add_child(param_value_label)

		test_container.add_child(param_container)

	# Debug info
	var debug_button = Button.new()
	debug_button.text = "📋 Show Debug Info"
	debug_button.pressed.connect(_on_debug_pressed.bind(object))
	test_container.add_child(debug_button)

	# Validation info
	if not _validate_event(object):
		var warning_panel = PanelContainer.new()
		var warning_label = Label.new()
		warning_label.text = "⚠ Event has configuration issues - check console"
		warning_label.add_theme_color_override("font_color", Color.ORANGE)
		warning_panel.add_child(warning_label)
		test_container.add_child(warning_panel)

	add_custom_control(test_container)

func _validate_event(event: Resource) -> bool:
	if event is AudioEvent:
		return event.is_valid()
	elif event is LayeredAudioEvent:
		return event.is_valid()
	elif event is MusicEvent:
		return event.is_valid()
	elif event is AudioSnapshot:
		return event.is_valid()
	return true

func _on_test_pressed(event: Resource) -> void:
	if not Engine.is_editor_hint():
		return

	# Check if AudioController exists in editor
	if not _ensure_audio_controller():
		push_error("AudioController not found. Make sure it's registered as an autoload.")
		return

	var audio_controller = Engine.get_singleton("AudioController")
	if not audio_controller:
		# Fallback: try to get from scene tree
		var tree = Engine.get_main_loop() as SceneTree
		if tree and tree.root:
			audio_controller = tree.root.get_node_or_null("/root/AudioController")

	if not audio_controller:
		push_error("AudioController not accessible in editor")
		return

	print("🎵 Testing audio event: ", event.resource_path)

	if event is AudioEvent:
		audio_controller.play_event(event)
	elif event is LayeredAudioEvent:
		# Create parameter if it doesn't exist
		if not event.control_parameter.is_empty():
			if not audio_controller.get_parameter(event.control_parameter):
				audio_controller.create_parameter(event.control_parameter, 0.0, 1.0, 0.5)
		audio_controller.play_layered_event(event)
	elif event is MusicEvent:
		var music_manager = Engine.get_singleton("MusicManager")
		if not music_manager:
			var tree = Engine.get_main_loop() as SceneTree
			if tree and tree.root:
				music_manager = tree.root.get_node_or_null("/root/MusicManager")
		if music_manager:
			music_manager.play_music(event, 1.0)
		else:
			push_error("MusicManager not accessible in editor")
	elif event is AudioSnapshot:
		audio_controller.register_snapshot(event)
		audio_controller.apply_snapshot(event.snapshot_name, 0.5)

func _on_stop_pressed(event: Resource) -> void:
	if event is MusicEvent:
		var music_manager = Engine.get_singleton("MusicManager")
		if not music_manager:
			var tree = Engine.get_main_loop() as SceneTree
			if tree and tree.root:
				music_manager = tree.root.get_node_or_null("/root/MusicManager")
		if music_manager:
			music_manager.stop_music(0.5)

func _on_param_changed(value: float, event: Resource) -> void:
	var param_name = ""

	if event is LayeredAudioEvent:
		param_name = event.control_parameter
	elif event is MusicEvent:
		# Get first stem's parameter if available
		if event.stems.size() > 0:
			for stem in event.stems:
				if not stem.control_parameter.is_empty():
					param_name = stem.control_parameter
					break

	if param_name.is_empty():
		return

	var audio_controller = Engine.get_singleton("AudioController")
	if not audio_controller:
		var tree = Engine.get_main_loop() as SceneTree
		if tree and tree.root:
			audio_controller = tree.root.get_node_or_null("/root/AudioController")

	if audio_controller:
		if not audio_controller.get_parameter(param_name):
			audio_controller.create_parameter(param_name, 0.0, 1.0, 0.5)
		audio_controller.set_parameter(param_name, value)

func _on_debug_pressed(event: Resource) -> void:
	print("\n" + "=".repeat(60))
	if event is AudioEvent:
		print(event.get_debug_info())
	elif event is LayeredAudioEvent:
		print(event.get_debug_info())
	elif event is MusicEvent:
		print(event.get_debug_info())
	elif event is AudioSnapshot:
		print(event.get_debug_info())
	print("=".repeat(60) + "\n")

func _ensure_audio_controller() -> bool:
	# Check if autoload is registered in project settings
	var autoloads = ProjectSettings.get_setting("autoload", {})
	if autoloads is Dictionary:
		return autoloads.has("AudioController")
	return false
