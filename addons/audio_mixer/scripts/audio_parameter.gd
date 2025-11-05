@tool
extends Resource
class_name AudioParameter

## Interactive audio parameter for controlling layered events and music
## Similar to FMOD parameters - can control volume, pitch, filters, layer crossfades, etc.

signal value_changed(new_value: float)

#region Enums
enum ParameterType {
	CONTINUOUS,    ## Smooth float value (e.g., engine RPM, player health)
	DISCRETE,      ## Stepped integer value (e.g., weapon level, game state)
	LABELED        ## Named states (e.g., "combat", "stealth", "exploration")
}

enum AutomationTarget {
	VOLUME,        ## Controls layer/event volume
	PITCH,         ## Controls layer/event pitch
	LOWPASS,       ## Controls lowpass filter cutoff
	HIGHPASS,      ## Controls highpass filter cutoff
	LAYER_FADE,    ## Controls layer crossfade
	CUSTOM         ## Custom parameter for game logic
}
#endregion

#region Core Properties
@export_group("Parameter Identity")
@export var parameter_name: String = "NewParameter":
	set(value):
		parameter_name = value.strip_edges()
		emit_changed()

@export_multiline var description: String = "":
	set(value):
		description = value
		emit_changed()

@export var parameter_type: ParameterType = ParameterType.CONTINUOUS:
	set(value):
		parameter_type = value
		emit_changed()
#endregion

#region Value Range
@export_group("Value Range")
## Minimum value for this parameter
@export var min_value: float = 0.0:
	set(value):
		min_value = value
		if current_value < min_value:
			current_value = min_value
		emit_changed()

## Maximum value for this parameter
@export var max_value: float = 1.0:
	set(value):
		max_value = value
		if current_value > max_value:
			current_value = max_value
		emit_changed()

## Default/initial value
@export var default_value: float = 0.0:
	set(value):
		default_value = clampf(value, min_value, max_value)
		emit_changed()

## Labeled states (for LABELED type parameters)
@export var labeled_states: PackedStringArray = []:
	set(value):
		labeled_states = value
		emit_changed()
#endregion

#region Behavior
@export_group("Behavior")
## Interpolation speed (0 = instant, higher = slower smoothing)
@export_range(0.0, 10.0, 0.01) var interpolation_speed: float = 0.1:
	set(value):
		interpolation_speed = max(0.0, value)
		emit_changed()

## Seek speed for seeking to a target value
@export_range(0.0, 100.0, 0.1) var seek_speed: float = 5.0:
	set(value):
		seek_speed = max(0.0, value)
		emit_changed()

## Enable velocity tracking (useful for doppler-like effects)
@export var track_velocity: bool = false:
	set(value):
		track_velocity = value
		emit_changed()
#endregion

#region Runtime State
var current_value: float = 0.0:
	set(value):
		var old_value = current_value
		current_value = clampf(value, min_value, max_value)
		if abs(current_value - old_value) > 0.001:
			value_changed.emit(current_value)

var target_value: float = 0.0
var velocity: float = 0.0
var _last_value: float = 0.0
#endregion

#region Methods
func _init() -> void:
	current_value = default_value
	target_value = default_value

## Set parameter value instantly (no interpolation)
func set_value(value: float) -> void:
	current_value = clampf(value, min_value, max_value)
	target_value = current_value

## Set parameter value with interpolation
func set_value_smooth(value: float) -> void:
	target_value = clampf(value, min_value, max_value)

## Set labeled state by name (for LABELED type parameters)
func set_label(label: String) -> void:
	if parameter_type != ParameterType.LABELED:
		push_warning("Parameter '%s' is not a LABELED type" % parameter_name)
		return

	var index = labeled_states.find(label)
	if index >= 0:
		set_value(float(index))
	else:
		push_warning("Label '%s' not found in parameter '%s'" % [label, parameter_name])

## Get current labeled state
func get_current_label() -> String:
	if parameter_type != ParameterType.LABELED or labeled_states.is_empty():
		return ""
	var index = int(current_value)
	if index >= 0 and index < labeled_states.size():
		return labeled_states[index]
	return ""

## Update parameter (called each frame by AudioController)
func update(delta: float) -> void:
	if interpolation_speed <= 0.0:
		current_value = target_value
	else:
		current_value = lerpf(current_value, target_value, delta / interpolation_speed)

	# Track velocity if enabled
	if track_velocity:
		velocity = (current_value - _last_value) / delta if delta > 0.0 else 0.0
		_last_value = current_value

## Reset to default value
func reset() -> void:
	set_value(default_value)

## Get normalized value (0.0 to 1.0)
func get_normalized() -> float:
	if abs(max_value - min_value) < 0.001:
		return 0.0
	return (current_value - min_value) / (max_value - min_value)
#endregion
