@tool
extends Control

## Audio Mixer UI V2 - Complete standalone audio editor
## Professional workflow: Create, Edit, Test, Save - all in one place

var editor_plugin: EditorPlugin = null
var current_event: Resource = null
var current_event_path: String = ""
var is_playing: bool = false
var param_sliders: Dictionary = {}  # param_name -> {slider, label, value_label}

# Node references
@onready var event_tree: Tree = $MarginContainer/MainContainer/LeftPanel/EventTree
@onready var search_bar: LineEdit = $MarginContainer/MainContainer/LeftPanel/Header/VBox/SearchContainer/SearchBar
@onready var new_event_button: MenuButton = $MarginContainer/MainContainer/LeftPanel/Header/VBox/Toolbar/NewEventButton
@onready var delete_button: Button = $MarginContainer/MainContainer/LeftPanel/Header/VBox/Toolbar/DeleteButton
@onready var refresh_button: Button = $MarginContainer/MainContainer/LeftPanel/Header/VBox/Toolbar/RefreshButton

@onready var event_name_label: Label = $MarginContainer/MainContainer/CenterRightSplit/CenterPanel/EventHeader/HBox/EventNameLabel
@onready var event_icon: Label = $MarginContainer/MainContainer/CenterRightSplit/CenterPanel/EventHeader/HBox/EventIcon
@onready var save_button: Button = $MarginContainer/MainContainer/CenterRightSplit/CenterPanel/EventHeader/HBox/SaveButton

@onready var editor_tabs: TabContainer = $MarginContainer/MainContainer/CenterRightSplit/CenterPanel/EditorTabContainer
@onready var properties_container: VBoxContainer = $MarginContainer/MainContainer/CenterRightSplit/CenterPanel/EditorTabContainer/Properties/PropertiesContainer
@onready var layers_container: VBoxContainer = $MarginContainer/MainContainer/CenterRightSplit/CenterPanel/EditorTabContainer/Layers/LayersContainer
@onready var stems_container: VBoxContainer = $MarginContainer/MainContainer/CenterRightSplit/CenterPanel/EditorTabContainer/Stems/StemsContainer
@onready var snapshots_container: VBoxContainer = $MarginContainer/MainContainer/CenterRightSplit/CenterPanel/EditorTabContainer/Snapshots/SnapshotsContainer

@onready var test_button: Button = $MarginContainer/MainContainer/CenterRightSplit/RightPanel/PlaybackPanel/VBox/ButtonContainer/TestButton
@onready var stop_button: Button = $MarginContainer/MainContainer/CenterRightSplit/RightPanel/PlaybackPanel/VBox/ButtonContainer/StopButton
@onready var status_label: Label = $MarginContainer/MainContainer/CenterRightSplit/RightPanel/PlaybackPanel/VBox/StatusLabel

@onready var parameters_container: VBoxContainer = $MarginContainer/MainContainer/CenterRightSplit/RightPanel/ParametersPanel/VBox/ParametersScroll/ParametersContainer
@onready var no_params_label: Label = $MarginContainer/MainContainer/CenterRightSplit/RightPanel/ParametersPanel/VBox/ParametersScroll/NoParamsLabel
@onready var create_param_button: Button = $MarginContainer/MainContainer/CenterRightSplit/RightPanel/ParametersPanel/VBox/CreateParamButton

@onready var stats_label: Label = $MarginContainer/MainContainer/CenterRightSplit/RightPanel/StatsPanel/VBox/StatsScroll/StatsLabel
@onready var bpm_spinbox: SpinBox = $MarginContainer/MainContainer/CenterRightSplit/RightPanel/StatsPanel/VBox/BPMContainer/BPMSpinBox
@onready var beat_label: Label = $MarginContainer/MainContainer/CenterRightSplit/RightPanel/StatsPanel/VBox/BeatLabel

@onready var new_event_dialog: ConfirmationDialog = $NewEventDialog
@onready var event_name_edit: LineEdit = $NewEventDialog/VBox/EventNameEdit
@onready var location_edit: LineEdit = $NewEventDialog/VBox/LocationEdit

