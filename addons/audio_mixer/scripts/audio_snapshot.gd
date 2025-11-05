@tool
extends Resource
class_name AudioSnapshot

## Audio Mixer Snapshot - captures and applies complete mixer state
## Similar to Unity/FMOD mixer snapshots for dynamic mixing scenarios

#region Sub-Resources
## Individual bus state
class BusState extends Resource:
	## Bus name
	@export var bus_name: String = "Master"

	## Volume in dB
	@export_range(-80.0, 6.0, 0.1) var volume_db: float = 0.0

	## Mute state
	@export var mute: bool = false

	## Solo state
	@export var solo: bool = false

	## Lowpass filter enabled
	@export var enable_lowpass: bool = false

	## Lowpass cutoff frequency (Hz)
	@export_range(20.0, 20000.0, 1.0) var lowpass_cutoff: float = 20000.0

	## Highpass filter enabled
	@export var enable_highpass: bool = false

	## Highpass cutoff frequency (Hz)
	@export_range(20.0, 20000.0, 1.0) var highpass_cutoff: float = 20.0

	## Reverb send amount (0-1)
	@export_range(0.0, 1.0, 0.01) var reverb_send: float = 0.0

	## Compression threshold (dB)
	@export_range(-60.0, 0.0, 0.1) var compression_threshold: float = 0.0

	## Compression ratio
	@export_range(1.0, 20.0, 0.1) var compression_ratio: float = 1.0

	func apply_to_bus(bus_index: int) -> void:
		if bus_index < 0 or bus_index >= AudioServer.bus_count:
			return

		# Apply volume
		AudioServer.set_bus_volume_db(bus_index, volume_db)

		# Apply mute
		AudioServer.set_bus_mute(bus_index, mute)

		# Apply solo
		AudioServer.set_bus_solo(bus_index, solo)

		# Note: Filter effects would need to be added to the bus in AudioServer
		# This is a simplified version - full implementation would manage effects

	func capture_from_bus(bus_index: int) -> void:
		if bus_index < 0 or bus_index >= AudioServer.bus_count:
			return

		bus_name = AudioServer.get_bus_name(bus_index)
		volume_db = AudioServer.get_bus_volume_db(bus_index)
		mute = AudioServer.is_bus_mute(bus_index)
		solo = AudioServer.is_bus_solo(bus_index)
#endregion

#region Core Properties
@export_group("Snapshot Identity")
@export var snapshot_name: String = "NewSnapshot":
	set(value):
		snapshot_name = value.strip_edges()
		emit_changed()

@export var category: String = "Snapshots":
	set(value):
		category = value.strip_edges()
		emit_changed()

@export_multiline var description: String = "":
	set(value):
		description = value
		emit_changed()
#endregion

#region Bus States
@export_group("Bus States")
## Array of bus states to apply
@export var bus_states: Array[BusState] = []:
	set(value):
		bus_states = value
		emit_changed()

## Capture all buses automatically
@export var auto_capture_all_buses: bool = false:
	set(value):
		auto_capture_all_buses = value
		if value and Engine.is_editor_hint():
			capture_current_mixer_state()
		emit_changed()
#endregion

#region Transition Settings
@export_group("Transition")
## Default transition time to this snapshot in seconds
@export_range(0.0, 10.0, 0.1) var transition_time: float = 1.0:
	set(value):
		transition_time = max(0.0, value)
		emit_changed()

## Transition curve (0.5 = linear, <0.5 = ease in, >0.5 = ease out)
@export_range(0.0, 1.0, 0.01) var transition_curve: float = 0.5:
	set(value):
		transition_curve = clampf(value, 0.0, 1.0)
		emit_changed()
#endregion

#region Priority & Ducking
@export_group("Ducking")
## Priority (higher priority snapshots override lower ones)
@export_range(0, 100, 1) var priority: int = 0:
	set(value):
		priority = clampi(value, 0, 100)
		emit_changed()

## Auto-duck specified buses when this snapshot is active
@export var ducking_enabled: bool = false:
	set(value):
		ducking_enabled = value
		emit_changed()

## Buses to duck (reduce volume)
@export var ducked_buses: PackedStringArray = []:
	set(value):
		ducked_buses = value
		emit_changed()

## Amount to duck by (in dB)
@export_range(-80.0, 0.0, 0.1) var duck_amount: float = -12.0:
	set(value):
		duck_amount = clampf(value, -80.0, 0.0)
		emit_changed()

## Duck fade time
@export_range(0.0, 5.0, 0.01) var duck_fade_time: float = 0.3:
	set(value):
		duck_fade_time = max(0.0, value)
		emit_changed()
#endregion

#region Methods
## Capture current mixer state from AudioServer
func capture_current_mixer_state() -> void:
	bus_states.clear()

	for i in range(AudioServer.bus_count):
		var bus_state = BusState.new()
		bus_state.capture_from_bus(i)
		bus_states.append(bus_state)

	emit_changed()
	print("Captured mixer state: %d buses" % bus_states.size())

## Apply this snapshot to the AudioServer immediately
func apply_immediate() -> void:
	for bus_state in bus_states:
		var bus_index = AudioServer.get_bus_index(bus_state.bus_name)
		if bus_index >= 0:
			bus_state.apply_to_bus(bus_index)

## Get bus state by name
func get_bus_state(bus_name: String) -> BusState:
	for bus_state in bus_states:
		if bus_state.bus_name == bus_name:
			return bus_state
	return null

## Set bus volume in this snapshot
func set_bus_volume(bus_name: String, volume_db: float) -> void:
	var bus_state = get_bus_state(bus_name)
	if bus_state:
		bus_state.volume_db = volume_db
	else:
		# Create new bus state
		var new_state = BusState.new()
		new_state.bus_name = bus_name
		new_state.volume_db = volume_db
		bus_states.append(new_state)

## Validate snapshot
func is_valid() -> bool:
	if snapshot_name.is_empty():
		push_warning("AudioSnapshot has no name")
		return false

	if bus_states.is_empty():
		push_warning("AudioSnapshot '%s' has no bus states" % snapshot_name)
		return false

	return true

## Get debug info
func get_debug_info() -> String:
	var info = "AudioSnapshot: %s\nCategory: %s\nBuses: %d\nTransition Time: %.2fs\nPriority: %d\n" % [
		snapshot_name,
		category,
		bus_states.size(),
		transition_time,
		priority
	]

	if ducking_enabled:
		info += "Ducking: %d buses by %.1f dB\n" % [ducked_buses.size(), duck_amount]

	info += "\nBus States:\n"
	for bus_state in bus_states:
		info += "  %s: %.1f dB %s%s\n" % [
			bus_state.bus_name,
			bus_state.volume_db,
			"[MUTE]" if bus_state.mute else "",
			"[SOLO]" if bus_state.solo else ""
		]

	return info
#endregion

#region Editor Helpers
func _get_property_list() -> Array:
	var properties := []

	# Add tool button to capture mixer state
	if Engine.is_editor_hint():
		properties.append({
			"name": "capture_mixer",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_CATEGORY,
			"hint_string": "Capture Current Mixer State"
		})

	return properties
#endregion
