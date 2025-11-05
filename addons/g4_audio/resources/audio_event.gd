## AudioEvent - Simple sound effect definition
## Supports multiple variations, randomization, and spatial audio
@tool
class_name AudioEvent
extends Resource

enum PlaybackMode {
	ONE_SHOT,     ## Play once and stop
	LOOPING,      ## Loop continuously
	RANDOM,       ## Pick random variation each time
	SEQUENTIAL    ## Play variations in sequence
}

enum SpatialMode {
	MODE_2D,  ## 2D positional audio
	MODE_3D,  ## 3D spatial audio
	GLOBAL    ## Non-positional (UI sounds, music)
}

## Event identification
@export var event_name: String = "New Audio Event"
@export var category: String = "Uncategorized"
@export_multiline var description: String = ""

## Audio streams (variations)
@export var streams: Array[AudioStream] = []

## Volume settings
@export_range(-80.0, 24.0, 0.1) var volume_min: float = -3.0
@export_range(-80.0, 24.0, 0.1) var volume_max: float = 0.0

## Pitch settings
@export_range(0.01, 4.0, 0.01) var pitch_min: float = 0.95
@export_range(0.01, 4.0, 0.01) var pitch_max: float = 1.05

## Playback settings
@export var playback_mode: PlaybackMode = PlaybackMode.RANDOM
@export var max_instances: int = 5
@export var priority: int = 128  ## 0 = lowest, 255 = highest

## Spatial audio
@export var spatial_mode: SpatialMode = SpatialMode.MODE_3D
@export_range(0.0, 4096.0) var max_distance: float = 100.0
@export_range(0.0, 10.0) var attenuation: float = 1.0

## Bus routing
@export var bus_name: String = "Master"

## Fade settings
@export var fade_in_duration: float = 0.0
@export var fade_out_duration: float = 0.0

## Cooldown (prevent spam)
@export var cooldown_time: float = 0.0

# Internal state
var _last_play_time: float = 0.0
var _current_variation_index: int = 0

## Check if this event can be played (cooldown check)
func can_play() -> bool:
	if cooldown_time <= 0.0:
		return true

	var current_time = Time.get_ticks_msec() / 1000.0
	return (current_time - _last_play_time) >= cooldown_time

## Mark event as played (for cooldown tracking)
func mark_played() -> void:
	_last_play_time = Time.get_ticks_msec() / 1000.0

## Get a random stream from the variations
func get_random_stream() -> AudioStream:
	if streams.is_empty():
		return null

	match playback_mode:
		PlaybackMode.RANDOM:
			return streams[randi() % streams.size()]
		PlaybackMode.SEQUENTIAL:
			var stream = streams[_current_variation_index]
			_current_variation_index = (_current_variation_index + 1) % streams.size()
			return stream
		_:
			return streams[0] if not streams.is_empty() else null

## Get randomized volume in dB
func get_random_volume_db() -> float:
	return randf_range(volume_min, volume_max)

## Get randomized pitch scale
func get_random_pitch() -> float:
	return randf_range(pitch_min, pitch_max)

## Check if event is valid and ready to play
func is_valid() -> bool:
	return not streams.is_empty() and event_name != ""

## Get display name for editor
func get_display_name() -> String:
	return event_name if event_name != "" else resource_path.get_file().get_basename()
