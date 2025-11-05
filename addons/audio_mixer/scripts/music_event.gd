@tool
extends Resource
class_name MusicEvent

## Adaptive Music Event with synchronized stems
## Supports layered music stems, transitions, and beat-quantized changes

signal beat(beat_number: int)
signal bar(bar_number: int)
signal marker_reached(marker_name: String)
signal stem_changed(stem_index: int, enabled: bool)

#region Sub-Resources
## Individual music stem (layer) with volume automation
class MusicStem extends Resource:
	## Stem name (e.g., "Drums", "Bass", "Melody", "Intensity Layer")
	@export var stem_name: String = "Stem"

	## Audio stream for this stem
	@export var stream: AudioStream = null

	## Default enabled state
	@export var default_enabled: bool = true

	## Volume offset in dB
	@export_range(-80.0, 6.0, 0.1) var volume_offset: float = 0.0

	## Parameter that controls this stem's volume (empty = always on)
	@export var control_parameter: String = ""

	## Parameter range for this stem (min, max)
	@export var parameter_range: Vector2 = Vector2(0.0, 1.0)

	## Fade in/out time when enabling/disabling this stem
	@export_range(0.0, 10.0, 0.1) var fade_time: float = 1.0

	## Solo this stem (mute all others)
	@export var solo: bool = false

	## Mute this stem
	@export var mute: bool = false

	## Runtime state
	var enabled: bool = false
	var current_volume_db: float = -80.0
	var target_volume_db: float = -80.0

	func _init() -> void:
		enabled = default_enabled

	func calculate_volume(param_value: float) -> float:
		if mute or stream == null:
			return -80.0

		# If no parameter control, return volume offset
		if control_parameter.is_empty():
			return volume_offset if enabled else -80.0

		# Check if parameter is in range
		if param_value < parameter_range.x or param_value > parameter_range.y:
			return -80.0

		# Calculate normalized position in range
		var range_size = parameter_range.y - parameter_range.x
		if range_size < 0.001:
			return volume_offset

		var normalized = (param_value - parameter_range.x) / range_size

		# Smooth fade at edges
		if normalized < 0.1:
			normalized = normalized / 0.1
		elif normalized > 0.9:
			normalized = 1.0 - ((normalized - 0.9) / 0.1)

		# Convert to dB
		var fade_db = linear_to_db(normalized) if normalized > 0.0 else -80.0
		return fade_db + volume_offset

## Music transition definition
class MusicTransition extends Resource:
	## Target music event to transition to
	@export var target_event: MusicEvent = null

	## Transition type
	@export_enum("Immediate", "End of Bar", "End of Section", "Crossfade") var transition_type: int = 1

	## Crossfade duration in seconds (for Crossfade type)
	@export_range(0.0, 10.0, 0.1) var crossfade_duration: float = 2.0

	## Exit fade out time (for non-crossfade transitions)
	@export_range(0.0, 10.0, 0.1) var exit_fade_time: float = 1.0

	## Entry fade in time
	@export_range(0.0, 10.0, 0.1) var entry_fade_time: float = 1.0

	## Condition parameter (empty = no condition)
	@export var condition_parameter: String = ""

	## Condition value range
	@export var condition_range: Vector2 = Vector2(0.0, 1.0)

	func check_condition(param_value: float) -> bool:
		if condition_parameter.is_empty():
			return true
		return param_value >= condition_range.x and param_value <= condition_range.y

## Musical marker/cue point
class MusicMarker extends Resource:
	## Marker name
	@export var marker_name: String = "Marker"

	## Time position in seconds
	@export var time_position: float = 0.0

	## Beat position (alternative to time)
	@export var beat_position: int = 0

	## Callback method name to invoke on game logic
	@export var callback_method: String = ""
#endregion

#region Core Properties
@export_group("Music Identity")
@export var music_name: String = "NewMusic":
	set(value):
		music_name = value.strip_edges()
		emit_changed()

@export var category: String = "Music":
	set(value):
		category = value.strip_edges()
		emit_changed()

@export_multiline var description: String = "":
	set(value):
		description = value
		emit_changed()
#endregion

#region Timing
@export_group("Musical Timing")
## Beats per minute
@export_range(30.0, 300.0, 0.1) var bpm: float = 120.0:
	set(value):
		bpm = clampf(value, 30.0, 300.0)
		_update_timing()
		emit_changed()

## Time signature - beats per bar
@export_range(1, 16, 1) var beats_per_bar: int = 4:
	set(value):
		beats_per_bar = clampi(value, 1, 16)
		emit_changed()

## Beat subdivision (for quantization)
@export_enum("Quarter Note", "Eighth Note", "Sixteenth Note", "Bar") var quantization: int = 0:
	set(value):
		quantization = value
		emit_changed()
#endregion

#region Stems
@export_group("Music Stems")
## Array of music stems/layers
@export var stems: Array[MusicStem] = []:
	set(value):
		stems = value
		emit_changed()

## Sync all stems to same playback position
@export var sync_stems: bool = true:
	set(value):
		sync_stems = value
		emit_changed()
#endregion

#region Transitions
@export_group("Transitions")
## Available transitions to other music events
@export var transitions: Array[MusicTransition] = []:
	set(value):
		transitions = value
		emit_changed()

