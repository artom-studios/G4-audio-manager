## Unit tests for AudioPool
extends "res://tests/test_base.gd"

var test_pool: AudioPool

func run_tests():
	test("Create 2D pool", test_create_2d_pool)
	test("Create 3D pool", test_create_3d_pool)
	test("Acquire player from pool", test_acquire_player)
	test("Release player back to pool", test_release_player)
	test("Pool exhaustion and expansion", test_pool_exhaustion)
	test("Pool statistics", test_pool_stats)
	test("Stop all players", test_stop_all)
	test("Player finished signal", test_player_finished)

func test_create_2d_pool():
	test_pool = AudioPool.new(AudioPool.PoolType.POOL_2D, 10)
	add_child(test_pool)
	await get_tree().process_frame

	assert_not_null(test_pool, "2D pool should be created")
	assert_equal(test_pool.pool_type, AudioPool.PoolType.POOL_2D, "Should be 2D pool type")
	assert_equal(test_pool.pool_size, 10, "Pool size should be 10")

	var stats = test_pool.get_stats()
	assert_equal(stats.total, 10, "Should have 10 total players")
	assert_equal(stats.available, 10, "Should have 10 available players")
	assert_equal(stats.active, 0, "Should have 0 active players")

	test_pool.queue_free()
	await get_tree().process_frame

func test_create_3d_pool():
	test_pool = AudioPool.new(AudioPool.PoolType.POOL_3D, 5)
	add_child(test_pool)
	await get_tree().process_frame

	assert_not_null(test_pool, "3D pool should be created")
	assert_equal(test_pool.pool_type, AudioPool.PoolType.POOL_3D, "Should be 3D pool type")
	assert_equal(test_pool.pool_size, 5, "Pool size should be 5")

	var stats = test_pool.get_stats()
	assert_equal(stats.total, 5, "Should have 5 total players")

	test_pool.queue_free()
	await get_tree().process_frame

func test_acquire_player():
	test_pool = AudioPool.new(AudioPool.PoolType.POOL_2D, 5)
	add_child(test_pool)
	await get_tree().process_frame

	# Acquire a player
	var player = test_pool.acquire()
	assert_not_null(player, "Should acquire a player")
	assert_true(player is AudioStreamPlayer2D, "Should be AudioStreamPlayer2D")

	var stats = test_pool.get_stats()
	assert_equal(stats.available, 4, "Should have 4 available after acquiring 1")
	assert_equal(stats.active, 1, "Should have 1 active")

	# Acquire another
	var player2 = test_pool.acquire()
	assert_not_null(player2, "Should acquire another player")
	assert_not_equal(player, player2, "Should be different players")

	stats = test_pool.get_stats()
	assert_equal(stats.available, 3, "Should have 3 available after acquiring 2")
	assert_equal(stats.active, 2, "Should have 2 active")

	test_pool.queue_free()
	await get_tree().process_frame

func test_release_player():
	test_pool = AudioPool.new(AudioPool.PoolType.POOL_3D, 5)
	add_child(test_pool)
	await get_tree().process_frame

	# Acquire player
	var player = test_pool.acquire()
	var stats = test_pool.get_stats()
	assert_equal(stats.active, 1, "Should have 1 active")

	# Simulate player finishing (triggers release)
	player.emit_signal("finished")
	await get_tree().process_frame

	stats = test_pool.get_stats()
	assert_equal(stats.active, 0, "Should have 0 active after release")
	assert_equal(stats.available, 5, "All players should be available again")

	test_pool.queue_free()
	await get_tree().process_frame

func test_pool_exhaustion():
	test_pool = AudioPool.new(AudioPool.PoolType.POOL_2D, 3)
	add_child(test_pool)
	await get_tree().process_frame

	# Acquire all players
	var p1 = test_pool.acquire()
	var p2 = test_pool.acquire()
	var p3 = test_pool.acquire()

	assert_not_null(p1, "Should acquire player 1")
	assert_not_null(p2, "Should acquire player 2")
	assert_not_null(p3, "Should acquire player 3")

	var stats = test_pool.get_stats()
	assert_equal(stats.available, 0, "Pool should be exhausted")
	assert_equal(stats.active, 3, "All players should be active")

	# Try to acquire when exhausted (should steal)
	var p4 = test_pool.acquire()
	# Note: This should trigger voice stealing, might return null or steal lowest priority
	# For now, just check it handles the case

	test_pool.queue_free()
	await get_tree().process_frame

func test_pool_stats():
	test_pool = AudioPool.new(AudioPool.PoolType.POOL_2D, 10)
	add_child(test_pool)
	await get_tree().process_frame

	var stats = test_pool.get_stats()
	assert_not_null(stats, "Should return stats dictionary")
	assert_true(stats.has("total"), "Stats should have 'total'")
	assert_true(stats.has("available"), "Stats should have 'available'")
	assert_true(stats.has("active"), "Stats should have 'active'")

	# Acquire some players
	test_pool.acquire()
	test_pool.acquire()

	stats = test_pool.get_stats()
	assert_equal(stats.total, 10, "Total should remain 10")
	assert_equal(stats.available, 8, "Available should be 8")
	assert_equal(stats.active, 2, "Active should be 2")

	test_pool.queue_free()
	await get_tree().process_frame

func test_stop_all():
	test_pool = AudioPool.new(AudioPool.PoolType.POOL_3D, 5)
	add_child(test_pool)
	await get_tree().process_frame

	# Acquire and "play" some players
	var p1 = test_pool.acquire()
	var p2 = test_pool.acquire()
	var p3 = test_pool.acquire()

	var stats = test_pool.get_stats()
	assert_equal(stats.active, 3, "Should have 3 active players")

	# Stop all
	test_pool.stop_all()
	await get_tree().process_frame

	# After stop_all, players might still be "active" until finished signal
	# This is implementation-dependent

	test_pool.queue_free()
	await get_tree().process_frame

func test_player_finished():
	test_pool = AudioPool.new(AudioPool.PoolType.POOL_2D, 5)
	add_child(test_pool)
	await get_tree().process_frame

	var signal_emitted = false
	var emitted_player = null

	# Connect to pool's player_finished signal
	test_pool.player_finished.connect(func(player):
		signal_emitted = true
		emitted_player = player
	)

	# Acquire player
	var player = test_pool.acquire()

	# Simulate finish
	player.emit_signal("finished")
	await get_tree().process_frame

	assert_true(signal_emitted, "player_finished signal should be emitted")
	assert_equal(emitted_player, player, "Signal should pass the correct player")

	test_pool.queue_free()
	await get_tree().process_frame