const AUDIO_EVENTS_PATH = "res://audio_events/"

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	refresh_event_list()
	_start_update_timer()

	print("🎵 Audio Mixer UI V2 initialized")

func _setup_ui() -> void:
	# Setup event tree
	if event_tree:
		event_tree.set_column_title(0, "Name")
		event_tree.set_column_title(1, "Type")
		event_tree.hide_root = true

	# Setup new event menu
	if new_event_button:
		var popup = new_event_button.get_popup()
		popup.clear()
		popup.add_item("🎵 Simple Audio Event", 0)
		popup.add_item("🎚 Layered Event", 1)
		popup.add_item("🎼 Music Event", 2)
		popup.add_item("📸 Mixer Snapshot", 3)

func _connect_signals() -> void:
	# Left panel
	if event_tree:
		event_tree.item_selected.connect(_on_event_selected)
	if search_bar:
		search_bar.text_changed.connect(_on_search_changed)
	if new_event_button:
		new_event_button.get_popup().id_pressed.connect(_on_new_event_type_selected)
	if delete_button:
		delete_button.pressed.connect(_on_delete_pressed)
	if refresh_button:
		refresh_button.pressed.connect(refresh_event_list)

	# Center panel
	if save_button:
		save_button.pressed.connect(_on_save_pressed)

	# Right panel
	if test_button:
		test_button.pressed.connect(_on_test_pressed)
	if stop_button:
		stop_button.pressed.connect(_on_stop_pressed)
	if create_param_button:
		create_param_button.pressed.connect(_on_create_param_pressed)
	if bpm_spinbox:
		bpm_spinbox.value_changed.connect(_on_bpm_changed)

	# Dialog
	if new_event_dialog:
		new_event_dialog.confirmed.connect(_on_new_event_confirmed)

	# AudioController signals
	if has_node("/root/AudioController"):
		var audio_controller = get_node("/root/AudioController")
		audio_controller.beat.connect(_on_beat)
		audio_controller.bar.connect(_on_bar)

func _start_update_timer() -> void:
	var timer = Timer.new()
	timer.wait_time = 0.3
	timer.timeout.connect(_update_stats)
	timer.autostart = true
	add_child(timer)

func _process(_delta: float) -> void:
	# Update playback status
	if is_playing and status_label:
		status_label.text = "▶ Playing..."
		status_label.modulate = Color.GREEN
	else:
		status_label.text = "Ready"
		status_label.modulate = Color.WHITE

#region Event List Management

func refresh_event_list() -> void:
	if not event_tree:
		return

	event_tree.clear()
	var root = event_tree.create_item()
	_scan_directory_recursive(AUDIO_EVENTS_PATH, root)
	print("🔄 Event list refreshed")

func _scan_directory_recursive(path: String, parent_item: TreeItem) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()

	# First pass: directories
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			var folder_item = event_tree.create_item(parent_item)
			folder_item.set_text(0, file_name)
			folder_item.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
			folder_item.set_selectable(0, false)
			_scan_directory_recursive(path.path_join(file_name), folder_item)
		file_name = dir.get_next()

	# Second pass: .tres files
	dir.list_dir_begin()
	file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var file_path = path.path_join(file_name)
			var resource = load(file_path)

			if _is_audio_resource(resource):
				var item = event_tree.create_item(parent_item)
				item.set_text(0, file_name.get_basename())
				item.set_metadata(0, file_path)

				var type_info = _get_resource_type_info(resource)
				item.set_text(1, type_info.type_name)
				item.set_icon(0, get_theme_icon(type_info.icon_name, "EditorIcons"))

		file_name = dir.get_next()

	dir.list_dir_end()

func _is_audio_resource(resource: Resource) -> bool:
	return resource is AudioEvent or resource is LayeredAudioEvent or resource is MusicEvent or resource is AudioSnapshot

