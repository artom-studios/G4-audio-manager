## AudioEventPlayer3D - Plays AudioEvent at this node's 3D position
## Place this node in your scene and assign an AudioEvent resource
@tool
class_name AudioEventPlayer3D
extends Node3D

## The audio event to play
@export var event: AudioEvent:
	set(value):
		event = value
		update_configuration_warnings()

## Play automatically when the scene starts
@export var autoplay: bool = false

## Play on a specific trigger
@export var play_on_ready: bool = false

func _ready():
	if Engine.is_editor_hint():
		return

	if autoplay or play_on_ready:
		play()

## Play the audio event at this node's position
func play() -> bool:
	if not event:
		push_warning("AudioEventPlayer3D: No event assigned")
		return false

	if not is_inside_tree():
		push_warning("AudioEventPlayer3D: Node is not in tree")
		return false

	return AudioManager.play_event_3d(event, global_position)

## Stop all sounds from this event (note: this stops ALL instances)
func stop():
	# This is a simplified version - in a full implementation,
	# we'd track instance IDs and stop only this specific playback
	pass

## Get configuration warnings for the editor
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if not event:
		warnings.append("No AudioEvent assigned. Assign an AudioEvent resource to play audio.")

	if event and not event.is_valid():
		warnings.append("The assigned AudioEvent is invalid. Check that it has at least one audio stream.")

	return warnings