## Loop this music indefinitely
@export var loop: bool = true:
	set(value):
		loop = value
		emit_changed()

## Jump to this position when looping (in beats, -1 = start)
@export var loop_start_beat: int = -1:
	set(value):
		loop_start_beat = value
		emit_changed()
#endregion

#region Markers
@export_group("Markers & Cues")
## Musical markers/cue points
@export var markers: Array[MusicMarker] = []:
	set(value):
		markers = value
		emit_changed()
#endregion

#region Playback Settings
@export_group("Playback")
## Audio bus
@export var bus_name: String = "Music":
	set(value):
		bus_name = value
		emit_changed()

## Master volume offset in dB
@export_range(-80.0, 6.0, 0.1) var master_volume: float = 0.0:
	set(value):
		master_volume = value
		emit_changed()

## Allow multiple instances (usually false for music)
@export var allow_multiple_instances: bool = false:
	set(value):
		allow_multiple_instances = value
		emit_changed()
#endregion

#region Runtime State
var _beat_duration: float = 0.5  # Seconds per beat
var _bar_duration: float = 2.0   # Seconds per bar
var _current_beat: int = 0
var _current_bar: int = 0
var _playback_position: float = 0.0
var _is_playing: bool = false
#endregion

#region Methods
func _init() -> void:
	_update_timing()

func _update_timing() -> void:
	_beat_duration = 60.0 / bpm
	_bar_duration = _beat_duration * beats_per_bar

## Get duration of one beat in seconds
func get_beat_duration() -> float:
	return _beat_duration

## Get duration of one bar in seconds
func get_bar_duration() -> float:
	return _bar_duration

## Get quantization duration in seconds
func get_quantization_duration() -> float:
	match quantization:
		0: return _beat_duration  # Quarter note
		1: return _beat_duration / 2.0  # Eighth note
		2: return _beat_duration / 4.0  # Sixteenth note
		3: return _bar_duration  # Bar
		_: return _beat_duration

## Update playback position and emit beat/bar signals
func update_position(delta: float) -> void:
	if not _is_playing:
		return

	var old_beat = _current_beat
	var old_bar = _current_bar

	_playback_position += delta

	# Calculate current beat and bar
	_current_beat = int(_playback_position / _beat_duration)
	_current_bar = int(_playback_position / _bar_duration)

	# Emit signals for new beats/bars
	if _current_beat != old_beat:
		beat.emit(_current_beat % beats_per_bar)

	if _current_bar != old_bar:
		bar.emit(_current_bar)

	# Check markers
	_check_markers()

## Check if any markers have been reached
func _check_markers() -> void:
	for marker in markers:
		var marker_time = marker.time_position if marker.time_position > 0.0 else marker.beat_position * _beat_duration
		# Check if marker was just passed (simple check without delta)
		if _playback_position >= marker_time and _playback_position < marker_time + 0.1:
			marker_reached.emit(marker.marker_name)

## Get next quantization boundary time
func get_next_quantization_time() -> float:
	var quant_duration = get_quantization_duration()
	var current_quant = int(_playback_position / quant_duration)
	return (current_quant + 1) * quant_duration

## Calculate time until next quantization boundary
func get_time_to_next_quantization() -> float:
	return get_next_quantization_time() - _playback_position

## Enable/disable a stem by name
func set_stem_enabled(stem_name_or_index: Variant, enabled: bool) -> void:
	var index = -1

	if stem_name_or_index is int:
		index = stem_name_or_index
	elif stem_name_or_index is String:
		for i in stems.size():
			if stems[i].stem_name == stem_name_or_index:
				index = i
				break

	if index >= 0 and index < stems.size():
		stems[index].enabled = enabled
		stem_changed.emit(index, enabled)

## Get stem by name
func get_stem(stem_name: String) -> MusicStem:
	for stem in stems:
		if stem.stem_name == stem_name:
			return stem
	return null

## Validate event
func is_valid() -> bool:
	if music_name.is_empty():
		push_warning("MusicEvent has no name")
		return false

	if stems.is_empty():
		push_warning("MusicEvent '%s' has no stems" % music_name)
		return false

	var has_valid_stems = false
	for stem in stems:
		if stem.stream != null:
			has_valid_stems = true
			break

	if not has_valid_stems:
		push_warning("MusicEvent '%s' has no valid stems" % music_name)
		return false

	return true

## Get debug info
func get_debug_info() -> String:
	return """
	MusicEvent: %s
	Category: %s
	BPM: %.1f
	Time Signature: %d/4
	Stems: %d
	Bus: %s
	Loop: %s
	Playing: %s
	Position: %.2fs (Beat %d, Bar %d)
	""" % [
		music_name,
		category,
		bpm,
		beats_per_bar,
		stems.size(),
		bus_name,
		"Yes" if loop else "No",
		"Yes" if _is_playing else "No",
		_playback_position,
		_current_beat % beats_per_bar,
		_current_bar
	]
#endregion

#region Editor Helpers
func _get_property_list() -> Array:
	var properties := []

	# Dynamic bus name enum
	var buses := PackedStringArray()
	for i in range(AudioServer.bus_count):
		buses.append(AudioServer.get_bus_name(i))

	properties.append({
		"name": "bus_name",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(buses)
	})

	return properties
#endregion