func _get_resource_type_info(resource: Resource) -> Dictionary:
	if resource is AudioEvent:
		return {"type_name": "Audio", "icon_name": "AudioStreamPlayer"}
	elif resource is LayeredAudioEvent:
		return {"type_name": "Layered", "icon_name": "AudioStreamPlayer2D"}
	elif resource is MusicEvent:
		return {"type_name": "Music", "icon_name": "AudioStreamPlayer3D"}
	elif resource is AudioSnapshot:
		return {"type_name": "Snapshot", "icon_name": "AudioBusLayout"}
	return {"type_name": "Unknown", "icon_name": "File"}

func _on_search_changed(text: String) -> void:
	if not event_tree:
		return
	var root = event_tree.get_root()
	if root:
		_filter_tree(root, text.to_lower())

func _filter_tree(item: TreeItem, search: String) -> bool:
	var visible = false
	var child = item.get_first_child()

	while child:
		if _filter_tree(child, search):
			visible = true
		child = child.get_next()

	if search.is_empty() or item.get_text(0).to_lower().contains(search):
		visible = true

	item.visible = visible
	return visible

#endregion

#region Event Selection

func _on_event_selected() -> void:
	var selected = event_tree.get_selected()
	if not selected:
		return

	var file_path = selected.get_metadata(0)
	if not file_path:
		return

	load_event(file_path)

func load_event(file_path: String) -> void:
	var resource = load(file_path)
	if not _is_audio_resource(resource):
		return

	current_event = resource
	current_event_path = file_path

	_update_header()
	_build_property_editor()
	_update_parameters_panel()

	print("📂 Loaded: ", file_path)

func _update_header() -> void:
	if not current_event:
		event_name_label.text = "No Event Selected"
		event_icon.text = "❓"
		return

	var name = ""
	if current_event is AudioEvent:
		name = current_event.event_name
		event_icon.text = "🎵"
	elif current_event is LayeredAudioEvent:
		name = current_event.event_name
		event_icon.text = "🎚"
	elif current_event is MusicEvent:
		name = current_event.music_name
		event_icon.text = "🎼"
	elif current_event is AudioSnapshot:
		name = current_event.snapshot_name
		event_icon.text = "📸"

	event_name_label.text = name

#endregion

#region Property Editor

func _build_property_editor() -> void:
	# Clear all containers
	for child in properties_container.get_children():
		child.queue_free()
	for child in layers_container.get_children():
		child.queue_free()
	for child in stems_container.get_children():
		child.queue_free()
	for child in snapshots_container.get_children():
		child.queue_free()

	if not current_event:
		return

	# Build appropriate editor based on type
	if current_event is AudioEvent:
		_build_audio_event_editor()
		editor_tabs.current_tab = 0
	elif current_event is LayeredAudioEvent:
		_build_layered_event_editor()
		editor_tabs.current_tab = 1
	elif current_event is MusicEvent:
		_build_music_event_editor()
		editor_tabs.current_tab = 2
	elif current_event is AudioSnapshot:
		_build_snapshot_editor()
		editor_tabs.current_tab = 3

