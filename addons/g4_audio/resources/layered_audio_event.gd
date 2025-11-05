## LayeredAudioEvent - Multi-layer audio with parameter-driven crossfading
## Perfect for car engines, wind, crowd ambience, etc.
@tool
class_name LayeredAudioEvent
extends Resource

@export var event_name: String = "New Layered Event"
@export var category: String = "Uncategorized"
@export_multiline var description: String = ""

## The parameter that controls layer crossfading
@export var control_parameter: String = ""

## Audio layers
@export var layers: Array[AudioLayer] = []

## Crossfade settings
@export var crossfade_time: float = 0.3
@export var sync_layers: bool = true  ## Keep layers in sync

## Spatial audio
@export var spatial_mode: AudioEvent.SpatialMode = AudioEvent.SpatialMode.MODE_3D
@export_range(0.0, 4096.0) var max_distance: float = 100.0

## Bus routing
@export var bus_name: String = "Master"

## Get volumes for all layers at a specific parameter value
func get_layer_volumes(param_value: float) -> Array[float]:
	var volumes: Array[float] = []
	for layer in layers:
		volumes.append(layer.get_volume_at_parameter(param_value))
	return volumes

## Check if event is valid
func is_valid() -> bool:
	if event_name == "" or control_parameter == "":
		return false

	for layer in layers:
		if not layer.is_valid():
			return false

	return layers.size() > 0

## Get display name for editor
func get_display_name() -> String:
	return event_name if event_name != "" else resource_path.get_file().get_basename()
