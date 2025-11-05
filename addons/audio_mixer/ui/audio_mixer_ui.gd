@tool
extends Control

## AudioMixer UI - Main interface for the audio system

var editor_plugin: EditorPlugin = null
var current_event: Resource = null
var preview_players: Array = []

# UI References (will be set when scene is loaded)
@onready var event_tree: Tree = $HSplitContainer/LeftPanel/EventTree
@onready var event_search: LineEdit = $HSplitContainer/LeftPanel/VBoxContainer/SearchBar
@onready var create_event_menu: MenuButton = $HSplitContainer/LeftPanel/VBoxContainer/CreateEventMenu
@onready var refresh_button: Button = $HSplitContainer/LeftPanel/VBoxContainer/RefreshButton

@onready var inspector_container: VBoxContainer = $HSplitContainer/RightPanel/ScrollContainer/InspectorContainer
@onready var event_name_label: Label = $HSplitContainer/RightPanel/HeaderPanel/EventNameLabel
@onready var test_button: Button = $HSplitContainer/RightPanel/HeaderPanel/TestButton
@onready var stop_button: Button = $HSplitContainer/RightPanel/HeaderPanel/StopButton

@onready var param_list: ItemList = $HSplitContainer/RightPanel/BottomPanel/TabContainer/Parameters/ParamList
@onready var param_name: LineEdit = $HSplitContainer/RightPanel/BottomPanel/TabContainer/Parameters/Controls/ParamName
@onready var param_value: SpinBox = $HSplitContainer/RightPanel/BottomPanel/TabContainer/Parameters/Controls/ParamValue
@onready var param_min: SpinBox = $HSplitContainer/RightPanel/BottomPanel/TabContainer/Parameters/Controls/ParamMin
@onready var param_max: SpinBox = $HSplitContainer/RightPanel/BottomPanel/TabContainer/Parameters/Controls/ParamMax

@onready var bpm_spinbox: SpinBox = $HSplitContainer/RightPanel/BottomPanel/TabContainer/BPMSync/BPMSpinBox
@onready var time_sig_spinbox: SpinBox = $HSplitContainer/RightPanel/BottomPanel/TabContainer/BPMSync/TimeSigSpinBox
@onready var beat_label: Label = $HSplitContainer/RightPanel/BottomPanel/TabContainer/BPMSync/BeatLabel
@onready var bpm_start_button: Button = $HSplitContainer/RightPanel/BottomPanel/TabContainer/BPMSync/StartButton
@onready var bpm_stop_button: Button = $HSplitContainer/RightPanel/BottomPanel/TabContainer/BPMSync/StopButton

@onready var pool_stats_label: Label = $HSplitContainer/RightPanel/BottomPanel/TabContainer/Stats/PoolStatsLabel

const AUDIO_EVENTS_PATH = "res://audio_events/"

func _ready() -> void:
	# Setup UI
	_setup_event_tree()
	_setup_create_menu()
	_connect_signals()

	# Load events
	refresh_event_list()

	# Start update timer for stats
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_update_stats)
	timer.autostart = true
	add_child(timer)

func _setup_event_tree() -> void:
	if not event_tree:
		return

	event_tree.columns = 2
	event_tree.set_column_title(0, "Event Name")
	event_tree.set_column_title(1, "Type")
	event_tree.set_column_titles_visible(true)
	event_tree.hide_root = true

func _setup_create_menu() -> void:
	if not create_event_menu:
		return

	var popup = create_event_menu.get_popup()
	popup.add_item("AudioEvent", 0)
	popup.add_item("LayeredAudioEvent", 1)
	popup.add_item("MusicEvent", 2)
	popup.add_item("AudioSnapshot", 3)
	popup.id_pressed.connect(_on_create_event_pressed)

