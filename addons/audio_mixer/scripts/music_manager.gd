extends Node

## MusicManager - Handles adaptive music playback with stems and transitions
## Works in conjunction with AudioController

signal music_started(music_name: String)
signal music_stopped(music_name: String)
signal stem_toggled(stem_name: String, enabled: bool)
signal music_transitioned(from_music: String, to_music: String)
signal beat(beat_number: int)
signal bar(bar_number: int)
signal marker_reached(marker_name: String)

#region Current State
var _current_music: MusicEvent = null
var _stem_players: Array = []  # Array of {player: Node, stem: MusicStem, stem_index: int}
var _is_playing: bool = false
var _playback_position: float = 0.0
var _master_player: Node = null  # Reference player for sync
#endregion

#region Transitions
var _is_transitioning: bool = false
var _transition_to: MusicEvent = null
var _transition_time: float = 0.0
var _transition_duration: float = 0.0
var _transition_type: int = 0  # From MusicEvent.MusicTransition
#endregion

#region Configuration
@export_range(0.0, 100.0, 0.1) var stem_fade_time: float = 1.0
@export var sync_to_audio_controller_bpm: bool = true
#endregion

func _ready() -> void:
	# Connect to AudioController BPM signals if syncing
	if sync_to_audio_controller_bpm and has_node("/root/AudioController"):
		var audio_controller = get_node("/root/AudioController")
		if audio_controller.has_signal("beat"):
			audio_controller.beat.connect(_on_audio_controller_beat)
		if audio_controller.has_signal("bar"):
			audio_controller.bar.connect(_on_audio_controller_bar)

func _process(delta: float) -> void:
	if not _is_playing:
		return

	# Update playback position
	if _master_player and _master_player.playing:
		_playback_position = _master_player.get_playback_position()

	# Update music event timing
	if _current_music:
		_current_music.update_position(delta)

		# Forward signals
		if not _current_music.beat.is_connected(_on_music_beat):
			_current_music.beat.connect(_on_music_beat)
		if not _current_music.bar.is_connected(_on_music_bar):
			_current_music.bar.connect(_on_music_bar)
		if not _current_music.marker_reached.is_connected(_on_music_marker):
			_current_music.marker_reached.connect(_on_music_marker)

	# Update stem volumes based on parameters
	_update_stem_volumes(delta)

	# Handle transitions
	if _is_transitioning:
		_update_transition(delta)

func _on_music_beat(beat_num: int) -> void:
	beat.emit(beat_num)

func _on_music_bar(bar_num: int) -> void:
	bar.emit(bar_num)

func _on_music_marker(marker: String) -> void:
	marker_reached.emit(marker)

func _on_audio_controller_beat(beat_num: int) -> void:
	# Sync to AudioController BPM if not using internal timing
	if sync_to_audio_controller_bpm:
		beat.emit(beat_num)

func _on_audio_controller_bar(bar_num: int) -> void:
	if sync_to_audio_controller_bpm:
		bar.emit(bar_num)

#region Playback Control
## Play a music event
func play_music(music: MusicEvent, fade_in_time: float = 0.0) -> bool:
	if not music or not music.is_valid():
		push_warning("Invalid MusicEvent")
		return false

	# Stop current music if playing
	if _is_playing:
		stop_music(fade_in_time)
		await get_tree().create_timer(fade_in_time).timeout

	_current_music = music
	_stem_players.clear()
	_playback_position = 0.0
	_is_playing = true

	# Sync BPM with AudioController if enabled
	if sync_to_audio_controller_bpm and has_node("/root/AudioController"):
		var audio_controller = get_node("/root/AudioController")
		audio_controller.global_bpm = music.bpm
		audio_controller.time_signature = music.beats_per_bar

	# Start music internal timing
	music._is_playing = true
	music._playback_position = 0.0

	# Create players for each stem
	var audio_controller = get_node("/root/AudioController")

	for i in range(music.stems.size()):
		var stem: MusicEvent.MusicStem = music.stems[i]

		if not stem.stream:
			continue

		# Get player from pool
		var player = audio_controller._get_player_from_pool(false)  # Use 2D for music
		if not player:
			push_warning("Failed to get player for stem: %s" % stem.stem_name)
			continue

		# Setup player
		player.stream = stem.stream
		player.volume_db = -80.0 if not stem.default_enabled else stem.volume_offset + music.master_volume
		player.pitch_scale = 1.0
		player.bus = music.bus_name

		# Enable looping if music loops
		if music.loop and stem.stream is AudioStreamWAV:
			stem.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

		# Start playback
		player.play()

		# Store stem data
		var stem_data = {
			"player": player,
			"stem": stem,
			"stem_index": i,
			"current_volume": player.volume_db,
			"target_volume": player.volume_db
		}

		_stem_players.append(stem_data)

		# Set first player as master for sync
		if _master_player == null:
			_master_player = player

	# Sync all stems to master
	if music.sync_stems:
		_sync_all_stems()

	# Fade in if requested
	if fade_in_time > 0.0:
		for stem_data in _stem_players:
			var stem: MusicEvent.MusicStem = stem_data.stem
			if stem.default_enabled:
				_fade_stem(stem_data, stem.volume_offset + music.master_volume, fade_in_time)

	music_started.emit(music.music_name)
	print("Music started: %s (%.1f BPM, %d stems)" % [music.music_name, music.bpm, _stem_players.size()])
	return true

