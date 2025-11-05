@tool
extends Control

## Audio Mixer UI Modern - Professional, polished interface with proper spacing

var editor_plugin: EditorPlugin = null
var current_event: Resource = null
var current_event_path: String = ""
var is_playing: bool = false
var param_sliders: Dictionary = {}

# Node references - updated for modern UI paths
@onready var event_tree: Tree = $MarginContainer/MainSplit/LeftPanel/MarginContainer/VBoxContainer/EventTree
@onready var search_bar: LineEdit = $MarginContainer/MainSplit/LeftPanel/MarginContainer/VBoxContainer/Header/SearchContainer/MarginContainer/HBoxContainer/SearchBar
@onready var new_event_button: MenuButton = $MarginContainer/MainSplit/LeftPanel/MarginContainer/VBoxContainer/Header/Toolbar/NewEventButton
@onready var delete_button: Button = $MarginContainer/MainSplit/LeftPanel/MarginContainer/VBoxContainer/Header/Toolbar/DeleteButton
@onready var refresh_button: Button = $MarginContainer/MainSplit/LeftPanel/MarginContainer/VBoxContainer/Header/Toolbar/RefreshButton

@onready var event_name_label: Label = $MarginContainer/MainSplit/CenterRightSplit/CenterPanel/MarginContainer/VBoxContainer/EventHeader/MarginContainer/HBoxContainer/EventNameLabel
@onready var event_icon: Label = $MarginContainer/MainSplit/CenterRightSplit/CenterPanel/MarginContainer/VBoxContainer/EventHeader/MarginContainer/HBoxContainer/EventIcon
@onready var save_button: Button = $MarginContainer/MainSplit/CenterRightSplit/CenterPanel/MarginContainer/VBoxContainer/EventHeader/MarginContainer/HBoxContainer/SaveButton

@onready var editor_tabs: TabContainer = $MarginContainer/MainSplit/CenterRightSplit/CenterPanel/MarginContainer/VBoxContainer/EditorTabContainer
@onready var properties_container: VBoxContainer = $MarginContainer/MainSplit/CenterRightSplit/CenterPanel/MarginContainer/VBoxContainer/EditorTabContainer/Properties/MarginContainer/PropertiesContainer
@onready var layers_container: VBoxContainer = $MarginContainer/MainSplit/CenterRightSplit/CenterPanel/MarginContainer/VBoxContainer/EditorTabContainer/Layers/MarginContainer/LayersContainer
@onready var stems_container: VBoxContainer = $MarginContainer/MainSplit/CenterRightSplit/CenterPanel/MarginContainer/VBoxContainer/EditorTabContainer/Stems/MarginContainer/StemsContainer
@onready var snapshots_container: VBoxContainer = $MarginContainer/MainSplit/CenterRightSplit/CenterPanel/MarginContainer/VBoxContainer/EditorTabContainer/Snapshots/MarginContainer/SnapshotsContainer

@onready var test_button: Button = $MarginContainer/MainSplit/CenterRightSplit/RightPanel/PlaybackPanel/MarginContainer/VBoxContainer/ButtonContainer/TestButton
@onready var stop_button: Button = $MarginContainer/MainSplit/CenterRightSplit/RightPanel/PlaybackPanel/MarginContainer/VBoxContainer/ButtonContainer/StopButton
@onready var status_label: Label = $MarginContainer/MainSplit/CenterRightSplit/RightPanel/PlaybackPanel/MarginContainer/VBoxContainer/StatusLabel

@onready var parameters_container: VBoxContainer = $MarginContainer/MainSplit/CenterRightSplit/RightPanel/ParametersPanel/MarginContainer/VBoxContainer/ParametersScroll/ParametersContainer
@onready var no_params_label: Label = $MarginContainer/MainSplit/CenterRightSplit/RightPanel/ParametersPanel/MarginContainer/VBoxContainer/ParametersScroll/NoParamsLabel
@onready var create_param_button: Button = $MarginContainer/MainSplit/CenterRightSplit/RightPanel/ParametersPanel/MarginContainer/VBoxContainer/CreateParamButton