func _connect_signals() -> void:
	if event_tree:
		event_tree.item_selected.connect(_on_event_selected)

	if refresh_button:
		refresh_button.pressed.connect(refresh_event_list)

	if test_button:
		test_button.pressed.connect(_on_test_button_pressed)

	if stop_button:
		stop_button.pressed.connect(_on_stop_button_pressed)

	if event_search:
		event_search.text_changed.connect(_on_search_text_changed)

	# Parameter controls
	if param_list:
		param_list.item_selected.connect(_on_param_selected)

	# BPM controls
	if bpm_spinbox:
		bpm_spinbox.value_changed.connect(_on_bpm_changed)

	if time_sig_spinbox:
		time_sig_spinbox.value_changed.connect(_on_time_sig_changed)

	if bpm_start_button:
		bpm_start_button.pressed.connect(_on_bpm_start_pressed)

	if bpm_stop_button:
		bpm_stop_button.pressed.connect(_on_bpm_stop_pressed)

	# Connect to AudioController signals if available
	if has_node("/root/AudioController"):
		var audio_controller = get_node("/root/AudioController")
		audio_controller.beat.connect(_on_beat)
		audio_controller.bar.connect(_on_bar)

func _process(_delta: float) -> void:
	# Update BPM display
	_update_bpm_display()

#region Event List Management
func refresh_event_list() -> void:
	if not event_tree:
		return

	event_tree.clear()
	var root = event_tree.create_item()

	# Scan audio_events directory
	_scan_directory_recursive(AUDIO_EVENTS_PATH, root)