## Stop current music
func stop_music(fade_out_time: float = 1.0) -> void:
	if not _is_playing:
		return

	var music_name = _current_music.music_name if _current_music else "Unknown"

	# Fade out all stems
	for stem_data in _stem_players:
		_fade_stem(stem_data, -80.0, fade_out_time)

	# Wait for fade, then stop
	if fade_out_time > 0.0:
		await get_tree().create_timer(fade_out_time).timeout

	# Stop and return players to pool
	var audio_controller = get_node("/root/AudioController")
	for stem_data in _stem_players:
		var player = stem_data.player
		player.stop()
		audio_controller._return_player_to_pool(player)

	_stem_players.clear()
	_master_player = null
	_is_playing = false

	if _current_music:
		_current_music._is_playing = false

	music_stopped.emit(music_name)
	print("Music stopped: %s" % music_name)

## Pause music
func pause_music() -> void:
	if not _is_playing:
		return

	for stem_data in _stem_players:
		stem_data.player.stream_paused = true

	if _current_music:
		_current_music._is_playing = false

## Resume music
func resume_music() -> void:
	if not _is_playing:
		return

	for stem_data in _stem_players:
		stem_data.player.stream_paused = false

	if _current_music:
		_current_music._is_playing = true

## Check if music is playing
func is_playing() -> bool:
	return _is_playing

## Get current music event
func get_current_music() -> MusicEvent:
	return _current_music
#endregion

#region Stem Control
## Enable or disable a stem by name or index
func set_stem_enabled(stem_identifier: Variant, enabled: bool, fade_time: float = -1.0) -> void:
	if not _current_music:
		return

	if fade_time < 0.0:
		fade_time = stem_fade_time

	var target_stem_data = null

	# Find stem
	if stem_identifier is int:
		if stem_identifier >= 0 and stem_identifier < _stem_players.size():
			target_stem_data = _stem_players[stem_identifier]
	elif stem_identifier is String:
		for stem_data in _stem_players:
			if stem_data.stem.stem_name == stem_identifier:
				target_stem_data = stem_data
				break

	if not target_stem_data:
		push_warning("Stem not found: %s" % str(stem_identifier))
		return

	# Update stem state
	target_stem_data.stem.enabled = enabled

	# Calculate target volume
	var target_volume = -80.0
	if enabled:
		target_volume = target_stem_data.stem.volume_offset + _current_music.master_volume

	# Fade to target
	_fade_stem(target_stem_data, target_volume, fade_time)

	stem_toggled.emit(target_stem_data.stem.stem_name, enabled)

## Solo a stem (mute all others)
func solo_stem(stem_identifier: Variant, fade_time: float = -1.0) -> void:
	if not _current_music:
		return

	if fade_time < 0.0:
		fade_time = stem_fade_time

	# Find target stem
	var target_index = -1
	if stem_identifier is int:
		target_index = stem_identifier
	elif stem_identifier is String:
		for i in range(_stem_players.size()):
			if _stem_players[i].stem.stem_name == stem_identifier:
				target_index = i
				break

	if target_index < 0:
		return

	# Mute all except target
	for i in range(_stem_players.size()):
		set_stem_enabled(i, i == target_index, fade_time)

## Unsolo all stems (enable all default stems)
func unsolo_all(fade_time: float = -1.0) -> void:
	if not _current_music:
		return

	if fade_time < 0.0:
		fade_time = stem_fade_time

	for stem_data in _stem_players:
		set_stem_enabled(stem_data.stem_index, stem_data.stem.default_enabled, fade_time)