@onready var stats_label: Label = $MarginContainer/MainSplit/CenterRightSplit/RightPanel/StatsPanel/MarginContainer/VBoxContainer/StatsScroll/StatsLabel
@onready var bpm_spinbox: SpinBox = $MarginContainer/MainSplit/CenterRightSplit/RightPanel/StatsPanel/MarginContainer/VBoxContainer/BPMContainer/BPMSpinBox
@onready var beat_label: Label = $MarginContainer/MainSplit/CenterRightSplit/RightPanel/StatsPanel/MarginContainer/VBoxContainer/BeatLabel

@onready var new_event_dialog: ConfirmationDialog = $NewEventDialog
@onready var event_name_edit: LineEdit = $NewEventDialog/VBoxContainer/NameContainer/EventNameEdit
@onready var location_edit: LineEdit = $NewEventDialog/VBoxContainer/LocationContainer/LocationEdit

const AUDIO_EVENTS_PATH = "res://audio_events/"

var _pending_event_type: int = 0

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_setup_keyboard_shortcuts()
	refresh_event_list()
	_start_update_timer()

	print("🎨 Audio Mixer UI Modern initialized")

func _setup_ui() -> void:
	# Setup event tree
	if event_tree:
		event_tree.set_column_title(0, "Name")
		event_tree.set_column_title(1, "Type")
		event_tree.set_column_expand_ratio(0, 3)
		event_tree.set_column_expand_ratio(1, 1)

	# Setup new event menu
	if new_event_button:
		var popup = new_event_button.get_popup()
		popup.clear()
		popup.add_item("🎵 Simple Audio Event", 0)
		popup.add_item("🎚 Layered Event", 1)
		popup.add_item("🎼 Music Event", 2)
		popup.add_item("📸 Mixer Snapshot", 3)

	# Setup context menu and tooltips
	_setup_context_menu()
	_setup_tooltips()

func _connect_signals() -> void:
	# Left panel
	if event_tree:
		event_tree.item_selected.connect(_on_event_selected)
	if search_bar:
		search_bar.text_changed.connect(_on_search_changed)
	if new_event_button:
		new_event_button.get_popup().id_pressed.connect(_on_new_event_type_selected)
	if delete_button:
		delete_button.pressed.connect(_show_delete_confirmation)
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
	# Update playback status with color
	if is_playing and status_label:
		status_label.text = "▶ Playing..."
		status_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	else:
		status_label.text = "Ready"
		status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))

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
# NOTE: Keeping the same property editor code from V2, just with updated container paths

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
	_add_section_header(properties_container, "Event Identity")
	_add_text_field(properties_container, "Event Name", event.event_name, func(val): event.event_name = val)
	_add_text_field(properties_container, "Category", event.category, func(val): event.category = val)

	_add_section_header(properties_container, "Audio Streams")
	_add_stream_list(properties_container, event)

func _build_layered_event_editor() -> void:
	var event: LayeredAudioEvent = current_event
	_add_section_header(layers_container, "Event Settings")
	_add_text_field(layers_container, "Event Name", event.event_name, func(val): event.event_name = val)

func _build_music_event_editor() -> void:
	var event: MusicEvent = current_event
	_add_section_header(stems_container, "Music Settings")
	_add_text_field(stems_container, "Music Name", event.music_name, func(val): event.music_name = val)

func _build_snapshot_editor() -> void:
	var snapshot: AudioSnapshot = current_event
	_add_section_header(snapshots_container, "Snapshot Settings")
	_add_text_field(snapshots_container, "Snapshot Name", snapshot.snapshot_name, func(val): snapshot.snapshot_name = val)

func _add_section_header(container: Control, title: String) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	container.add_child(spacer)

	var label = Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	container.add_child(label)

	var sep = HSeparator.new()
	container.add_child(sep)

func _add_text_field(container: Control, label_text: String, value: String, on_changed: Callable) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var lbl = Label.new()
	lbl.text = label_text + ":"
	lbl.custom_minimum_size = Vector2(140, 0)
	lbl.add_theme_font_size_override("font_size", 12)
	hbox.add_child(lbl)

	var edit = LineEdit.new()
	edit.text = value
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.add_theme_font_size_override("font_size", 12)
	edit.text_changed.connect(on_changed)
	hbox.add_child(edit)

	container.add_child(hbox)

#endregion

#region Parameters Panel