func _scan_directory_recursive(path: String, parent_item: TreeItem) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		push_warning("Failed to open directory: %s" % path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	# First pass: add directories
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			var folder_item = event_tree.create_item(parent_item)
			folder_item.set_text(0, file_name)
			folder_item.set_icon(0, get_theme_icon("Folder", "EditorIcons"))
			folder_item.set_selectable(0, false)

			# Recurse into subdirectory
			_scan_directory_recursive(path.path_join(file_name), folder_item)

		file_name = dir.get_next()

	dir.list_dir_begin()
	file_name = dir.get_next()

	# Second pass: add .tres files
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var file_path = path.path_join(file_name)
			var resource = load(file_path)

			if resource is AudioEvent or resource is LayeredAudioEvent or resource is MusicEvent or resource is AudioSnapshot:
				var item = event_tree.create_item(parent_item)
				item.set_text(0, file_name.get_basename())
				item.set_metadata(0, file_path)

				# Set type and icon
				var type_name = "Unknown"
				var icon_name = "AudioStreamPlayer"

				if resource is AudioEvent:
					type_name = "AudioEvent"
					icon_name = "AudioStreamPlayer"
				elif resource is LayeredAudioEvent:
					type_name = "Layered"
					icon_name = "AudioStreamPlayer2D"
				elif resource is MusicEvent:
					type_name = "Music"
					icon_name = "AudioStreamPlayer3D"
				elif resource is AudioSnapshot:
					type_name = "Snapshot"
					icon_name = "AudioBusLayout"

				item.set_text(1, type_name)
				item.set_icon(0, get_theme_icon(icon_name, "EditorIcons"))

		file_name = dir.get_next()

	dir.list_dir_end()

func _on_search_text_changed(new_text: String) -> void:
	if not event_tree:
		return

	# Simple search filter
	var root = event_tree.get_root()
	if not root:
		return

	_filter_tree_items(root, new_text.to_lower())

func _filter_tree_items(item: TreeItem, search_text: String) -> bool:
	var has_visible_children = false
	var child = item.get_first_child()

	while child:
		var child_visible = _filter_tree_items(child, search_text)
		has_visible_children = has_visible_children or child_visible
		child = child.get_next()

	# Show item if it matches search or has visible children
	var item_name = item.get_text(0).to_lower()
	var should_show = search_text.is_empty() or item_name.contains(search_text) or has_visible_children

	item.visible = should_show
	return should_show
#endregion

#region Event Selection
func _on_event_selected() -> void:
	var selected = event_tree.get_selected()
	if not selected:
		return

	var file_path = selected.get_metadata(0)
	if not file_path:
		return

	# Load resource
	current_event = load(file_path)
	if not current_event:
		return

	# Update inspector
	_update_inspector()

func _update_inspector() -> void:
	if not current_event:
		return

	# Update header
	if event_name_label:
		if current_event is AudioEvent:
			event_name_label.text = current_event.event_name
		elif current_event is LayeredAudioEvent:
			event_name_label.text = current_event.event_name
		elif current_event is MusicEvent:
			event_name_label.text = current_event.music_name
		elif current_event is AudioSnapshot:
			event_name_label.text = current_event.snapshot_name

	# Clear inspector
	if inspector_container:
		for child in inspector_container.get_children():
			child.queue_free()

		# Add property editors
		_add_property_editors()

func _add_property_editors() -> void:
	if not inspector_container or not current_event:
		return

	var properties = current_event.get_property_list()

	for prop in properties:
		# Skip internal properties
		if prop.usage & PROPERTY_USAGE_EDITOR == 0:
			continue

		# Skip specific properties
		if prop.name in ["resource_local_to_scene", "resource_path", "resource_name", "script"]:
			continue

		# Create label
		var label = Label.new()
		label.text = prop.name.capitalize()
		inspector_container.add_child(label)

		# Create appropriate editor based on type
		match prop.type:
			TYPE_BOOL:
				var checkbox = CheckBox.new()
				checkbox.button_pressed = current_event.get(prop.name)
				checkbox.toggled.connect(func(value): current_event.set(prop.name, value))
				inspector_container.add_child(checkbox)

			TYPE_INT, TYPE_FLOAT:
				var spinbox = SpinBox.new()
				spinbox.value = current_event.get(prop.name)
				spinbox.step = 0.01 if prop.type == TYPE_FLOAT else 1.0

				if prop.hint == PROPERTY_HINT_RANGE:
					var range_parts = prop.hint_string.split(",")
					if range_parts.size() >= 2:
						spinbox.min_value = float(range_parts[0])
						spinbox.max_value = float(range_parts[1])

				spinbox.value_changed.connect(func(value): current_event.set(prop.name, value))
				inspector_container.add_child(spinbox)

			TYPE_STRING:
				if prop.hint == PROPERTY_HINT_ENUM:
					var option_button = OptionButton.new()
					var options = prop.hint_string.split(",")
					for option in options:
						option_button.add_item(option)

					var current_value = current_event.get(prop.name)
					option_button.selected = options.find(current_value)
					option_button.item_selected.connect(func(idx): current_event.set(prop.name, options[idx]))
					inspector_container.add_child(option_button)
				else:
					var line_edit = LineEdit.new()
					line_edit.text = str(current_event.get(prop.name))
					line_edit.text_changed.connect(func(value): current_event.set(prop.name, value))
					inspector_container.add_child(line_edit)

			TYPE_VECTOR2:
				var hbox = HBoxContainer.new()
				var vec2_value: Vector2 = current_event.get(prop.name)

				var x_spin = SpinBox.new()
				x_spin.value = vec2_value.x
				x_spin.step = 0.01
				x_spin.value_changed.connect(func(value):
					var v = current_event.get(prop.name)
					current_event.set(prop.name, Vector2(value, v.y))
				)

				var y_spin = SpinBox.new()
				y_spin.value = vec2_value.y
				y_spin.step = 0.01
				y_spin.value_changed.connect(func(value):
					var v = current_event.get(prop.name)
					current_event.set(prop.name, Vector2(v.x, value))
				)

				hbox.add_child(Label.new())
				hbox.get_child(-1).text = "X:"
				hbox.add_child(x_spin)
				hbox.add_child(Label.new())
				hbox.get_child(-1).text = "Y:"
				hbox.add_child(y_spin)

				inspector_container.add_child(hbox)

		# Add spacing
		inspector_container.add_child(HSeparator.new())
#endregion

#region Event Creation
func _on_create_event_pressed(id: int) -> void:
	var new_event: Resource = null

	match id:
		0:  # AudioEvent
			new_event = AudioEvent.new()
			new_event.event_name = "NewAudioEvent"
		1:  # LayeredAudioEvent
			new_event = LayeredAudioEvent.new()
			new_event.event_name = "NewLayeredEvent"
		2:  # MusicEvent
			new_event = MusicEvent.new()
			new_event.music_name = "NewMusic"
		3:  # AudioSnapshot
			new_event = AudioSnapshot.new()
			new_event.snapshot_name = "NewSnapshot"

	if new_event:
		# Save to file
		var file_name = "new_event_%d.tres" % Time.get_ticks_msec()
		var save_path = AUDIO_EVENTS_PATH.path_join(file_name)

		# Ensure directory exists
		DirAccess.make_dir_recursive_absolute(AUDIO_EVENTS_PATH)

		var err = ResourceSaver.save(new_event, save_path)
		if err == OK:
			print("Created new event: %s" % save_path)
			refresh_event_list()
		else:
			push_error("Failed to save event: %s" % save_path)
#endregion

#region Playback Testing
func _on_test_button_pressed() -> void:
	if not current_event:
		return

	if not has_node("/root/AudioController"):
		push_warning("AudioController not found")
		return

	var audio_controller = get_node("/root/AudioController")

	if current_event is AudioEvent:
		audio_controller.play_event(current_event)
		print("Testing AudioEvent: %s" % current_event.event_name)

	elif current_event is LayeredAudioEvent:
		audio_controller.play_layered_event(current_event)
		print("Testing LayeredAudioEvent: %s" % current_event.event_name)

	elif current_event is MusicEvent:
		if has_node("/root/MusicManager"):
			var music_manager = get_node("/root/MusicManager")
			music_manager.play_music(current_event)
			print("Testing MusicEvent: %s" % current_event.music_name)

	elif current_event is AudioSnapshot:
		audio_controller.apply_snapshot(current_event.snapshot_name)
		print("Applying AudioSnapshot: %s" % current_event.snapshot_name)

func _on_stop_button_pressed() -> void:
	if has_node("/root/MusicManager"):
		var music_manager = get_node("/root/MusicManager")
		music_manager.stop_music(0.5)
#endregion

#region Parameters
func _on_param_selected(index: int) -> void:
	# Load selected parameter info
	pass

func _update_param_list() -> void:
	if not param_list or not has_node("/root/AudioController"):
		return

	param_list.clear()
	var audio_controller = get_node("/root/AudioController")

	for param_name in audio_controller._parameters.keys():
		var param: AudioParameter = audio_controller._parameters[param_name]
		param_list.add_item("%s: %.2f" % [param_name, param.current_value])
#endregion

#region BPM Sync
func _on_bpm_changed(value: float) -> void:
	if has_node("/root/AudioController"):
		var audio_controller = get_node("/root/AudioController")
		audio_controller.global_bpm = value

func _on_time_sig_changed(value: float) -> void:
	if has_node("/root/AudioController"):
		var audio_controller = get_node("/root/AudioController")
		audio_controller.time_signature = int(value)

func _on_bpm_start_pressed() -> void:
	if has_node("/root/AudioController"):
		var audio_controller = get_node("/root/AudioController")
		audio_controller.start_bpm_clock()

func _on_bpm_stop_pressed() -> void:
	if has_node("/root/AudioController"):
		var audio_controller = get_node("/root/AudioController")
		audio_controller.stop_bpm_clock()

func _update_bpm_display() -> void:
	if not has_node("/root/AudioController"):
		return

	var audio_controller = get_node("/root/AudioController")

	if bpm_spinbox:
		bpm_spinbox.value = audio_controller.global_bpm

	if time_sig_spinbox:
		time_sig_spinbox.value = audio_controller.time_signature

	if beat_label:
		beat_label.text = "Beat: %d/%d | Bar: %d" % [
			audio_controller.get_current_beat() + 1,
			audio_controller.time_signature,
			audio_controller.get_current_bar()
		]

func _on_beat(beat_num: int) -> void:
	# Visual feedback for beat
	if beat_label:
		beat_label.modulate = Color.GREEN
		await get_tree().create_timer(0.1).timeout
		if beat_label:
			beat_label.modulate = Color.WHITE

func _on_bar(bar_num: int) -> void:
	# Visual feedback for bar
	pass
#endregion

#region Stats
func _update_stats() -> void:
	if not pool_stats_label or not has_node("/root/AudioController"):
		return

	var audio_controller = get_node("/root/AudioController")
	var stats = audio_controller.get_pool_stats()

	var stats_text = """
	Pool Statistics:

	2D Players:
	  Available: %d
	  Active: %d

	3D Players:
	  Available: %d
	  Active: %d

	Total Players: %d / %d

	Active Layered Events: %d
	Parameters: %d

	BPM: %.1f
	Beat: %d/%d | Bar: %d
	""" % [
		stats.pool_2d_available,
		stats.active_2d,
		stats.pool_3d_available,
		stats.active_3d,
		stats.total_players,
		audio_controller.max_total_players,
		stats.layered_events,
		audio_controller._parameters.size(),
		audio_controller.global_bpm,
		audio_controller.get_current_beat() + 1,
		audio_controller.time_signature,
		audio_controller.get_current_bar()
	]

	pool_stats_label.text = stats_text

	# Update parameter list
	_update_param_list()
#endregion
