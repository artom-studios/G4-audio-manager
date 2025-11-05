extends Node

## AudioController - Main autoload singleton for the audio system
## Handles pooling, parameters, layered events, BPM sync, and mixer snapshots

signal beat(beat_number: int)
signal bar(bar_number: int)
signal bpm_changed(new_bpm: float)
signal parameter_changed(param_name: String, value: float)
signal snapshot_changed(snapshot_name: String)

#region Configuration
@export_group("Pooling")
## Initial size of 2D player pool
@export_range(5, 100, 1) var initial_pool_size_2d: int = 20

## Initial size of 3D player pool
@export_range(5, 100, 1) var initial_pool_size_3d: int = 20

## Auto-expand pool when exhausted
@export var auto_expand_pool: bool = true

## Maximum total players (prevents infinite growth)
@export_range(10, 500, 1) var max_total_players: int = 100
#endregion

#region BPM Sync
@export_group("BPM Synchronization")
## Enable global BPM synchronization
@export var enable_bpm_sync: bool = true

## Global BPM (beats per minute)
@export_range(30.0, 300.0, 0.1) var global_bpm: float = 120.0:
	set(value):
		var old_bpm = global_bpm
		global_bpm = clampf(value, 30.0, 300.0)
		_beat_duration = 60.0 / global_bpm
		_bar_duration = _beat_duration * time_signature
		if abs(global_bpm - old_bpm) > 0.01:
			bpm_changed.emit(global_bpm)

## Time signature (beats per bar)
@export_range(1, 16, 1) var time_signature: int = 4:
	set(value):
		time_signature = clampi(value, 1, 16)
		_bar_duration = _beat_duration * time_signature

## Start BPM clock on ready
@export var auto_start_bpm_clock: bool = false

## Metronome click sound (optional, for debugging)
@export var metronome_click_event: AudioEvent = null

## Enable metronome (for testing)
@export var metronome_enabled: bool = false
#endregion

#region Pools
var _pool_2d: Array[AudioStreamPlayer2D] = []
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _active_players_2d: Array[AudioStreamPlayer2D] = []
var _active_players_3d: Array[AudioStreamPlayer3D] = []
var _player_event_map: Dictionary = {}  # Maps player -> event for instance tracking
#endregion

#region Parameters
var _parameters: Dictionary = {}  # String -> AudioParameter
#endregion

#region Layered Events
var _active_layered_events: Dictionary = {}  # event -> LayeredEventInstance
#endregion

#region Music
var _current_music: MusicEvent = null
var _music_players: Array = []  # Array of {player, stem_index, stem}
var _music_playback_position: float = 0.0
var _music_is_playing: bool = false
#endregion

#region Snapshots
var _snapshots: Dictionary = {}  # String -> AudioSnapshot
var _active_snapshot: AudioSnapshot = null
var _snapshot_transition_time: float = 0.0
var _snapshot_transition_duration: float = 0.0
var _previous_snapshot: AudioSnapshot = null
#endregion

#region BPM Clock
var _bpm_clock_running: bool = false
var _bpm_time: float = 0.0
var _current_beat: int = 0
var _current_bar: int = 0
var _beat_duration: float = 0.5  # seconds per beat
var _bar_duration: float = 2.0   # seconds per bar
var _next_beat_time: float = 0.0
var _next_bar_time: float = 0.0
var _quantized_event_queue: Array = []  # Events waiting for quantized start
#endregion

#region Initialization
func _ready() -> void:
	# Set process priority to run early
	process_priority = -100

	# Initialize pools
	_initialize_pools()

	# Initialize BPM clock
	_beat_duration = 60.0 / global_bpm
	_bar_duration = _beat_duration * time_signature

	if auto_start_bpm_clock:
		start_bpm_clock()

	print("AudioController initialized - 2D Pool: %d, 3D Pool: %d" % [_pool_2d.size(), _pool_3d.size()])

func _initialize_pools() -> void:
	# Create 2D players
	for i in range(initial_pool_size_2d):
		var player = AudioStreamPlayer2D.new()
		player.name = "PooledPlayer2D_%d" % i
		add_child(player)
		player.finished.connect(_on_player_2d_finished.bind(player))
		_pool_2d.append(player)

	# Create 3D players
	for i in range(initial_pool_size_3d):
		var player = AudioStreamPlayer3D.new()
		player.name = "PooledPlayer3D_%d" % i
		add_child(player)
		player.finished.connect(_on_player_3d_finished.bind(player))
		_pool_3d.append(player)