func _update_parameters_panel() -> void:
	for child in parameters_container.get_children():
		child.queue_free()
	param_sliders.clear()

	if not current_event:
		no_params_label.visible = true
		return

	var param_names: Array = []

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

	for param_name in param_names:
		_create_parameter_slider(param_name)

func _create_parameter_slider(param_name: String) -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var header = HBoxContainer.new()
	var name_label = Label.new()
	name_label.text = param_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	header.add_child(name_label)

	var value_label = Label.new()
	value_label.text = "0.50"
	value_label.custom_minimum_size = Vector2(50, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	header.add_child(value_label)
	vbox.add_child(header)

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

	if not audio_controller.get_parameter(param_name):
		audio_controller.create_parameter(param_name, 0.0, 1.0, value)

	audio_controller.set_parameter(param_name, value)

func _on_create_param_pressed() -> void:
	print("⚠ Create parameter dialog not implemented yet")

#endregion

#region Playback Control

func _on_test_pressed() -> void:
	if not current_event:
		_show_status("⚠ No event selected", Color.ORANGE)
		return

	if not has_node("/root/AudioController"):
		_show_status("⚠ AudioController not found", Color.RED)
		return

	var audio_controller = get_node("/root/AudioController")

	if current_event is AudioEvent:
		audio_controller.play_event(current_event)
		is_playing = true
		_show_status("Playing AudioEvent", Color.GREEN)
		await get_tree().create_timer(0.5).timeout
		is_playing = false

	elif current_event is LayeredAudioEvent:
		if not current_event.control_parameter.is_empty():
			if not audio_controller.get_parameter(current_event.control_parameter):
				audio_controller.create_parameter(current_event.control_parameter, 0.0, 1.0, 0.5)
		audio_controller.play_layered_event(current_event)
		is_playing = true
		_show_status("Playing LayeredEvent", Color.GREEN)

	elif current_event is MusicEvent:
		if has_node("/root/MusicManager"):
			var music_manager = get_node("/root/MusicManager")
			music_manager.play_music(current_event, 1.0)
			is_playing = true
			_show_status("Playing Music", Color.GREEN)
		else:
			_show_status("⚠ MusicManager not found", Color.RED)

	elif current_event is AudioSnapshot:
		audio_controller.register_snapshot(current_event)
		audio_controller.apply_snapshot(current_event.snapshot_name, 0.5)
		is_playing = true
		_show_status("Applied Snapshot", Color.GREEN)
		await get_tree().create_timer(1.0).timeout
		is_playing = false

func _on_stop_pressed() -> void:
	is_playing = false

	if has_node("/root/MusicManager"):
		var music_manager = get_node("/root/MusicManager")
		music_manager.stop_music(0.5)

	_show_status("Stopped", Color.GRAY)

func _show_status(message: String, color: Color, auto_clear: bool = true) -> void:
	if status_label:
		status_label.text = message
		status_label.add_theme_color_override("font_color", color)

		# Add a subtle scale animation for visual feedback
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.tween_property(status_label, "scale", Vector2(1.05, 1.05), 0.1)
		tween.tween_property(status_label, "scale", Vector2(1.0, 1.0), 0.15)

		# Auto-clear after 3 seconds for success messages
		if auto_clear and (color == Color.GREEN or color == Color.CYAN):
			await get_tree().create_timer(3.0).timeout
			if status_label and status_label.text == message:
				_fade_out_status()

func _fade_out_status() -> void:
	if status_label:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(status_label, "modulate:a", 0.0, 0.5)
		await tween.finished
		if status_label:
			status_label.text = "Ready"
			status_label.add_theme_color_override("font_color", Color.WHITE)
			status_label.modulate.a = 1.0

#endregion

#region Event Creation

func _on_new_event_type_selected(id: int) -> void:
	_pending_event_type = id
	new_event_dialog.popup_centered()
	event_name_edit.grab_focus()

func _on_new_event_confirmed() -> void:
	var event_name = event_name_edit.text.strip_edges()
	if event_name.is_empty():
		event_name = "new_event"

	var save_path = location_edit.text
	if not save_path.ends_with("/"):
		save_path += "/"
	save_path += event_name + ".tres"

	var new_event: Resource = null
	match _pending_event_type:
		0:
			new_event = AudioEvent.new()
			new_event.event_name = event_name
		1:
			new_event = LayeredAudioEvent.new()
			new_event.event_name = event_name
		2:
			new_event = MusicEvent.new()
			new_event.music_name = event_name
		3:
			new_event = AudioSnapshot.new()
			new_event.snapshot_name = event_name

	DirAccess.make_dir_recursive_absolute(location_edit.text)
	var err = ResourceSaver.save(new_event, save_path)

	if err == OK:
		print("✅ Created: ", save_path)
		refresh_event_list()
		load_event(save_path)
		_show_status("Event created", Color.GREEN)
	else:
		print("❌ Failed to create event: ", err)
		_show_status("Failed to create event", Color.RED)

func _on_delete_pressed() -> void:
	if not current_event or current_event_path.is_empty():
		return

	DirAccess.remove_absolute(current_event_path)
	print("🗑 Deleted: ", current_event_path)
	current_event = null
	current_event_path = ""
	refresh_event_list()
	_update_header()
	_show_status("Event deleted", Color.ORANGE)

func _on_save_pressed() -> void:
	if not current_event or current_event_path.is_empty():
		return

	var err = ResourceSaver.save(current_event, current_event_path)
	if err == OK:
		print("💾 Saved: ", current_event_path)
		_show_status("✅ Saved!", Color.GREEN)
		await get_tree().create_timer(2.0).timeout
		if status_label:
			_show_status("Ready", Color.WHITE)
	else:
		print("❌ Save failed: ", err)
		_show_status("❌ Save failed!", Color.RED)

#endregion

#region Stats & BPM

func _update_stats() -> void:
	if not has_node("/root/AudioController"):
		return

	var audio_controller = get_node("/root/AudioController")
	var stats = audio_controller.get_pool_stats()

	var stats_text = """2D: %d/%d active
3D: %d/%d active
Total: %d/%d

Layered: %d
Params: %d""" % [
		stats.active_2d, stats.pool_2d_available + stats.active_2d,
		stats.active_3d, stats.pool_3d_available + stats.active_3d,
		stats.total_players, audio_controller.max_total_players,
		stats.layered_events,
		audio_controller._parameters.size()
	]

	stats_label.text = stats_text

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
	beat_label.text = "Beat: %d/%d | Bar: %d" % [beat_num + 1, audio_controller.time_signature, audio_controller.get_current_bar()]

	beat_label.add_theme_color_override("font_color", Color.YELLOW)
	await get_tree().create_timer(0.08).timeout
	if beat_label:
		beat_label.add_theme_color_override("font_color", Color.WHITE)

func _on_bar(bar_num: int) -> void:
	pass

#endregion

#region Keyboard Shortcuts

func _setup_keyboard_shortcuts() -> void:
	# Make this control grab keyboard input
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		var ctrl = event.ctrl_pressed or event.command_or_control_pressed
		var shift = event.shift_pressed

		# Ctrl+S: Save current event
		if ctrl and event.keycode == KEY_S and not event.echo:
			accept_event()
			_on_save_pressed()

		# Ctrl+N: New event menu
		elif ctrl and event.keycode == KEY_N and not event.echo:
			accept_event()
			if new_event_button:
				new_event_button.get_popup().popup(Rect2(new_event_button.global_position, Vector2.ZERO))

		# Ctrl+D: Duplicate current event
		elif ctrl and event.keycode == KEY_D and not event.echo:
			accept_event()
			_duplicate_current_event()

		# Delete: Delete current event
		elif event.keycode == KEY_DELETE and not event.echo:
			accept_event()
			_show_delete_confirmation()

		# F2: Rename current event
		elif event.keycode == KEY_F2 and not event.echo:
			accept_event()
			_start_rename_event()

		# Space: Play/Stop preview
		elif event.keycode == KEY_SPACE and not event.echo and not search_bar.has_focus():
			accept_event()
			if is_playing:
				_on_stop_pressed()
			else:
				_on_test_pressed()

		# Ctrl+F: Focus search
		elif ctrl and event.keycode == KEY_F and not event.echo:
			accept_event()
			if search_bar:
				search_bar.grab_focus()
				search_bar.select_all()

		# Ctrl+C: Copy event
		elif ctrl and event.keycode == KEY_C and not event.echo:
			accept_event()
			_copy_current_event()

		# Ctrl+V: Paste event
		elif ctrl and event.keycode == KEY_V and not event.echo:
			accept_event()
			_paste_event()

#endregion

#region Context Menu

var _context_menu: PopupMenu = null
var _clipboard_event: Resource = null
var _clipboard_event_name: String = ""

func _setup_context_menu() -> void:
	_context_menu = PopupMenu.new()
	_context_menu.name = "EventContextMenu"
	add_child(_context_menu)

	_context_menu.add_item("Rename", 0)
	_context_menu.add_item("Duplicate", 1)
	_context_menu.add_separator()
	_context_menu.add_item("Copy", 2)
	_context_menu.add_item("Paste", 3)
	_context_menu.add_separator()
	_context_menu.add_item("Delete", 4)
	_context_menu.add_separator()
	_context_menu.add_item("Show in FileSystem", 5)

	_context_menu.id_pressed.connect(_on_context_menu_item)

	# Connect right-click to tree
	if event_tree:
		event_tree.gui_input.connect(_on_tree_gui_input)

func _on_tree_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var selected = event_tree.get_selected()
			if selected and selected.get_metadata(0):
				_context_menu.position = get_viewport().get_mouse_position()
				_context_menu.popup()

func _on_context_menu_item(id: int) -> void:
	match id:
		0: # Rename
			_start_rename_event()
		1: # Duplicate
			_duplicate_current_event()
		2: # Copy
			_copy_current_event()
		3: # Paste
			_paste_event()
		4: # Delete
			_show_delete_confirmation()
		5: # Show in FileSystem
			_show_in_filesystem()

#endregion

#region Event Operations (Rename, Duplicate, Copy, Paste)

var _rename_dialog: ConfirmationDialog = null
var _rename_edit: LineEdit = null

func _start_rename_event() -> void:
	if not current_event or current_event_path.is_empty():
		_show_status("⚠ No event selected", Color.ORANGE)
		return

	# Create rename dialog if it doesn't exist
	if not _rename_dialog:
		_rename_dialog = ConfirmationDialog.new()
		_rename_dialog.title = "Rename Event"
		_rename_dialog.size = Vector2(400, 120)

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)

		var label = Label.new()
		label.text = "New name:"
		vbox.add_child(label)

		_rename_edit = LineEdit.new()
		_rename_edit.placeholder_text = "Enter new event name"
		vbox.add_child(_rename_edit)

		_rename_dialog.add_child(vbox)
		_rename_dialog.confirmed.connect(_on_rename_confirmed)
		add_child(_rename_dialog)

	# Set current name
	var current_name = current_event_path.get_file().get_basename()
	_rename_edit.text = current_name
	_rename_dialog.popup_centered()
	_rename_edit.grab_focus()
	_rename_edit.select_all()

