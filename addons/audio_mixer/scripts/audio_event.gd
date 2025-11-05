@tool
extends Resource
class_name AudioEvent

## FMOD-like Audio Event Resource for Godot 4
## Defines a reusable, configurable audio event with randomization and pooling support

#region Enums
enum PlaybackMode {
	ONE_SHOT,      ## Play once and stop
	LOOPING,       ## Loop indefinitely
	RANDOM_ONE,    ## Pick one random variation and play once
	SEQUENTIAL     ## Play variations in sequence
}

enum SpatialMode {
	MODE_2D,       ## 2D audio (no attenuation)
	MODE_3D        ## 3D spatial audio with attenuation
}

enum Priority {
	LOWEST = 0,
	LOW = 1,
	NORMAL = 2,
	HIGH = 3,
	CRITICAL = 4
}
#endregion

#region Core Properties
@export_group("Event Identity")
## Unique identifier for this audio event
@export var event_name: String = "NewAudioEvent":
	set(value):
		event_name = value.strip_edges()
		emit_changed()

## Category/folder for organization (e.g., "SFX/Weapons", "Music/Combat")
@export var category: String = "Uncategorized":
	set(value):
		category = value.strip_edges()
		emit_changed()

## Optional description/notes for sound designers
@export_multiline var description: String = "":
	set(value):
		description = value
		emit_changed()
#endregion

#region Audio Streams
@export_group("Audio Sources")
## Array of audio stream variations (randomly selected during playback)
@export var streams: Array[AudioStream] = []:
	set(value):
		streams = value
		emit_changed()

## Mode for selecting which stream to play
@export var playback_mode: PlaybackMode = PlaybackMode.RANDOM_ONE:
	set(value):
		playback_mode = value
		emit_changed()
#endregion

#region Randomization
@export_group("Randomization")
## Volume variation range in dB (min, max)
@export var volume_range: Vector2 = Vector2(-3.0, 0.0):
	set(value):
		# Ensure min <= max
		if value.x > value.y:
			value = Vector2(value.y, value.x)
		volume_range = value
		emit_changed()

## Pitch variation range (min, max scale)
@export var pitch_range: Vector2 = Vector2(0.95, 1.05):
	set(value):
		# Ensure min <= max and positive values
		if value.x > value.y:
			value = Vector2(value.y, value.x)
		pitch_range = Vector2(max(0.01, value.x), max(0.01, value.y))
		emit_changed()

## Enable random start position (useful for ambient loops)
@export var random_start_position: bool = false:
	set(value):
		random_start_position = value
		emit_changed()
#endregion

#region Playback Control
@export_group("Playback Control")
## Maximum number of concurrent instances of this event
@export_range(1, 100, 1) var max_concurrent_instances: int = 5:
	set(value):
		max_concurrent_instances = max(1, value)
		emit_changed()

## Priority level for voice stealing (higher priority events can interrupt lower ones)
@export var priority: Priority = Priority.NORMAL:
	set(value):
		priority = value
		emit_changed()

## Cooldown time in seconds before this event can be triggered again
@export_range(0.0, 10.0, 0.01) var cooldown_time: float = 0.0:
	set(value):
		cooldown_time = max(0.0, value)
		emit_changed()

## Fade in duration in seconds
@export_range(0.0, 5.0, 0.01) var fade_in_duration: float = 0.0:
	set(value):
		fade_in_duration = max(0.0, value)
		emit_changed()

## Fade out duration in seconds
@export_range(0.0, 5.0, 0.01) var fade_out_duration: float = 0.0:
	set(value):
		fade_out_duration = max(0.0, value)
		emit_changed()
#endregion

#region Spatial Audio
@export_group("Spatial Audio")
## 2D or 3D audio mode
@export var spatial_mode: SpatialMode = SpatialMode.MODE_2D:
	set(value):
		spatial_mode = value
		emit_changed()

## 3D attenuation model (only for 3D mode)
@export_enum("Inverse:0", "Inverse Square:1", "Logarithmic:2", "Disabled:3") var attenuation_model: int = 0:
	set(value):
		attenuation_model = value
		emit_changed()

## Maximum audible distance (only for 3D mode)
@export_range(1.0, 4096.0, 0.1) var max_distance: float = 100.0:
	set(value):
		max_distance = max(1.0, value)
		emit_changed()

## Unit size for distance attenuation (only for 3D mode)
@export_range(0.1, 100.0, 0.1) var unit_size: float = 10.0:
	set(value):
		unit_size = max(0.1, value)
		emit_changed()

## Doppler tracking (only for 3D mode)
@export_enum("Disabled:0", "Idle:1", "Physics:2") var doppler_tracking: int = 0:
	set(value):
		doppler_tracking = value
		emit_changed()
#endregion