func _process(delta: float) -> void:
	# Update BPM clock
	if _bpm_clock_running:
		_update_bpm_clock(delta)

	# Update parameters
	for param in _parameters.values():
		param.update(delta)

	# Update layered events
	_update_layered_events(delta)

	# Update music
	if _music_is_playing:
		_update_music(delta)

	# Update snapshot transitions
	if _snapshot_transition_time > 0.0:
		_update_snapshot_transition(delta)

	# Process quantized event queue
	_process_quantized_queue()
#endregion

#region BPM Clock
## Start the global BPM clock
func start_bpm_clock() -> void:
	_bpm_clock_running = true
	_bpm_time = 0.0
	_current_beat = 0
	_current_bar = 0
	_next_beat_time = _beat_duration
	_next_bar_time = _bar_duration
	print("BPM Clock started at %.1f BPM" % global_bpm)

## Stop the BPM clock
func stop_bpm_clock() -> void:
	_bpm_clock_running = false
	print("BPM Clock stopped")

## Reset the BPM clock to beat 0
func reset_bpm_clock() -> void:
	_bpm_time = 0.0
	_current_beat = 0
	_current_bar = 0
	_next_beat_time = _beat_duration
	_next_bar_time = _bar_duration

## Set BPM with optional smooth transition
func set_bpm(new_bpm: float, transition_time: float = 0.0) -> void:
	if transition_time <= 0.0:
		global_bpm = new_bpm
	else:
		# Smooth BPM transition (would need tweening)
		var tween = create_tween()
		tween.tween_property(self, "global_bpm", new_bpm, transition_time)

## Get current beat number (within bar)
func get_current_beat() -> int:
	return _current_beat % time_signature

## Get current bar number
func get_current_bar() -> int:
	return _current_bar

## Get time until next beat
func get_time_to_next_beat() -> float:
	return max(0.0, _next_beat_time - _bpm_time)

## Get time until next bar
func get_time_to_next_bar() -> float:
	return max(0.0, _next_bar_time - _bpm_time)

## Get normalized position within current beat (0.0 to 1.0)
func get_beat_phase() -> float:
	var beat_start = _current_beat * _beat_duration
	var phase = (_bpm_time - beat_start) / _beat_duration
	return clampf(phase, 0.0, 1.0)

## Get normalized position within current bar (0.0 to 1.0)
func get_bar_phase() -> float:
	var bar_start = _current_bar * _bar_duration
	var phase = (_bpm_time - bar_start) / _bar_duration
	return clampf(phase, 0.0, 1.0)

func _update_bpm_clock(delta: float) -> void:
	_bpm_time += delta

	# Check for beat
	while _bpm_time >= _next_beat_time:
		_current_beat += 1
		_next_beat_time += _beat_duration
		beat.emit(_current_beat % time_signature)

		# Metronome click
		if metronome_enabled and metronome_click_event:
			play_event(metronome_click_event)

	# Check for bar
	while _bpm_time >= _next_bar_time:
		_current_bar += 1
		_next_bar_time += _bar_duration
		bar.emit(_current_bar)
#endregion

#region Parameters
## Create or get a parameter
func create_parameter(param_name: String, min_val: float = 0.0, max_val: float = 1.0, default_val: float = 0.0) -> AudioParameter:
	if _parameters.has(param_name):
		return _parameters[param_name]

	var param = AudioParameter.new()
	param.parameter_name = param_name
	param.min_value = min_val
	param.max_value = max_val
	param.default_value = default_val
	param.current_value = default_val
	param.value_changed.connect(_on_parameter_changed.bind(param_name))

	_parameters[param_name] = param
	print("Created parameter: %s [%.2f - %.2f]" % [param_name, min_val, max_val])
	return param

## Get a parameter by name
func get_parameter(param_name: String) -> AudioParameter:
	return _parameters.get(param_name, null)

## Set parameter value instantly
func set_parameter(param_name: String, value: float) -> void:
	var param = get_parameter(param_name)
	if param:
		param.set_value(value)
	else:
		push_warning("Parameter '%s' does not exist" % param_name)

## Set parameter value with interpolation
func set_parameter_smooth(param_name: String, value: float) -> void:
	var param = get_parameter(param_name)
	if param:
		param.set_value_smooth(value)
	else:
		push_warning("Parameter '%s' does not exist" % param_name)