func _on_rename_confirmed() -> void:
	if not current_event or current_event_path.is_empty():
		return

	var new_name = _rename_edit.text.strip_edges()
	if new_name.is_empty():
		_show_status("⚠ Name cannot be empty", Color.ORANGE)
		return

	var dir_path = current_event_path.get_base_dir()
	var new_path = dir_path.path_join(new_name + ".tres")

	# Check if file already exists
	if FileAccess.file_exists(new_path) and new_path != current_event_path:
		_show_status("⚠ File already exists", Color.ORANGE)
		return

	# Rename the file
	var err = DirAccess.rename_absolute(current_event_path, new_path)
	if err == OK:
		# Update event name property
		if current_event.has("event_name"):
			current_event.event_name = new_name
		elif current_event.has("music_name"):
			current_event.music_name = new_name
		elif current_event.has("snapshot_name"):
			current_event.snapshot_name = new_name

		ResourceSaver.save(current_event, new_path)
		current_event_path = new_path
		refresh_event_list()
		_update_header()
		_show_status("✅ Renamed to: " + new_name, Color.GREEN)
		print("✅ Renamed: ", new_path)
	else:
		_show_status("❌ Rename failed", Color.RED)

func _duplicate_current_event() -> void:
	if not current_event or current_event_path.is_empty():
		_show_status("⚠ No event selected", Color.ORANGE)
		return

	# Create a duplicate
	var original_name = current_event_path.get_file().get_basename()
	var dir_path = current_event_path.get_base_dir()
	var new_name = original_name + "_copy"
	var new_path = dir_path.path_join(new_name + ".tres")

	# Find unique name
	var counter = 1
	while FileAccess.file_exists(new_path):
		new_name = original_name + "_copy" + str(counter)
		new_path = dir_path.path_join(new_name + ".tres")
		counter += 1

	# Duplicate the resource
	var duplicated = current_event.duplicate(true)

	# Update the name property
	if duplicated.has("event_name"):
		duplicated.event_name = new_name
	elif duplicated.has("music_name"):
		duplicated.music_name = new_name
	elif duplicated.has("snapshot_name"):
		duplicated.snapshot_name = new_name

	var err = ResourceSaver.save(duplicated, new_path)
	if err == OK:
		refresh_event_list()
		load_event(new_path)
		_show_status("✅ Duplicated: " + new_name, Color.GREEN)
		print("✅ Duplicated to: ", new_path)
	else:
		_show_status("❌ Duplicate failed", Color.RED)

