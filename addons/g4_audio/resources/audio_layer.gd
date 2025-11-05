## AudioLayer - Single layer in a LayeredAudioEvent
@tool
class_name AudioLayer
extends Resource

@export var layer_name: String = "Layer"
@export var stream: AudioStream
@export_range(-80.0, 24.0, 0.1) var volume_offset: float = 0.0
@export_range(0.01, 4.0, 0.01) var pitch_offset: float = 1.0
@export var parameter_min: float = 0.0
@export var parameter_max: float = 100.0
@export var fade_curve: Curve

func _init():
	# Create default linear fade curve
	if not fade_curve:
		fade_curve = Curve.new()
		fade_curve.add_point(Vector2(0.0, 0.0))
		fade_curve.add_point(Vector2(1.0, 1.0))

## Get the layer volume at a specific parameter value
func get_volume_at_parameter(param_value: float) -> float:
	if param_value < parameter_min or param_value > parameter_max:
		return -80.0  # Muted

	# Normalize parameter to 0-1 range within this layer's range
	var normalized = 0.0
	if parameter_max > parameter_min:
		normalized = (param_value - parameter_min) / (parameter_max - parameter_min)

	# Sample fade curve
	var curve_value = fade_curve.sample(normalized) if fade_curve else normalized

	# Convert to dB (0.0 to 1.0 -> -80dB to volume_offset)
	if curve_value <= 0.0:
		return -80.0
	else:
		return linear_to_db(curve_value) + volume_offset

## Check if layer is valid
func is_valid() -> bool:
	return stream != null and layer_name != ""