## Get stem by name
func get_stem_player(stem_name: String) -> Node:
	for stem_data in _stem_players:
		if stem_data.stem.stem_name == stem_name:
			return stem_data.player
	return null
#endregion

#region Stem Volume Updates
func _update_stem_volumes(delta: float) -> void:
	if not _current_music:
		return

	var audio_controller = get_node_or_null("/root/AudioController")

	for stem_data in _stem_players:
		var stem: MusicEvent.MusicStem = stem_data.stem
		var player: Node = stem_data.player

		# Check if stem is controlled by a parameter
		if not stem.control_parameter.is_empty() and audio_controller:
			var param = audio_controller.get_parameter(stem.control_parameter)
			if param:
				var param_value = param.current_value
				var calculated_volume = stem.calculate_volume(param_value)

				if calculated_volume > -80.0:
					calculated_volume += _current_music.master_volume

				stem_data.target_volume = calculated_volume

		# Smooth interpolation to target volume
		var fade_speed = delta / stem.fade_time if stem.fade_time > 0.0 else 1.0
		stem_data.current_volume = lerpf(stem_data.current_volume, stem_data.target_volume, fade_speed)
		player.volume_db = stem_data.current_volume
#endregion

#region Synchronization
func _sync_all_stems() -> void:
	if not _master_player or not _current_music or not _current_music.sync_stems:
		return

	var master_pos = _master_player.get_playback_position()

	for stem_data in _stem_players:
		var player = stem_data.player
		if player != _master_player and player.playing:
			var current_pos = player.get_playback_position()
			if abs(current_pos - master_pos) > 0.05:  # 50ms tolerance
				player.seek(master_pos)
#endregion

#region Transitions
## Transition to new music
func transition_to(new_music: MusicEvent, transition_type: int = 1, transition_time: float = 2.0) -> void:
	if not new_music or not new_music.is_valid():
		push_warning("Invalid transition target")
		return

	_is_transitioning = true
	_transition_to = new_music
	_transition_type = transition_type
	_transition_duration = transition_time
	_transition_time = transition_time

	var old_music_name = _current_music.music_name if _current_music else "None"

	match transition_type:
		0:  # Immediate
			stop_music(0.0)
			play_music(new_music, 0.0)
			_is_transitioning = false

		1:  # End of Bar - wait for next bar boundary
			if has_node("/root/AudioController"):
				var audio_controller = get_node("/root/AudioController")
				var wait_time = audio_controller.get_time_to_next_bar()
				await get_tree().create_timer(wait_time).timeout
			stop_music(0.5)
			play_music(new_music, 0.5)
			_is_transitioning = false

		2:  # End of Section (placeholder - would need section markers)
			stop_music(1.0)
			play_music(new_music, 1.0)
			_is_transitioning = false

		3:  # Crossfade
			play_music(new_music, transition_time)
			# Old music will fade out automatically in play_music

	music_transitioned.emit(old_music_name, new_music.music_name)

func _update_transition(delta: float) -> void:
	_transition_time -= delta
	if _transition_time <= 0.0:
		_is_transitioning = false
#endregion

#region Helpers
func _fade_stem(stem_data: Dictionary, target_volume: float, duration: float) -> void:
	stem_data.target_volume = target_volume

	if duration <= 0.0:
		stem_data.current_volume = target_volume
		stem_data.player.volume_db = target_volume
	else:
		# Smooth fade handled in _update_stem_volumes
		pass
#endregion

#region Debug
func print_status() -> void:
	print("\n=== MusicManager Status ===")
	if _current_music:
		print("Current Music: %s" % _current_music.music_name)
		print("BPM: %.1f" % _current_music.bpm)
		print("Position: %.2fs" % _playback_position)
		print("Playing: %s" % str(_is_playing))
		print("\nStems:")
		for stem_data in _stem_players:
			var stem: MusicEvent.MusicStem = stem_data.stem
			print("  [%s] %s: %.1f dB (Target: %.1f dB) %s" % [
				"ON" if stem.enabled else "OFF",
				stem.stem_name,
				stem_data.current_volume,
				stem_data.target_volume,
				"[SOLO]" if stem.solo else ""
			])
	else:
		print("No music playing")
	print("===========================\n")
#endregion
