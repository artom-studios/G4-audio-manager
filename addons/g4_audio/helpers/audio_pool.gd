## AudioPool - Object pooling for audio players
## Manages a pool of AudioStreamPlayer2D/3D nodes for efficient audio playback
class_name AudioPool
extends Node

enum PoolType {
	POOL_2D,
	POOL_3D
}

signal player_finished(player)

var pool_type: PoolType
var pool_size: int
var _available_players: Array = []
var _active_players: Array = []

func _init(type: PoolType = PoolType.POOL_2D, size: int = 50):
	pool_type = type
	pool_size = size

func _ready():
	_create_pool()

## Create the initial pool of players
func _create_pool():
	for i in range(pool_size):
		var player = _create_player()
		_available_players.append(player)
		add_child(player)

## Create a single player of the appropriate type
func _create_player():
	var player
	match pool_type:
		PoolType.POOL_2D:
			player = AudioStreamPlayer2D.new()
		PoolType.POOL_3D:
			player = AudioStreamPlayer3D.new()
			player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE

	player.finished.connect(_on_player_finished.bind(player))
	player.bus = "Master"

	return player

## Acquire a player from the pool
func acquire():
	if _available_players.is_empty():
		# Try to steal from lowest priority active player
		if not _active_players.is_empty():
			var victim = _active_players[0]
			victim.stop()
			_release_player(victim)
			push_warning("Audio pool exhausted, stealing from active player")
		else:
			push_error("Audio pool completely exhausted!")
			return null

	var player = _available_players.pop_back()
	_active_players.append(player)
	return player

## Release a player back to the pool
func _release_player(player):
	var idx = _active_players.find(player)
	if idx != -1:
		_active_players.remove_at(idx)
		_available_players.append(player)
		player.stream = null

## Called when a player finishes playing
func _on_player_finished(player):
	_release_player(player)
	player_finished.emit(player)

## Get pool statistics
func get_stats() -> Dictionary:
	return {
		"total": pool_size,
		"available": _available_players.size(),
		"active": _active_players.size()
	}

## Stop all active players
func stop_all():
	for player in _active_players.duplicate():
		player.stop()

## Expand pool size dynamically
func expand_pool(additional_size: int):
	for i in range(additional_size):
		var player = _create_player()
		_available_players.append(player)
		add_child(player)
	pool_size += additional_size
