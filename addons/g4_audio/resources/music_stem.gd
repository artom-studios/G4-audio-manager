## MusicStem - Single stem/layer in adaptive music
@tool
class_name MusicStem
extends Resource

@export var stem_name: String = "Stem"
@export var stream: AudioStream
@export_range(-80.0, 24.0, 0.1) var volume_offset: float = 0.0
@export var default_enabled: bool = true

## Parameter control (optional)
@export var controlled_by_parameter: bool = false
@export var control_parameter: String = ""
@export var parameter_threshold: float = 0.5

## Check if stem should be enabled based on parameter value
func should_be_enabled(param_value: float) -> bool:
	if not controlled_by_parameter:
		return default_enabled

	return param_value >= parameter_threshold

## Check if stem is valid
func is_valid() -> bool:
	return stream != null and stem_name != ""