#region Audio Bus
@export_group("Audio Routing")
## The audio bus to route this event through
@export var bus_name: String = "Master":
	set(value):
		# Validate bus exists
		if _is_valid_bus(value):
			bus_name = value
		else:
			bus_name = "Master"
			push_warning("Invalid bus name '%s', defaulting to 'Master'" % value)
		emit_changed()
#endregion

#region Advanced Features
@export_group("Advanced")
## Enable voice stealing (replace lower priority sounds when pool is exhausted)
@export var enable_voice_stealing: bool = false:
	set(value):
		enable_voice_stealing = value
		emit_changed()

## Delay before playback starts (in seconds)
@export_range(0.0, 10.0, 0.01) var delay: float = 0.0:
	set(value):
		delay = max(0.0, value)
		emit_changed()

## Custom user data (can store game-specific metadata)
@export var metadata: Dictionary = {}:
	set(value):
		metadata = value
		emit_changed()
#endregion

#region Runtime State (not exported)
var _last_play_time: float = 0.0
var _current_stream_index: int = 0
var _active_instances: int = 0
#endregion

#region Helper Functions

## Get available bus names from AudioServer
func _get_bus_enum() -> PackedStringArray:
	var buses := PackedStringArray()
	for i in range(AudioServer.bus_count):
		buses.append(AudioServer.get_bus_name(i))
	return buses

## Validate if a bus name exists
func _is_valid_bus(bus: String) -> bool:
	if bus.is_empty():
		return false
	for i in range(AudioServer.bus_count):
		if AudioServer.get_bus_name(i) == bus:
			return true
	return false

## Get a random stream from the array
func get_random_stream() -> AudioStream:
	if streams.is_empty():
		push_error("AudioEvent '%s' has no streams assigned!" % event_name)
		return null

	match playback_mode:
		PlaybackMode.RANDOM_ONE:
			return streams[randi() % streams.size()]
		PlaybackMode.SEQUENTIAL:
			var stream = streams[_current_stream_index]
			_current_stream_index = (_current_stream_index + 1) % streams.size()
			return stream
		_:
			return streams[randi() % streams.size()]

## Get a random volume within the range
func get_random_volume_db() -> float:
	return randf_range(volume_range.x, volume_range.y)

## Get a random pitch within the range
func get_random_pitch() -> float:
	return randf_range(pitch_range.x, pitch_range.y)

## Check if this event can be played (cooldown check)
func can_play() -> bool:
	if cooldown_time <= 0.0:
		return true
	var current_time = Time.get_ticks_msec() / 1000.0
	return (current_time - _last_play_time) >= cooldown_time

## Update last play time (called by AudioController)
func mark_played() -> void:
	_last_play_time = Time.get_ticks_msec() / 1000.0

## Check if max instances reached
func is_at_max_instances() -> bool:
	return _active_instances >= max_concurrent_instances

## Validate this event has all required data
func is_valid() -> bool:
	if streams.is_empty():
		push_warning("AudioEvent '%s' has no audio streams" % event_name)
		return false
	if event_name.is_empty():
		push_warning("AudioEvent has no name")
		return false
	return true

## Get a summary of this event for debugging
func get_debug_info() -> String:
	return """
	AudioEvent: %s
	Category: %s
	Streams: %d
	Mode: %s
	Volume: %.1f to %.1f dB
	Pitch: %.2f to %.2f
	Bus: %s
	Max Instances: %d
	Active Instances: %d
	Priority: %s
	""" % [
		event_name,
		category,
		streams.size(),
		PlaybackMode.keys()[playback_mode],
		volume_range.x, volume_range.y,
		pitch_range.x, pitch_range.y,
		bus_name,
		max_concurrent_instances,
		_active_instances,
		Priority.keys()[priority]
	]
#endregion

#region Editor Helpers (only works in @tool mode)
func _get_property_list() -> Array:
	var properties := []

	# Dynamic bus name enum
	properties.append({
		"name": "bus_name",
		"type": TYPE_STRING,
		"usage": PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(_get_bus_enum())
	})

	return properties

func _property_can_revert(property: StringName) -> bool:
	match property:
		"event_name": return event_name != "NewAudioEvent"
		"category": return category != "Uncategorized"
		"volume_range": return volume_range != Vector2(-3.0, 0.0)
		"pitch_range": return pitch_range != Vector2(0.95, 1.05)
		"bus_name": return bus_name != "Master"
		"max_concurrent_instances": return max_concurrent_instances != 5
		_: return false

func _property_get_revert(property: StringName):
	match property:
		"event_name": return "NewAudioEvent"
		"category": return "Uncategorized"
		"volume_range": return Vector2(-3.0, 0.0)
		"pitch_range": return Vector2(0.95, 1.05)
		"bus_name": return "Master"
		"max_concurrent_instances": return 5
		_: return null
#endregion