## Get parameter value
func get_parameter_value(param_name: String) -> float:
	var param = get_parameter(param_name)
	return param.current_value if param else 0.0

func _on_parameter_changed(value: float, param_name: String) -> void:
	parameter_changed.emit(param_name, value)
#endregion

#region Simple Event Playback
## Play a simple AudioEvent
func play_event(event: AudioEvent, position: Vector3 = Vector3.ZERO) -> bool:
	if not event or not event.is_valid():
		push_warning("Invalid AudioEvent")
		return false

	# Check cooldown
	if not event.can_play():
		return false

	# Check max instances
	if event.is_at_max_instances():
		if event.enable_voice_stealing:
			_steal_voice(event)
		else:
			return false

	# Get player from pool
	var player = _get_player_from_pool(event.spatial_mode == AudioEvent.SpatialMode.MODE_3D)
	if not player:
		push_warning("No available players in pool")
		return false

	# Get random stream
	var stream = event.get_random_stream()
	if not stream:
		return false

	# Setup player
	_setup_player(player, event, stream, position)

	# Play with optional delay
	if event.delay > 0.0:
		await get_tree().create_timer(event.delay).timeout

	player.play()

	# Track instance
	event._active_instances += 1
	event.mark_played()
	_player_event_map[player] = event

	# Handle fade in
	if event.fade_in_duration > 0.0:
		_fade_in_player(player, event.fade_in_duration)

	return true

## Play event quantized to next beat/bar
func play_event_quantized(event: AudioEvent, quantize_to_bar: bool = false, position: Vector3 = Vector3.ZERO) -> void:
	if not enable_bpm_sync or not _bpm_clock_running:
		play_event(event, position)
		return

	var wait_time = get_time_to_next_bar() if quantize_to_bar else get_time_to_next_beat()
	_quantized_event_queue.append({
		"event": event,
		"position": position,
		"trigger_time": _bpm_time + wait_time
	})

func _process_quantized_queue() -> void:
	var i = 0
	while i < _quantized_event_queue.size():
		var queued = _quantized_event_queue[i]
		if _bpm_time >= queued.trigger_time:
			play_event(queued.event, queued.position)
			_quantized_event_queue.remove_at(i)
		else:
			i += 1

func _setup_player(player: Node, event: AudioEvent, stream: AudioStream, position: Vector3) -> void:
	player.stream = stream
	player.volume_db = event.get_random_volume_db()
	player.pitch_scale = event.get_random_pitch()
	player.bus = event.bus_name

	# Handle looping
	if event.playback_mode == AudioEvent.PlaybackMode.LOOPING:
		# Note: Some stream types have max_loop property
		pass

	# Random start position
	if event.random_start_position and stream.get_length() > 0.0:
		player.play()
		player.seek(randf() * stream.get_length())
		player.stop()

	# 3D specific setup
	if player is AudioStreamPlayer3D:
		player.position = position
		player.max_distance = event.max_distance
		player.unit_size = event.unit_size
		player.attenuation_model = event.attenuation_model
		player.doppler_tracking = event.doppler_tracking

func _fade_in_player(player: Node, duration: float) -> void:
	var target_volume = player.volume_db
	player.volume_db = -80.0
	var tween = create_tween()
	tween.tween_property(player, "volume_db", target_volume, duration)

func _steal_voice(event: AudioEvent) -> void:
	# Find lowest priority active sound and stop it
	var lowest_priority_player = null
	var lowest_priority = event.priority

	for player in _active_players_2d + _active_players_3d:
		if player in _player_event_map:
			var active_event = _player_event_map[player]
			if active_event.priority < lowest_priority:
				lowest_priority = active_event.priority
				lowest_priority_player = player

	if lowest_priority_player:
		lowest_priority_player.stop()
#endregion

