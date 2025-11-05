## AudioManager - Global audio system coordinator
## Access via: AudioManager.play_event(event, position)
extends Node

## Emitted when a parameter changes
signal parameter_changed(param_name: String, value: float)

## Emitted on each beat (when BPM clock is running)
signal beat(beat_number: int)

## Emitted on each bar
signal bar(bar_number: int)

## Object pools
var _pool_2d: AudioPool
var _pool_3d: AudioPool

## Parameters registry
var _parameters: Dictionary = {}  # String -> AudioParameter

## Layered audio instances (for parameter-driven crossfading)
var _layered_instances: Dictionary = {}  # int -> LayeredInstance

## BPM Clock
var _bpm: float = 120.0
var _beat_timer: float = 0.0
var _current_beat: int = 0
var _current_bar: int = 0
var _beats_per_bar: int = 4
var _is_clock_running: bool = false

## Layered instance data
class LayeredInstance:
	var players: Array[AudioStreamPlayer3D] = []
	var event: LayeredAudioEvent
	var current_volumes: Array[float] = []
	var position: Vector3
	var instance_id: int

func _ready():
	# Initialize pools
	_pool_2d = AudioPool.new(AudioPool.PoolType.POOL_2D, 50)
	_pool_3d = AudioPool.new(AudioPool.PoolType.POOL_3D, 30)
	add_child(_pool_2d)
	add_child(_pool_3d)

	# Set the pools' names for debugging
	_pool_2d.name = "AudioPool2D"
	_pool_3d.name = "AudioPool3D"

func _process(delta):
	# Update parameters
	for param in _parameters.values():
		param.update(delta)

	# Update BPM clock
	if _is_clock_running:
		_update_bpm_clock(delta)

	# Update layered audio instances
	_update_layered_instances(delta)

## Update BPM clock
func _update_bpm_clock(delta: float):
	var beat_duration = 60.0 / _bpm
	_beat_timer += delta

	if _beat_timer >= beat_duration:
		_beat_timer -= beat_duration
		_current_beat += 1
		beat.emit(_current_beat)

		if _current_beat % _beats_per_bar == 0:
			_current_bar += 1
			bar.emit(_current_bar)

## Play an AudioEvent at a position (2D)
func play_event(event: AudioEvent, position: Vector2 = Vector2.ZERO) -> bool:
	if not event or not event.is_valid():
		push_warning("Invalid audio event")
		return false

	if not event.can_play():
		return false

	var player = _pool_2d.acquire()
	if not player:
		return false

	_configure_player_2d(player, event, position)
	player.play()
	event.mark_played()

	return true

## Play an AudioEvent at a 3D position
func play_event_3d(event: AudioEvent, position: Vector3 = Vector3.ZERO) -> bool:
	if not event or not event.is_valid():
		push_warning("Invalid audio event")
		return false

	if not event.can_play():
		return false

	var player = _pool_3d.acquire()
	if not player:
		return false

	_configure_player_3d(player, event, position)
	player.play()
	event.mark_played()

	return true

## Configure a 2D player
func _configure_player_2d(player: AudioStreamPlayer2D, event: AudioEvent, position: Vector2):
	player.stream = event.get_random_stream()
	player.volume_db = event.get_random_volume_db()
	player.pitch_scale = event.get_random_pitch()
	player.bus = event.bus_name
	player.position = position
	player.max_distance = event.max_distance
	player.attenuation = event.attenuation

## Configure a 3D player
func _configure_player_3d(player: AudioStreamPlayer3D, event: AudioEvent, position: Vector3):
	player.stream = event.get_random_stream()
	player.volume_db = event.get_random_volume_db()
	player.pitch_scale = event.get_random_pitch()
	player.bus = event.bus_name
	player.position = position
	player.max_distance = event.max_distance
	player.attenuation_filter_cutoff_hz = 5000.0

## Play a LayeredAudioEvent (parameter-driven crossfading)
func play_layered_event(event: LayeredAudioEvent, position: Vector3 = Vector3.ZERO) -> int:
	if not event or not event.is_valid():
		push_warning("Invalid layered audio event")
		return -1

	var instance = LayeredInstance.new()
	instance.event = event
	instance.position = position
	instance.instance_id = Time.get_ticks_msec()

	# Create a player for each layer
	for layer in event.layers:
		var player = _pool_3d.acquire()
		if player:
			player.stream = layer.stream
			player.pitch_scale = layer.pitch_offset
			player.bus = event.bus_name
			player.position = position
			player.max_distance = event.max_distance
			player.volume_db = -80.0  # Start muted
			player.play()
			instance.players.append(player)
			instance.current_volumes.append(-80.0)

	_layered_instances[instance.instance_id] = instance
	return instance.instance_id

## Stop a layered event instance
func stop_layered_event(instance_id: int, fade_out: float = 0.0):
	if not _layered_instances.has(instance_id):
		return

	var instance = _layered_instances[instance_id]
	for player in instance.players:
		if fade_out > 0.0:
			var tween = create_tween()
			tween.tween_property(player, "volume_db", -80.0, fade_out)
			tween.tween_callback(player.stop)
		else:
			player.stop()

	_layered_instances.erase(instance_id)

## Update all layered instances based on parameter values
func _update_layered_instances(delta: float):
	for instance in _layered_instances.values():
		var event = instance.event
		var param_value = get_parameter(event.control_parameter)
		var target_volumes = event.get_layer_volumes(param_value)

		# Smoothly interpolate volumes
		for i in range(instance.players.size()):
			if i >= target_volumes.size():
				continue

			var current = instance.current_volumes[i]
			var target = target_volumes[i]
			var speed = 1.0 / event.crossfade_time if event.crossfade_time > 0 else 10.0

			instance.current_volumes[i] = move_toward(current, target, speed * delta * 80.0)
			instance.players[i].volume_db = instance.current_volumes[i]

## Create or register a parameter
func create_parameter(name: String, min_val: float, max_val: float, default: float) -> AudioParameter:
	if _parameters.has(name):
		push_warning("Parameter '%s' already exists" % name)
		return _parameters[name]

	var param = AudioParameter.new()
	param.parameter_name = name
	param.min_value = min_val
	param.max_value = max_val
	param.default_value = default
	param.current_value = default
	param.target_value = default

	_parameters[name] = param
	return param

## Set a parameter value
func set_parameter(name: String, value: float):
	if not _parameters.has(name):
		# Auto-create parameter with reasonable defaults
		create_parameter(name, 0.0, 100.0, 0.0)

	_parameters[name].set_value(value)
	parameter_changed.emit(name, value)

## Get a parameter value
func get_parameter(name: String) -> float:
	if _parameters.has(name):
		return _parameters[name].get_value()
	return 0.0

## Start BPM clock
func start_bpm_clock(bpm: float = 120.0, beats_per_bar: int = 4):
	_bpm = bpm
	_beats_per_bar = beats_per_bar
	_is_clock_running = true
	_beat_timer = 0.0
	_current_beat = 0
	_current_bar = 0

## Stop BPM clock
func stop_bpm_clock():
	_is_clock_running = false

## Get pool statistics
func get_pool_stats() -> Dictionary:
	return {
		"pool_2d": _pool_2d.get_stats(),
		"pool_3d": _pool_3d.get_stats(),
		"layered_instances": _layered_instances.size()
	}