func _build_audio_event_editor() -> void:
	var event: AudioEvent = current_event

	# Event Identity
	_add_section_header(properties_container, "Event Identity")
	_add_text_field(properties_container, "Event Name", event.event_name, func(val): event.event_name = val)
	_add_text_field(properties_container, "Category", event.category, func(val): event.category = val)
	_add_multiline_field(properties_container, "Description", event.description, func(val): event.description = val)

	# Audio Streams
	_add_section_header(properties_container, "Audio Streams")
	_add_stream_list(properties_container, event)
	_add_enum_field(properties_container, "Playback Mode", event.playback_mode,
		["One Shot", "Looping", "Random One", "Sequential"],
		func(val): event.playback_mode = val)

	# Randomization
	_add_section_header(properties_container, "Randomization")
	_add_vector2_field(properties_container, "Volume Range (dB)", event.volume_range, func(val): event.volume_range = val)
	_add_vector2_field(properties_container, "Pitch Range", event.pitch_range, func(val): event.pitch_range = val)
	_add_bool_field(properties_container, "Random Start Position", event.random_start_position, func(val): event.random_start_position = val)

	# Playback Control
	_add_section_header(properties_container, "Playback Control")
	_add_int_field(properties_container, "Max Concurrent Instances", event.max_concurrent_instances, 1, 100, func(val): event.max_concurrent_instances = val)
	_add_enum_field(properties_container, "Priority", event.priority,
		["Lowest", "Low", "Normal", "High", "Critical"],
		func(val): event.priority = val)
	_add_float_field(properties_container, "Cooldown Time (s)", event.cooldown_time, 0.0, 10.0, func(val): event.cooldown_time = val)
	_add_float_field(properties_container, "Fade In Duration (s)", event.fade_in_duration, 0.0, 5.0, func(val): event.fade_in_duration = val)
	_add_float_field(properties_container, "Fade Out Duration (s)", event.fade_out_duration, 0.0, 5.0, func(val): event.fade_out_duration = val)

	# Spatial Audio
	_add_section_header(properties_container, "Spatial Audio")
	_add_enum_field(properties_container, "Spatial Mode", event.spatial_mode,
		["2D", "3D"],
		func(val): event.spatial_mode = val)
	_add_float_field(properties_container, "Max Distance", event.max_distance, 1.0, 4096.0, func(val): event.max_distance = val)
	_add_float_field(properties_container, "Unit Size", event.unit_size, 0.1, 100.0, func(val): event.unit_size = val)

	# Audio Bus
	_add_section_header(properties_container, "Audio Routing")
	_add_bus_selector(properties_container, "Bus Name", event.bus_name, func(val): event.bus_name = val)

func _build_layered_event_editor() -> void:
	var event: LayeredAudioEvent = current_event

	# Basic properties
	_add_section_header(layers_container, "Event Settings")
	_add_text_field(layers_container, "Event Name", event.event_name, func(val): event.event_name = val)
	_add_text_field(layers_container, "Control Parameter", event.control_parameter, func(val): event.control_parameter = val)
	_add_float_field(layers_container, "Crossfade Time (s)", event.crossfade_time, 0.0, 5.0, func(val): event.crossfade_time = val)
	_add_bool_field(layers_container, "Pitch Follows Parameter", event.pitch_follows_parameter, func(val): event.pitch_follows_parameter = val)

	# Layers
	_add_section_header(layers_container, "Audio Layers")
	_add_layer_editor(layers_container, event)

func _build_music_event_editor() -> void:
	var event: MusicEvent = current_event

	# Music settings
	_add_section_header(stems_container, "Music Settings")
	_add_text_field(stems_container, "Music Name", event.music_name, func(val): event.music_name = val)
	_add_float_field(stems_container, "BPM", event.bpm, 30.0, 300.0, func(val): event.bpm = val)
	_add_int_field(stems_container, "Beats Per Bar", event.beats_per_bar, 1, 16, func(val): event.beats_per_bar = val)
	_add_bool_field(stems_container, "Loop", event.loop, func(val): event.loop = val)

	# Stems
	_add_section_header(stems_container, "Music Stems")
	_add_stem_editor(stems_container, event)

func _build_snapshot_editor() -> void:
	var snapshot: AudioSnapshot = current_event

	_add_section_header(snapshots_container, "Snapshot Settings")
	_add_text_field(snapshots_container, "Snapshot Name", snapshot.snapshot_name, func(val): snapshot.snapshot_name = val)
	_add_float_field(snapshots_container, "Transition Time (s)", snapshot.transition_time, 0.0, 10.0, func(val): snapshot.transition_time = val)

	# Capture button
	var capture_btn = Button.new()
	capture_btn.text = "📸 Capture Current Mixer State"
	capture_btn.pressed.connect(func(): snapshot.capture_current_mixer_state())
	snapshots_container.add_child(capture_btn)

#endregion

#region Property Editor Helpers

func _add_section_header(container: Control, title: String) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	container.add_child(spacer)

	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	container.add_child(label)

	var sep = HSeparator.new()
	container.add_child(sep)