func _copy_current_event() -> void:
	if not current_event or current_event_path.is_empty():
		_show_status("⚠ No event selected", Color.ORANGE)
		return

	_clipboard_event = current_event.duplicate(true)
	_clipboard_event_name = current_event_path.get_file().get_basename()
	_show_status("📋 Copied: " + _clipboard_event_name, Color.CYAN)

func _paste_event() -> void:
	if not _clipboard_event:
		_show_status("⚠ Clipboard is empty", Color.ORANGE)
		return

	var selected = event_tree.get_selected()
	var target_dir = AUDIO_EVENTS_PATH

	# If a folder is selected, paste into it
	if selected:
		var meta = selected.get_metadata(0)
		if meta:
			target_dir = meta.get_base_dir()

	var new_name = _clipboard_event_name + "_paste"
	var new_path = target_dir.path_join(new_name + ".tres")

	# Find unique name
	var counter = 1
	while FileAccess.file_exists(new_path):
		new_name = _clipboard_event_name + "_paste" + str(counter)
		new_path = target_dir.path_join(new_name + ".tres")
		counter += 1

	# Save the pasted resource
	var pasted = _clipboard_event.duplicate(true)
	if pasted.has("event_name"):
		pasted.event_name = new_name
	elif pasted.has("music_name"):
		pasted.music_name = new_name
	elif pasted.has("snapshot_name"):
		pasted.snapshot_name = new_name

	var err = ResourceSaver.save(pasted, new_path)
	if err == OK:
		refresh_event_list()
		load_event(new_path)
		_show_status("✅ Pasted: " + new_name, Color.GREEN)
		print("✅ Pasted to: ", new_path)
	else:
		_show_status("❌ Paste failed", Color.RED)

