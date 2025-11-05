## MusicManager - Global music system
## Access via: MusicManager.play_music(music_event)
extends Node

## Emitted when music starts playing
signal music_started(music_name: String)

## Emitted when music stops
signal music_stopped(music_name: String)

## Emitted when a stem is toggled
signal stem_toggled(stem_name: String, enabled: bool)

## Emitted on each beat
signal beat(beat_number: int)

## Emitted on each bar
signal bar(bar_number: int)

## Current music state
var current_music: MusicEvent = null
var _stem_players: Array[AudioStreamPlayer] = []
var _stem_enabled_states: Array[bool] = []

## Beat tracking
var _beat_timer: float = 0.0
var _current_beat: int = 0
var _current_bar: int = 0
var _is_playing: bool = false

func _process(delta):
	if not _is_playing or not current_music:
		return

	# Update beat timer
	var beat_duration = current_music.get_beat_duration()
	_beat_timer += delta

	if _beat_timer >= beat_duration:
		_beat_timer -= beat_duration
		_current_beat += 1
		beat.emit(_current_beat)

		if _current_beat % current_music.beats_per_bar == 0:
			_current_bar += 1
			bar.emit(_current_bar)

	# Update stems based on parameters
	_update_stem_parameters()

## Play a music event
func play_music(music: MusicEvent, fade_in: float = 0.0) -> bool:
	if not music or not music.is_valid():
		push_warning("Invalid music event")
		return false

	# Stop current music
	if current_music:
		stop_music()

	# Create players for each stem
	_stem_players.clear()
	_stem_enabled_states.clear()

	for stem in music.stems:
		var player = AudioStreamPlayer.new()
		player.stream = stem.stream
		player.volume_db = stem.volume_offset if stem.default_enabled else -80.0
		player.bus = "Music"
		add_child(player)

		# Sync playback
		player.play()

		_stem_players.append(player)
		_stem_enabled_states.append(stem.default_enabled)

	current_music = music
	_is_playing = true
	_beat_timer = 0.0
	_current_beat = 0
	_current_bar = 0

	# Apply fade in
	if fade_in > 0.0:
		for i in range(_stem_players.size()):
			if _stem_enabled_states[i]:
				var player = _stem_players[i]
				var target_volume = music.stems[i].volume_offset
				player.volume_db = -80.0
				var tween = create_tween()
				tween.tween_property(player, "volume_db", target_volume, fade_in)

	music_started.emit(music.music_name)
	return true

## Stop the current music
func stop_music(fade_out: float = 0.0):
	if not current_music:
		return

	var music_name = current_music.music_name

	if fade_out > 0.0:
		for player in _stem_players:
			var tween = create_tween()
			tween.tween_property(player, "volume_db", -80.0, fade_out)
			tween.tween_callback(player.queue_free)
	else:
		for player in _stem_players:
			player.stop()
			player.queue_free()

	_stem_players.clear()
	_stem_enabled_states.clear()
	current_music = null
	_is_playing = false

	music_stopped.emit(music_name)

## Enable or disable a stem
func set_stem_enabled(stem_name: String, enabled: bool, fade_time: float = 1.0):
	if not current_music:
		return

	# Find stem index
	var stem_idx = -1
	for i in range(current_music.stems.size()):
		if current_music.stems[i].stem_name == stem_name:
			stem_idx = i
			break

	if stem_idx == -1:
		push_warning("Stem '%s' not found" % stem_name)
		return

	# Update state
	_stem_enabled_states[stem_idx] = enabled

	# Fade player volume
	var player = _stem_players[stem_idx]
	var target_volume = current_music.stems[stem_idx].volume_offset if enabled else -80.0

	if fade_time > 0.0:
		var tween = create_tween()
		tween.tween_property(player, "volume_db", target_volume, fade_time)
	else:
		player.volume_db = target_volume

	stem_toggled.emit(stem_name, enabled)

## Update stems based on parameter values
func _update_stem_parameters():
	if not current_music:
		return

	for i in range(current_music.stems.size()):
		var stem = current_music.stems[i]
		if stem.controlled_by_parameter:
			var param_value = AudioManager.get_parameter(stem.control_parameter)
			var should_enable = stem.should_be_enabled(param_value)

			if should_enable != _stem_enabled_states[i]:
				set_stem_enabled(stem.stem_name, should_enable, 1.0)

## Get current playback position in beats
func get_current_beat() -> int:
	return _current_beat

## Get current bar
func get_current_bar() -> int:
	return _current_bar

## Check if music is playing
func is_playing() -> bool:
	return _is_playing

## Get current music name
func get_current_music_name() -> String:
	return current_music.music_name if current_music else ""