func _add_text_field(container: Control, label: String, value: String, on_changed: Callable) -> void:
	var hbox = HBoxContainer.new()

	var lbl = Label.new()
	lbl.text = label + ":"
	lbl.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(lbl)

	var edit = LineEdit.new()
	edit.text = value
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(on_changed)
	hbox.add_child(edit)

	container.add_child(hbox)

func _add_multiline_field(container: Control, label: String, value: String, on_changed: Callable) -> void:
	var lbl = Label.new()
	lbl.text = label + ":"
	container.add_child(lbl)

	var edit = TextEdit.new()
	edit.text = value
	edit.custom_minimum_size = Vector2(0, 60)
	edit.text_changed.connect(func(): on_changed.call(edit.text))
	container.add_child(edit)

func _add_float_field(container: Control, label: String, value: float, min_val: float, max_val: float, on_changed: Callable) -> void:
	var hbox = HBoxContainer.new()

	var lbl = Label.new()
	lbl.text = label + ":"
	lbl.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(lbl)

	var spin = SpinBox.new()
	spin.value = value
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = 0.01 if max_val - min_val < 100 else 1.0
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.value_changed.connect(on_changed)
	hbox.add_child(spin)

	container.add_child(hbox)

func _add_int_field(container: Control, label: String, value: int, min_val: int, max_val: int, on_changed: Callable) -> void:
	var hbox = HBoxContainer.new()

	var lbl = Label.new()
	lbl.text = label + ":"
	lbl.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(lbl)

	var spin = SpinBox.new()
	spin.value = value
	spin.min_value = min_val
	spin.max_value = max_val
	spin.step = 1.0
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.value_changed.connect(func(val): on_changed.call(int(val)))
	hbox.add_child(spin)

	container.add_child(hbox)

func _add_bool_field(container: Control, label: String, value: bool, on_changed: Callable) -> void:
	var hbox = HBoxContainer.new()

	var check = CheckBox.new()
	check.text = label
	check.button_pressed = value
	check.toggled.connect(on_changed)
	hbox.add_child(check)

	container.add_child(hbox)

func _add_vector2_field(container: Control, label: String, value: Vector2, on_changed: Callable) -> void:
	var hbox = HBoxContainer.new()

	var lbl = Label.new()
	lbl.text = label + ":"
	lbl.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(lbl)

	var x_spin = SpinBox.new()
	x_spin.value = value.x
	x_spin.min_value = -100.0
	x_spin.max_value = 100.0
	x_spin.step = 0.01
	x_spin.prefix = "X: "
	x_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	x_spin.value_changed.connect(func(val):
		on_changed.call(Vector2(val, value.y))
		value.x = val
	)
	hbox.add_child(x_spin)

	var y_spin = SpinBox.new()
	y_spin.value = value.y
	y_spin.min_value = -100.0
	y_spin.max_value = 100.0
	y_spin.step = 0.01
	y_spin.prefix = "Y: "
	y_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	y_spin.value_changed.connect(func(val):
		on_changed.call(Vector2(value.x, val))
		value.y = val
	)
	hbox.add_child(y_spin)

	container.add_child(hbox)

func _add_enum_field(container: Control, label: String, value: int, options: Array, on_changed: Callable) -> void:
	var hbox = HBoxContainer.new()

	var lbl = Label.new()
	lbl.text = label + ":"
	lbl.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(lbl)

	var option_btn = OptionButton.new()
	for option in options:
		option_btn.add_item(option)
	option_btn.selected = value
	option_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option_btn.item_selected.connect(on_changed)
	hbox.add_child(option_btn)

	container.add_child(hbox)

func _add_bus_selector(container: Control, label: String, value: String, on_changed: Callable) -> void:
	var hbox = HBoxContainer.new()

	var lbl = Label.new()
	lbl.text = label + ":"
	lbl.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(lbl)

	var option_btn = OptionButton.new()
	for i in range(AudioServer.bus_count):
		var bus_name = AudioServer.get_bus_name(i)
		option_btn.add_item(bus_name)
		if bus_name == value:
			option_btn.selected = i
	option_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option_btn.item_selected.connect(func(idx): on_changed.call(AudioServer.get_bus_name(idx)))
	hbox.add_child(option_btn)

	container.add_child(hbox)