func _show_in_filesystem() -> void:
	if not current_event_path.is_empty() and editor_plugin:
		var editor = editor_plugin.get_editor()
		if editor:
			var filesystem = editor.get_resource_filesystem()
			if filesystem:
				filesystem.scan()
				print("📂 Showing in FileSystem: ", current_event_path)

#endregion

#region Confirmation Dialogs

var _delete_confirmation: ConfirmationDialog = null

func _show_delete_confirmation() -> void:
	if not current_event or current_event_path.is_empty():
		_show_status("⚠ No event selected", Color.ORANGE)
		return

	# Create delete confirmation dialog if it doesn't exist
	if not _delete_confirmation:
		_delete_confirmation = ConfirmationDialog.new()
		_delete_confirmation.title = "Confirm Delete"
		_delete_confirmation.ok_button_text = "Delete"
		_delete_confirmation.size = Vector2(400, 120)
		_delete_confirmation.confirmed.connect(_on_delete_confirmed)
		add_child(_delete_confirmation)

	var event_name = current_event_path.get_file()
	_delete_confirmation.dialog_text = "Are you sure you want to delete:\n\n%s\n\nThis action cannot be undone." % event_name
	_delete_confirmation.popup_centered()

func _on_delete_confirmed() -> void:
	_on_delete_pressed()

#endregion

#region Drag and Drop for Audio Streams