#region Layered Event Playback
## Play a layered audio event with parameter control
func play_layered_event(event: LayeredAudioEvent, position: Vector3 = Vector3.ZERO) -> bool:
	if not event or not event.is_valid():
		push_warning("Invalid LayeredAudioEvent")
		return false

	# Check max instances
	if event._active_instances >= event.max_concurrent_instances:
		return false

	# Get controlling parameter
	var control_param = get_parameter(event.control_parameter)
	if not control_param:
		push_warning("LayeredAudioEvent '%s' requires parameter '%s'" % [event.event_name, event.control_parameter])
		return false

	# Create instance
	var instance = {
		"event": event,
		"position": position,
		"layers": [],
		"parameter": control_param
	}

	# Create player for each layer
	for layer in event.layers:
		if not layer.enabled or layer.streams.is_empty():
			continue

		var player = _get_player_from_pool(event.spatial_mode == 1)
		if not player:
			continue

		var stream = layer.get_random_stream()
		if not stream:
			continue

		# Setup layer player
		player.stream = stream
		player.bus = event.bus_name
		player.pitch_scale = event.master_pitch * layer.pitch_offset
		player.volume_db = -80.0  # Start silent

		if player is AudioStreamPlayer3D:
			player.position = position
			player.max_distance = event.max_distance
			player.unit_size = event.unit_size
			player.attenuation_model = event.attenuation_model

		# Set looping
		if layer.looping and stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

		player.play()

		instance.layers.append({
			"player": player,
			"layer": layer,
			"target_volume": -80.0
		})

	# Track instance
	event._active_instances += 1
	_active_layered_events[event] = instance

	# Initial parameter update
	_update_layered_event_instance(instance, 0.0)

	return true

## Stop a layered event
func stop_layered_event(event: LayeredAudioEvent, fade_out_time: float = 0.5) -> void:
	if not _active_layered_events.has(event):
		return

	var instance = _active_layered_events[event]

	# Fade out all layers
	for layer_data in instance.layers:
		var player = layer_data.player
		if fade_out_time > 0.0:
			var tween = create_tween()
			tween.tween_property(player, "volume_db", -80.0, fade_out_time)
			tween.tween_callback(player.stop)
			tween.tween_callback(_return_player_to_pool.bind(player))
		else:
			player.stop()
			_return_player_to_pool(player)

	event._active_instances -= 1
	_active_layered_events.erase(event)

func _update_layered_events(delta: float) -> void:
	for instance in _active_layered_events.values():
		_update_layered_event_instance(instance, delta)

func _update_layered_event_instance(instance: Dictionary, delta: float) -> void:
	var event: LayeredAudioEvent = instance.event
	var param: AudioParameter = instance.parameter
	var param_value = param.current_value

	# Update pitch if follows parameter
	if event.pitch_follows_parameter:
		var pitch = event.get_parameter_pitch(param_value)
		for layer_data in instance.layers:
			layer_data.player.pitch_scale = pitch * layer_data.layer.pitch_offset

	# Update layer volumes based on parameter
	for layer_data in instance.layers:
		var layer: LayeredAudioEvent.AudioLayer = layer_data.layer
		var player: Node = layer_data.player

		var target_volume = layer.calculate_volume(param_value) + event.master_volume
		layer_data.target_volume = target_volume

		# Smooth volume transition
		if event.crossfade_time > 0.0 and delta > 0.0:
			var lerp_speed = delta / event.crossfade_time
			player.volume_db = lerpf(player.volume_db, target_volume, lerp_speed)
		else:
			player.volume_db = target_volume

	# Sync layer positions if enabled
	if event.sync_layers and instance.layers.size() > 1:
		var master_pos = instance.layers[0].player.get_playback_position()
		for i in range(1, instance.layers.size()):
			var player = instance.layers[i].player
			if abs(player.get_playback_position() - master_pos) > 0.1:
				player.seek(master_pos)
#endregion

#region Pool Management
func _get_player_from_pool(is_3d: bool) -> Node:
	var pool = _pool_3d if is_3d else _pool_2d
	var active = _active_players_3d if is_3d else _active_players_2d

	# Try to get from pool
	if not pool.is_empty():
		var player = pool.pop_back()
		active.append(player)
		return player

	# Auto-expand if enabled
	if auto_expand_pool:
		var total_players = _pool_2d.size() + _pool_3d.size() + _active_players_2d.size() + _active_players_3d.size()
		if total_players < max_total_players:
			var player = AudioStreamPlayer3D.new() if is_3d else AudioStreamPlayer2D.new()
			player.name = "DynamicPlayer_%d" % total_players
			add_child(player)
			player.finished.connect(_on_player_3d_finished.bind(player) if is_3d else _on_player_2d_finished.bind(player))
			active.append(player)
			print("Pool expanded: created new %s player" % ("3D" if is_3d else "2D"))
			return player

	return null