func _add_stream_list(container: Control, event: AudioEvent) -> void:
	var label = Label.new()
	label.text = "Audio Streams (drag .wav/.ogg files here):"
	container.add_child(label)

	var list_container = VBoxContainer.new()

	# Show existing streams
	for i in range(event.streams.size()):
		var stream = event.streams[i]
		var item_hbox = HBoxContainer.new()

		var stream_label = Label.new()
		stream_label.text = "🎵 " + (stream.resource_path.get_file() if stream else "Empty")
		stream_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_hbox.add_child(stream_label)

		var remove_btn = Button.new()
		remove_btn.text = "✖"
		remove_btn.pressed.connect(func():
			event.streams.remove_at(i)
			_build_property_editor()
		)
		item_hbox.add_child(remove_btn)

		list_container.add_child(item_hbox)

	# Add new stream button
	var add_btn = Button.new()
	add_btn.text = "+ Add Stream"
	add_btn.pressed.connect(func():
		# TODO: File dialog for adding streams
		print("File dialog not implemented in this version - use Inspector to add streams")
	)
	list_container.add_child(add_btn)

	container.add_child(list_container)

func _add_layer_editor(container: Control, event: LayeredAudioEvent) -> void:
	for i in range(event.layers.size()):
		var layer = event.layers[i]
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()

		# Layer header
		var header = HBoxContainer.new()
		var layer_label = Label.new()
		layer_label.text = "Layer %d: %s" % [i, layer.layer_name]
		layer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(layer_label)

		var remove_btn = Button.new()
		remove_btn.text = "✖ Remove"
		remove_btn.pressed.connect(func():
			event.layers.remove_at(i)
			_build_property_editor()
		)
		header.add_child(remove_btn)
		vbox.add_child(header)

		# Layer properties
		_add_text_field(vbox, "Name", layer.layer_name, func(val): layer.layer_name = val)
		_add_vector2_field(vbox, "Parameter Range", layer.parameter_range, func(val): layer.parameter_range = val)
		_add_float_field(vbox, "Volume Offset (dB)", layer.volume_offset, -80.0, 6.0, func(val): layer.volume_offset = val)
		_add_float_field(vbox, "Pitch Offset", layer.pitch_offset, 0.1, 4.0, func(val): layer.pitch_offset = val)
		_add_bool_field(vbox, "Looping", layer.looping, func(val): layer.looping = val)
		_add_bool_field(vbox, "Enabled", layer.enabled, func(val): layer.enabled = val)

		panel.add_child(vbox)
		container.add_child(panel)

	# Add layer button
	var add_btn = Button.new()
	add_btn.text = "+ Add Layer"
	add_btn.pressed.connect(func():
		var new_layer = LayeredAudioEvent.AudioLayer.new()
		new_layer.layer_name = "Layer %d" % event.layers.size()
		event.layers.append(new_layer)
		_build_property_editor()
	)
	container.add_child(add_btn)

func _add_stem_editor(container: Control, event: MusicEvent) -> void:
	for i in range(event.stems.size()):
		var stem = event.stems[i]
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()

		# Stem header
		var header = HBoxContainer.new()
		var stem_label = Label.new()
		stem_label.text = "Stem %d: %s" % [i, stem.stem_name]
		stem_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(stem_label)

		var remove_btn = Button.new()
		remove_btn.text = "✖ Remove"
		remove_btn.pressed.connect(func():
			event.stems.remove_at(i)
			_build_property_editor()
		)
		header.add_child(remove_btn)
		vbox.add_child(header)

		# Stem properties
		_add_text_field(vbox, "Name", stem.stem_name, func(val): stem.stem_name = val)
		_add_bool_field(vbox, "Default Enabled", stem.default_enabled, func(val): stem.default_enabled = val)
		_add_float_field(vbox, "Volume Offset (dB)", stem.volume_offset, -80.0, 6.0, func(val): stem.volume_offset = val)
		_add_text_field(vbox, "Control Parameter", stem.control_parameter, func(val): stem.control_parameter = val)
		_add_vector2_field(vbox, "Parameter Range", stem.parameter_range, func(val): stem.parameter_range = val)
		_add_float_field(vbox, "Fade Time (s)", stem.fade_time, 0.0, 10.0, func(val): stem.fade_time = val)

		panel.add_child(vbox)
		container.add_child(panel)

	# Add stem button
	var add_btn = Button.new()
	add_btn.text = "+ Add Stem"
	add_btn.pressed.connect(func():
		var new_stem = MusicEvent.MusicStem.new()
		new_stem.stem_name = "Stem %d" % event.stems.size()
		event.stems.append(new_stem)
		_build_property_editor()
	)
	container.add_child(add_btn)

