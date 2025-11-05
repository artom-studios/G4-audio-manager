## MusicEvent - Adaptive music with multiple synchronized stems
@tool
class_name MusicEvent
extends Resource

enum TransitionType {
	IMMEDIATE,      ## Switch instantly
	BEAT_SYNC,      ## Sync to next beat
	BAR_SYNC,       ## Sync to next bar
	CROSSFADE       ## Smooth crossfade
}

@export var music_name: String = "New Music"
@export_multiline var description: String = ""

## Tempo and timing
@export_range(30.0, 300.0) var bpm: float = 120.0
@export_range(1, 16) var beats_per_bar: int = 4
@export_range(1, 16) var beat_division: int = 4  ## Note value (4 = quarter note)

## Stems
@export var stems: Array[MusicStem] = []

## Transition settings
@export var default_transition: TransitionType = TransitionType.BAR_SYNC
@export var crossfade_duration: float = 4.0  ## In beats

## Loop points (in beats)
@export var loop_enabled: bool = true
@export var loop_start_beat: int = 0
@export var loop_end_beat: int = 0  ## 0 = end of track

## Get beat duration in seconds
func get_beat_duration() -> float:
	return 60.0 / bpm

## Get bar duration in seconds
func get_bar_duration() -> float:
	return get_beat_duration() * beats_per_bar

## Check if music is valid
func is_valid() -> bool:
	if music_name == "" or bpm <= 0:
		return false

	for stem in stems:
		if not stem.is_valid():
			return false

	return stems.size() > 0

## Get display name for editor
func get_display_name() -> String:
	return music_name if music_name != "" else resource_path.get_file().get_basename()