func _return_player_to_pool(player: Node) -> void:
	if player is AudioStreamPlayer2D:
		_active_players_2d.erase(player)
		if not _pool_2d.has(player):
			_pool_2d.append(player)
	elif player is AudioStreamPlayer3D:
		_active_players_3d.erase(player)
		if not _pool_3d.has(player):
			_pool_3d.append(player)

	# Clean up tracking
	if player in _player_event_map:
		var event = _player_event_map[player]
		if event:
			event._active_instances = max(0, event._active_instances - 1)
		_player_event_map.erase(player)

func _on_player_2d_finished(player: AudioStreamPlayer2D) -> void:
	_return_player_to_pool(player)

func _on_player_3d_finished(player: AudioStreamPlayer3D) -> void:
	_return_player_to_pool(player)

## Get pool statistics
func get_pool_stats() -> Dictionary:
	return {
		"pool_2d_available": _pool_2d.size(),
		"pool_3d_available": _pool_3d.size(),
		"active_2d": _active_players_2d.size(),
		"active_3d": _active_players_3d.size(),
		"total_players": _pool_2d.size() + _pool_3d.size() + _active_players_2d.size() + _active_players_3d.size(),
		"layered_events": _active_layered_events.size()
	}
#endregion

#region Music Management (Placeholder for MusicManager)
func _update_music(delta: float) -> void:
	# This will be handled by MusicManager
	pass
#endregion

#region Snapshot Management
## Load and register a snapshot
func register_snapshot(snapshot: AudioSnapshot) -> void:
	if not snapshot or not snapshot.is_valid():
		push_warning("Invalid AudioSnapshot")
		return

	_snapshots[snapshot.snapshot_name] = snapshot
	print("Registered snapshot: %s" % snapshot.snapshot_name)

## Apply a snapshot with transition
func apply_snapshot(snapshot_name: String, transition_time: float = -1.0) -> void:
	if not _snapshots.has(snapshot_name):
		push_warning("Snapshot '%s' not found" % snapshot_name)
		return

	var snapshot: AudioSnapshot = _snapshots[snapshot_name]

	# Use snapshot's default transition time if not specified
	if transition_time < 0.0:
		transition_time = snapshot.transition_time

	_previous_snapshot = _active_snapshot
	_active_snapshot = snapshot
	_snapshot_transition_duration = transition_time
	_snapshot_transition_time = transition_time

	snapshot_changed.emit(snapshot_name)

func _update_snapshot_transition(delta: float) -> void:
	_snapshot_transition_time -= delta

	if _snapshot_transition_time <= 0.0:
		# Transition complete
		if _active_snapshot:
			_active_snapshot.apply_immediate()
		_snapshot_transition_time = 0.0
		return

	# Interpolate between snapshots
	var t = 1.0 - (_snapshot_transition_time / _snapshot_transition_duration)
	t = ease(t, _active_snapshot.transition_curve if _active_snapshot else 0.5)

	# Apply interpolated values
	if _active_snapshot and _previous_snapshot:
		for bus_state in _active_snapshot.bus_states:
			var bus_index = AudioServer.get_bus_index(bus_state.bus_name)
			if bus_index < 0:
				continue

			var prev_state = _previous_snapshot.get_bus_state(bus_state.bus_name)
			if prev_state:
				var volume = lerpf(prev_state.volume_db, bus_state.volume_db, t)
				AudioServer.set_bus_volume_db(bus_index, volume)
			else:
				AudioServer.set_bus_volume_db(bus_index, bus_state.volume_db)
#endregion

#region Debug
func print_stats() -> void:
	print("\n=== AudioController Stats ===")
	var stats = get_pool_stats()
	print("2D Players - Available: %d, Active: %d" % [stats.pool_2d_available, stats.active_2d])
	print("3D Players - Available: %d, Active: %d" % [stats.pool_3d_available, stats.active_3d])
	print("Total Players: %d / %d" % [stats.total_players, max_total_players])
	print("Parameters: %d" % _parameters.size())
	print("Active Layered Events: %d" % stats.layered_events)
	print("BPM: %.1f, Beat: %d, Bar: %d" % [global_bpm, _current_beat % time_signature, _current_bar])
	print("Active Snapshot: %s" % (_active_snapshot.snapshot_name if _active_snapshot else "None"))
	print("=============================\n")
#endregion