#endregion

#region Parameters Panel

func _update_parameters_panel() -> void:
	# Clear existing parameter sliders
	for child in parameters_container.get_children():
		child.queue_free()
	param_sliders.clear()

	if not current_event:
		no_params_label.visible = true
		return

	var param_names: Array = []

	# Collect parameter names
	if current_event is LayeredAudioEvent:
		if not current_event.control_parameter.is_empty():
			param_names.append(current_event.control_parameter)
	elif current_event is MusicEvent:
		for stem in current_event.stems:
			if not stem.control_parameter.is_empty() and not param_names.has(stem.control_parameter):
				param_names.append(stem.control_parameter)

	if param_names.is_empty():
		no_params_label.visible = true
		return

	no_params_label.visible = false

	# Create sliders for each parameter
	for param_name in param_names:
		_create_parameter_slider(param_name)

func _create_parameter_slider(param_name: String) -> void:
	var vbox = VBoxContainer.new()

	# Parameter name and value
	var header = HBoxContainer.new()
	var name_label = Label.new()
	name_label.text = param_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)

	var value_label = Label.new()
	value_label.text = "0.00"
	value_label.custom_minimum_size = Vector2(50, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(value_label)
	vbox.add_child(header)

	# Slider
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = 0.5
	slider.value_changed.connect(func(val):
		value_label.text = "%.2f" % val
		_on_parameter_slider_changed(param_name, val)
	)
	vbox.add_child(slider)

	parameters_container.add_child(vbox)
	param_sliders[param_name] = {"slider": slider, "label": name_label, "value_label": value_label}

func _on_parameter_slider_changed(param_name: String, value: float) -> void:
	if not has_node("/root/AudioController"):
		return

	var audio_controller = get_node("/root/AudioController")

	# Create parameter if it doesn't exist
	if not audio_controller.get_parameter(param_name):
		audio_controller.create_parameter(param_name, 0.0, 1.0, value)

	# Update parameter value
	audio_controller.set_parameter(param_name, value)

func _on_create_param_pressed() -> void:
	# TODO: Dialog for creating new parameter
	print("Create parameter dialog not implemented yet")

#endregion

#region Playback Control

func _on_test_pressed() -> void:
	if not current_event:
		status_label.text = "⚠ No event selected"
		return

	if not has_node("/root/AudioController"):
		status_label.text = "⚠ AudioController not found"
		return

	var audio_controller = get_node("/root/AudioController")

	if current_event is AudioEvent:
		audio_controller.play_event(current_event)
		is_playing = true
		await get_tree().create_timer(0.5).timeout
		is_playing = false

	elif current_event is LayeredAudioEvent:
		# Create parameter if needed
		if not current_event.control_parameter.is_empty():
			if not audio_controller.get_parameter(current_event.control_parameter):
				audio_controller.create_parameter(current_event.control_parameter, 0.0, 1.0, 0.5)
		audio_controller.play_layered_event(current_event)
		is_playing = true

	elif current_event is MusicEvent:
		if has_node("/root/MusicManager"):
			var music_manager = get_node("/root/MusicManager")
			music_manager.play_music(current_event, 1.0)
			is_playing = true
		else:
			status_label.text = "⚠ MusicManager not found"

	elif current_event is AudioSnapshot:
		audio_controller.register_snapshot(current_event)
		audio_controller.apply_snapshot(current_event.snapshot_name, 0.5)
		is_playing = true
		await get_tree().create_timer(1.0).timeout
		is_playing = false

func _on_stop_pressed() -> void:
	is_playing = false

	if has_node("/root/MusicManager"):
		var music_manager = get_node("/root/MusicManager")
		music_manager.stop_music(0.5)

	status_label.text = "Stopped"

#endregion

#region Event Creation

func _on_new_event_type_selected(id: int) -> void:
	new_event_dialog.popup_centered()
	event_name_edit.grab_focus()

var _pending_event_type: int = 0

func _on_new_event_confirmed() -> void:
	var event_name = event_name_edit.text.strip_edges()
	if event_name.is_empty():
		event_name = "new_event"

	var save_path = location_edit.text
	if not save_path.ends_with("/"):
		save_path += "/"
	save_path += event_name + ".tres"

	# Create event based on type
	var new_event: Resource = null
	match _pending_event_type:
		0:  # AudioEvent
			new_event = AudioEvent.new()
			new_event.event_name = event_name
		1:  # LayeredAudioEvent
			new_event = LayeredAudioEvent.new()
			new_event.event_name = event_name
		2:  # MusicEvent
			new_event = MusicEvent.new()
			new_event.music_name = event_name
		3:  # AudioSnapshot
			new_event = AudioSnapshot.new()
			new_event.snapshot_name = event_name

	# Save
	DirAccess.make_dir_recursive_absolute(location_edit.text)
	var err = ResourceSaver.save(new_event, save_path)

	if err == OK:
		print("✅ Created: ", save_path)
		refresh_event_list()
		load_event(save_path)
	else:
		print("❌ Failed to create event: ", err)

func _on_delete_pressed() -> void:
	if not current_event or current_event_path.is_empty():
		return

	# TODO: Confirmation dialog
	DirAccess.remove_absolute(current_event_path)
	print("🗑 Deleted: ", current_event_path)
	current_event = null
	current_event_path = ""
	refresh_event_list()
	_update_header()

func _on_save_pressed() -> void:
	if not current_event or current_event_path.is_empty():
		return

	var err = ResourceSaver.save(current_event, current_event_path)
	if err == OK:
		print("💾 Saved: ", current_event_path)
		status_label.text = "✅ Saved!"
		await get_tree().create_timer(2.0).timeout
		status_label.text = "Ready"
	else:
		print("❌ Save failed: ", err)
		status_label.text = "❌ Save failed!"

#endregion

#region Stats & BPM

func _update_stats() -> void:
	if not has_node("/root/AudioController"):
		return

	var audio_controller = get_node("/root/AudioController")
	var stats = audio_controller.get_pool_stats()

	var stats_text = """2D Players: %d available, %d active
3D Players: %d available, %d active
Total: %d / %d players

Layered Events: %d active
Parameters: %d""" % [
		stats.pool_2d_available,
		stats.active_2d,
		stats.pool_3d_available,
		stats.active_3d,
		stats.total_players,
		audio_controller.max_total_players,
		stats.layered_events,
		audio_controller._parameters.size()
	]

	stats_label.text = stats_text

	# Update BPM display
	if bpm_spinbox:
		bpm_spinbox.set_value_no_signal(audio_controller.global_bpm)

func _on_bpm_changed(value: float) -> void:
	if has_node("/root/AudioController"):
		var audio_controller = get_node("/root/AudioController")
		audio_controller.global_bpm = value

func _on_beat(beat_num: int) -> void:
	if not beat_label:
		return

	var audio_controller = get_node("/root/AudioController")
	beat_label.text = "Beat: %d | Bar: %d" % [beat_num + 1, audio_controller.get_current_bar()]

	# Visual feedback
	beat_label.modulate = Color.YELLOW
	await get_tree().create_timer(0.1).timeout
	if beat_label:
		beat_label.modulate = Color.WHITE

func _on_bar(bar_num: int) -> void:
	pass  # Could add bar feedback

#endregion
