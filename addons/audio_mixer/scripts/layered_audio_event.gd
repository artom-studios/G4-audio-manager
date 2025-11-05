@tool
extends Resource
class_name LayeredAudioEvent

## Layered Audio Event - supports multiple audio layers with parameter-driven crossfading
## Perfect for car engines, ambiences, and other layered sounds that change based on game state

signal layer_changed(layer_index: int)

#region Sub-Resources
## Individual audio layer with its own streams and parameter ranges
class AudioLayer extends Resource:
	## Layer name for identification
	@export var layer_name: String = "Layer"

	## Audio streams for this layer (can have variations)
	@export var streams: Array[AudioStream] = []

	## Parameter range where this layer is active (min, max)
	@export var parameter_range: Vector2 = Vector2(0.0, 1.0)

	## Volume offset for this layer in dB
	@export_range(-80.0, 6.0, 0.1) var volume_offset: float = 0.0

	## Pitch offset for this layer
	@export_range(0.1, 4.0, 0.01) var pitch_offset: float = 1.0

	## Crossfade curve power (1.0 = linear, <1.0 = ease out, >1.0 = ease in)
	@export_range(0.1, 4.0, 0.1) var fade_curve: float = 1.0

	## Should this layer loop?
	@export var looping: bool = true

	## Layer enabled/disabled
	@export var enabled: bool = true

	## Get a random stream from this layer
	func get_random_stream() -> AudioStream:
		if streams.is_empty():
			return null
		return streams[randi() % streams.size()]

	## Calculate volume based on parameter value
	func calculate_volume(param_value: float) -> float:
		if not enabled or streams.is_empty():
			return -80.0

		# Check if parameter is within range
		if param_value < parameter_range.x or param_value > parameter_range.y:
			return -80.0

		# Calculate crossfade based on position in range
		var range_size = parameter_range.y - parameter_range.x
		if range_size < 0.001:
			return volume_offset

		var normalized = (param_value - parameter_range.x) / range_size

		# Apply fade curve
		var fade = pow(normalized, fade_curve)

		# Linear crossfade at edges
		if normalized < 0.1:
			fade *= normalized / 0.1
		elif normalized > 0.9:
			fade *= (1.0 - normalized) / 0.1

		# Convert to dB (fade is 0-1, convert to dB)
		var fade_db = linear_to_db(fade) if fade > 0.0 else -80.0
		return fade_db + volume_offset
#endregion

#region Core Properties
@export_group("Event Identity")
@export var event_name: String = "NewLayeredEvent":
	set(value):
		event_name = value.strip_edges()
		emit_changed()

@export var category: String = "Layered":
	set(value):
		category = value.strip_edges()
		emit_changed()

@export_multiline var description: String = "":
	set(value):
		description = value
		emit_changed()
#endregion

#region Layers
@export_group("Layers")
## Array of audio layers
@export var layers: Array[AudioLayer] = []:
	set(value):
		layers = value
		emit_changed()

## Controlling parameter name (must exist in AudioController)
@export var control_parameter: String = "":
	set(value):
		control_parameter = value.strip_edges()
		emit_changed()

## Crossfade time between layers in seconds
@export_range(0.0, 5.0, 0.01) var crossfade_time: float = 0.5:
	set(value):
		crossfade_time = max(0.0, value)
		emit_changed()
#endregion

#region Playback Settings
@export_group("Playback")
## Spatial mode
@export_enum("2D:0", "3D:1") var spatial_mode: int = 0:
	set(value):
		spatial_mode = value
		emit_changed()

## Audio bus
@export var bus_name: String = "Master":
	set(value):
		bus_name = value
		emit_changed()

## Master volume offset in dB
@export_range(-80.0, 6.0, 0.1) var master_volume: float = 0.0:
	set(value):
		master_volume = value
		emit_changed()

## Master pitch multiplier
@export_range(0.1, 4.0, 0.01) var master_pitch: float = 1.0:
	set(value):
		master_pitch = max(0.1, value)
		emit_changed()

## Maximum concurrent instances
@export_range(1, 10, 1) var max_concurrent_instances: int = 2:
	set(value):
		max_concurrent_instances = max(1, value)
		emit_changed()
#endregion

#region 3D Audio Settings
@export_group("3D Audio")
@export_range(1.0, 4096.0, 0.1) var max_distance: float = 100.0:
	set(value):
		max_distance = max(1.0, value)
		emit_changed()

@export_range(0.1, 100.0, 0.1) var unit_size: float = 10.0:
	set(value):
		unit_size = max(0.1, value)
		emit_changed()

@export_enum("Inverse:0", "Inverse Square:1", "Logarithmic:2") var attenuation_model: int = 0:
	set(value):
		attenuation_model = value
		emit_changed()
#endregion

#region Advanced
@export_group("Advanced")
## Pitch controlled by parameter (multiplier per unit)
@export var pitch_follows_parameter: bool = false:
	set(value):
		pitch_follows_parameter = value
		emit_changed()

@export_range(0.0, 10.0, 0.1) var pitch_parameter_scale: float = 1.0:
	set(value):
		pitch_parameter_scale = max(0.0, value)
		emit_changed()

## Sync all layers to same playback position
@export var sync_layers: bool = true:
	set(value):
		sync_layers = value
		emit_changed()
#endregion

#region Runtime State
var _active_instances: int = 0
var _current_parameter_value: float = 0.0
#endregion

#region Methods
## Validate event has required data
func is_valid() -> bool:
	if event_name.is_empty():
		push_warning("LayeredAudioEvent has no name")
		return false

	if layers.is_empty():
		push_warning("LayeredAudioEvent '%s' has no layers" % event_name)
		return false

	if control_parameter.is_empty():
		push_warning("LayeredAudioEvent '%s' has no control parameter" % event_name)
		return false

	var has_streams = false
	for layer in layers:
		if layer.enabled and not layer.streams.is_empty():
			has_streams = true
			break

	if not has_streams:
		push_warning("LayeredAudioEvent '%s' has no enabled layers with streams" % event_name)
		return false

	return true

## Get active layers based on parameter value
func get_active_layers(param_value: float) -> Array[AudioLayer]:
	var active: Array[AudioLayer] = []
	for layer in layers:
		if layer.enabled and not layer.streams.is_empty():
			if param_value >= layer.parameter_range.x and param_value <= layer.parameter_range.y:
				active.append(layer)
	return active

## Calculate pitch based on parameter (if enabled)
func get_parameter_pitch(param_value: float) -> float:
	if not pitch_follows_parameter:
		return master_pitch
	return master_pitch * (1.0 + param_value * pitch_parameter_scale)

## Get debug info
func get_debug_info() -> String:
	return """
	LayeredAudioEvent: %s
	Category: %s
	Layers: %d
	Control Parameter: %s
	Bus: %s
	Spatial: %s
	Active Instances: %d/%d
	""" % [
		event_name,
		category,
		layers.size(),
		control_parameter,
		bus_name,
		"3D" if spatial_mode == 1 else "2D",
		_active_instances,
		max_concurrent_instances
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