func _add_stream_list(container: Control, event: AudioEvent) -> void:
	var stream_list_container = VBoxContainer.new()
	stream_list_container.add_theme_constant_override("separation", 4)

	# Add existing streams
	for i in range(event.streams.size()):
		var stream = event.streams[i]
		_add_stream_item(stream_list_container, event, i, stream)

	# Add "Drop Here" zone
	var drop_zone = _create_drop_zone(event)
	stream_list_container.add_child(drop_zone)

	container.add_child(stream_list_container)

func _add_stream_item(container: Control, event: AudioEvent, index: int, stream: AudioStream) -> void:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	# Icon
	var icon = Label.new()
	icon.text = "🎵"
	hbox.add_child(icon)

	# Stream name
	var label = Label.new()
	if stream:
		label.text = stream.resource_path.get_file()
	else:
		label.text = "(empty)"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 11)
	hbox.add_child(label)

	# Remove button
	var remove_btn = Button.new()
	remove_btn.text = "×"
	remove_btn.custom_minimum_size = Vector2(24, 24)
	remove_btn.pressed.connect(func():
		event.streams.remove_at(index)
		_build_property_editor()
		_show_status("Stream removed", Color.ORANGE)
	)
	hbox.add_child(remove_btn)

	container.add_child(hbox)

func _create_drop_zone(event: AudioEvent) -> Control:
	var drop_panel = PanelContainer.new()
	drop_panel.custom_minimum_size = Vector2(0, 60)

	# Create a StyleBox for the drop zone
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.5)
	style.border_color = Color(0.4, 0.6, 1.0, 0.5)
	style.set_border_width_all(2)
	style.border_blend = true
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	drop_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var drop_label = Label.new()
	drop_label.text = "Drag audio files here (.wav, .ogg, .mp3)"
	drop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drop_label.add_theme_font_size_override("font_size", 11)
	drop_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9, 0.8))
	vbox.add_child(drop_label)

	drop_panel.add_child(vbox)

	# Enable drag-and-drop
	drop_panel.set_drag_forwarding(
		Callable(),
		func(at_position: Vector2) -> bool:
			return _can_drop_data_stream(at_position, drop_panel)
		,
		func(at_position: Vector2):
			_drop_data_stream(at_position, drop_panel, event)
	)

	return drop_panel

func _can_drop_data_stream(at_position: Vector2, drop_panel: Control) -> bool:
	var preview = drop_panel.get_viewport().gui_get_drag_data()
	if preview is Dictionary:
		if preview.has("type") and preview["type"] == "files":
			var files = preview["files"]
			for file in files:
				if file.ends_with(".wav") or file.ends_with(".ogg") or file.ends_with(".mp3"):
					return true
	return false

func _drop_data_stream(at_position: Vector2, drop_panel: Control, event: AudioEvent) -> void:
	var data = drop_panel.get_viewport().gui_get_drag_data()
	if data is Dictionary and data.has("type") and data["type"] == "files":
		var files = data["files"]
		var added_count = 0

		for file in files:
			if file.ends_with(".wav") or file.ends_with(".ogg") or file.ends_with(".mp3"):
				var stream = load(file) as AudioStream
				if stream:
					event.streams.append(stream)
					added_count += 1
					print("✅ Added stream: ", file)

		if added_count > 0:
			_build_property_editor()
			_show_status("✅ Added %d audio stream(s)" % added_count, Color.GREEN)
		else:
			_show_status("⚠ No valid audio files", Color.ORANGE)

#endregion

#region Tooltips

func _setup_tooltips() -> void:
	# Left Panel
	if search_bar:
		search_bar.tooltip_text = "Search events (Ctrl+F)"
	if new_event_button:
		new_event_button.tooltip_text = "Create new audio event (Ctrl+N)"
	if delete_button:
		delete_button.tooltip_text = "Delete selected event (Delete)"
	if refresh_button:
		refresh_button.tooltip_text = "Refresh event list"
	if event_tree:
		event_tree.tooltip_text = "Right-click for more options"

	# Center Panel
	if save_button:
		save_button.tooltip_text = "Save current event (Ctrl+S)"

	# Right Panel
	if test_button:
		test_button.tooltip_text = "Test play event (Space)"
	if stop_button:
		stop_button.tooltip_text = "Stop playback (Space)"
	if create_param_button:
		create_param_button.tooltip_text = "Create new parameter"
	if bpm_spinbox:
		bpm_spinbox.tooltip_text = "Global BPM for music synchronization"

#endregion
