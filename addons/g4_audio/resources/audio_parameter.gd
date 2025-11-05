## AudioParameter - Interactive audio parameter
## Can be continuous, discrete, or labeled
@tool
class_name AudioParameter
extends Resource

enum ParameterType {
	CONTINUOUS,  ## Float value in range (e.g., 0.0 to 100.0)
	DISCRETE,    ## Integer steps (e.g., 0, 1, 2, 3)
	LABELED      ## Named values (e.g., "Low", "Medium", "High")
}

@export var parameter_name: String = ""
@export var parameter_type: ParameterType = ParameterType.CONTINUOUS
@export var min_value: float = 0.0
@export var max_value: float = 100.0
@export var default_value: float = 0.0
@export var interpolation_speed: float = 1.0  ## How fast the parameter changes
@export var labeled_values: Array[String] = []  ## For LABELED type

var current_value: float = 0.0
var target_value: float = 0.0
var velocity: float = 0.0

func _init():
	current_value = default_value
	target_value = default_value

## Set the parameter to a new target value
func set_value(value: float) -> void:
	target_value = clampf(value, min_value, max_value)

## Get the current value (interpolated)
func get_value() -> float:
	return current_value

## Update the parameter (called by AudioManager)
func update(delta: float) -> void:
	if is_equal_approx(current_value, target_value):
		return

	var diff = target_value - current_value
	var step = interpolation_speed * delta

	if abs(diff) < step:
		current_value = target_value
		velocity = 0.0
	else:
		current_value += sign(diff) * step
		velocity = sign(diff) * step / delta

## Get normalized value (0.0 to 1.0)
func get_normalized() -> float:
	if max_value == min_value:
		return 0.0
	return (current_value - min_value) / (max_value - min_value)

## Check if parameter is valid
func is_valid() -> bool:
	return parameter_name != "" and max_value > min_value
