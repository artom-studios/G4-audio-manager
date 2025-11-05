# G4 Audio Studio - Testing Guide & Success Criteria
## Detailed Test Cases for Every Implementation Step

---

## 📋 Table of Contents
1. [Testing Philosophy](#testing-philosophy)
2. [Phase 1: Core Resource Types](#phase-1-core-resource-types)
3. [Phase 2: Runtime Systems](#phase-2-runtime-systems)
4. [Phase 3: Editor Plugin Foundation](#phase-3-editor-plugin-foundation)
5. [Phase 4: Core UI Components](#phase-4-core-ui-components)
6. [Phase 5: Enhanced UX](#phase-5-enhanced-ux)
7. [Phase 6: Advanced Features](#phase-6-advanced-features)
8. [Phase 7: Documentation & Polish](#phase-7-documentation--polish)
9. [Integration Test Scenarios](#integration-test-scenarios)
10. [Performance Benchmarks](#performance-benchmarks)

---

## 🎯 Testing Philosophy

### Test Levels
```
Unit Tests        → Individual functions work correctly
Integration Tests → Components work together
System Tests      → Full workflows function end-to-end
User Tests        → Real users can accomplish tasks
Performance Tests → System meets speed/memory requirements
```

### Success Criteria Format
```
For each feature:
✅ GIVEN: Initial conditions
✅ WHEN: Action performed
✅ THEN: Expected outcome
✅ VERIFY: How to check it worked
```

---

## 🔧 Phase 1: Core Resource Types

### 1.1 AudioEvent Resource Class

**File:** `addons/audio_mixer/scripts/audio_event.gd`

#### Test Case 1.1.1: Create Basic AudioEvent
```gdscript
# Test Script: test_audio_event_basic.gd
extends Node

func test_create_audio_event():
    var event = AudioEvent.new()
    event.event_name = "TestSound"
    event.category = "SFX/Test"

    # SUCCESS CRITERIA:
    assert(event != null, "Event should be created")
    assert(event.event_name == "TestSound", "Name should be set")
    assert(event.category == "SFX/Test", "Category should be set")
    assert(event is Resource, "Event should extend Resource")
    print("✅ Test 1.1.1 PASSED: Basic AudioEvent creation")
```

**Success Criteria:**
- ✅ Can instantiate AudioEvent with `AudioEvent.new()`
- ✅ Can set `event_name` property
- ✅ Can set `category` property
- ✅ Event extends `Resource` class
- ✅ Can save as `.tres` file
- ✅ Can load saved `.tres` file

**Manual Verification:**
1. Create new GDScript file in Godot
2. Paste test script above
3. Run in Godot editor
4. Console shows "✅ Test 1.1.1 PASSED"

---

#### Test Case 1.1.2: Audio Stream Management
```gdscript
func test_audio_streams():
    var event = AudioEvent.new()
    var stream1 = AudioStreamWAV.new()
    var stream2 = AudioStreamWAV.new()

    event.streams = [stream1, stream2]

    # SUCCESS CRITERIA:
    assert(event.streams.size() == 2, "Should have 2 streams")
    assert(event.streams[0] == stream1, "First stream should match")
    assert(event.is_valid(), "Event with streams should be valid")

    # Test validation
    event.streams = []
    assert(not event.is_valid(), "Event without streams should be invalid")

    print("✅ Test 1.1.2 PASSED: Stream management")
```

**Success Criteria:**
- ✅ Can add multiple audio streams to `streams` array
- ✅ Can access streams by index
- ✅ `is_valid()` returns `true` when streams exist
- ✅ `is_valid()` returns `false` when streams array is empty
- ✅ Streams persist after saving/loading resource

**Manual Verification:**
1. In Godot: Create > New Resource > AudioEvent
2. Add audio files to `streams` array
3. Save as `.tres`
4. Close and reopen resource
5. Verify streams are still there

---

#### Test Case 1.1.3: Randomization System
```gdscript
func test_randomization():
    var event = AudioEvent.new()
    event.volume_range = Vector2(-3.0, 0.0)
    event.pitch_range = Vector2(0.9, 1.1)

    # Test volume randomization
    var volumes = []
    for i in range(100):
        var vol = event.get_random_volume_db()
        volumes.append(vol)
        assert(vol >= -3.0 and vol <= 0.0, "Volume should be in range")

    # Verify distribution (should have variety)
    var unique_values = {}
    for v in volumes:
        unique_values[snapped(v, 0.1)] = true
    assert(unique_values.size() > 10, "Should have varied volume values")

    # Test pitch randomization
    var pitches = []
    for i in range(100):
        var pitch = event.get_random_pitch()
        pitches.append(pitch)
        assert(pitch >= 0.9 and pitch <= 1.1, "Pitch should be in range")

    print("✅ Test 1.1.3 PASSED: Randomization system")
```

**Success Criteria:**
- ✅ `volume_range` accepts Vector2 with min/max values
- ✅ `get_random_volume_db()` returns value within range
- ✅ `pitch_range` accepts Vector2 with min/max values
- ✅ `get_random_pitch()` returns value within range
- ✅ Random values have good distribution (not always same)
- ✅ Ranges are validated (min <= max)

**Manual Verification:**
1. Create AudioEvent in editor
2. Set Volume Range to (-3, 0)
3. Set Pitch Range to (0.9, 1.1)
4. Run test script above
5. Check console for "PASSED" message

---

#### Test Case 1.1.4: Playback Modes
```gdscript
func test_playback_modes():
    var event = AudioEvent.new()
    var stream1 = load("res://test_audio/sound1.wav")
    var stream2 = load("res://test_audio/sound2.wav")
    var stream3 = load("res://test_audio/sound3.wav")
    event.streams = [stream1, stream2, stream3]

    # Test RANDOM_ONE mode
    event.playback_mode = AudioEvent.PlaybackMode.RANDOM_ONE
    var selected_streams = []
    for i in range(20):
        var stream = event.get_random_stream()
        selected_streams.append(stream)
    # Should have variety
    var unique = {}
    for s in selected_streams:
        unique[s] = true
    assert(unique.size() > 1, "Random mode should select different streams")

    # Test SEQUENTIAL mode
    event.playback_mode = AudioEvent.PlaybackMode.SEQUENTIAL
    event._current_stream_index = 0
    assert(event.get_random_stream() == stream1, "First call should return stream1")
    assert(event.get_random_stream() == stream2, "Second call should return stream2")
    assert(event.get_random_stream() == stream3, "Third call should return stream3")
    assert(event.get_random_stream() == stream1, "Fourth call should wrap to stream1")

    print("✅ Test 1.1.4 PASSED: Playback modes")
```

**Success Criteria:**
- ✅ RANDOM_ONE mode selects different streams randomly
- ✅ SEQUENTIAL mode plays streams in order
- ✅ Sequential mode wraps back to first stream
- ✅ ONE_SHOT mode plays once and stops
- ✅ LOOPING mode enables loop on the player

**Manual Verification:**
1. Create AudioEvent with 3 audio files
2. Set Playback Mode to "Random One"
3. Play event 10 times, verify different sounds play
4. Set Playback Mode to "Sequential"
5. Play event multiple times, verify order (1,2,3,1,2,3...)

---

#### Test Case 1.1.5: Cooldown System
```gdscript
func test_cooldown():
    var event = AudioEvent.new()
    event.cooldown_time = 1.0  # 1 second cooldown

    # Should be able to play initially
    assert(event.can_play(), "Should be able to play initially")

    # Mark as played
    event.mark_played()

    # Should not be able to play immediately after
    assert(not event.can_play(), "Should not play during cooldown")

    # Wait for cooldown
    await get_tree().create_timer(1.1).timeout

    # Should be able to play again
    assert(event.can_play(), "Should be able to play after cooldown")

    print("✅ Test 1.1.5 PASSED: Cooldown system")
```

**Success Criteria:**
- ✅ `cooldown_time` property accepts float value (0-10 seconds)
- ✅ `can_play()` returns `true` initially
- ✅ `mark_played()` records the play time
- ✅ `can_play()` returns `false` during cooldown period
- ✅ `can_play()` returns `true` after cooldown expires
- ✅ Cooldown of 0.0 allows immediate replay

**Manual Verification:**
1. Create AudioEvent with cooldown = 1.0
2. Play event
3. Try to play immediately again - should be blocked
4. Wait 1 second
5. Try to play again - should work

---

#### Test Case 1.1.6: Priority and Instance Limits
```gdscript
func test_priority_and_limits():
    var event = AudioEvent.new()
    event.priority = AudioEvent.Priority.HIGH
    event.max_concurrent_instances = 3

    # Test priority
    assert(event.priority == AudioEvent.Priority.HIGH, "Priority should be HIGH")

    # Test instance tracking
    assert(event._active_instances == 0, "Should start with 0 instances")
    assert(not event.is_at_max_instances(), "Should not be at max initially")

    event._active_instances = 3
    assert(event.is_at_max_instances(), "Should be at max with 3 instances")

    event._active_instances = 4
    assert(event.is_at_max_instances(), "Should be at max when over limit")

    print("✅ Test 1.1.6 PASSED: Priority and instance limits")
```

**Success Criteria:**
- ✅ Can set priority (LOWEST, LOW, NORMAL, HIGH, CRITICAL)
- ✅ Can set max_concurrent_instances (1-100)
- ✅ `is_at_max_instances()` correctly reports when limit reached
- ✅ Priority is used for voice stealing decisions
- ✅ Instance counting works correctly

---

#### Test Case 1.1.7: 3D Spatial Settings
```gdscript
func test_spatial_settings():
    var event = AudioEvent.new()

    # Test 2D mode
    event.spatial_mode = AudioEvent.SpatialMode.MODE_2D
    assert(event.spatial_mode == AudioEvent.SpatialMode.MODE_2D, "Should be 2D mode")

    # Test 3D mode
    event.spatial_mode = AudioEvent.SpatialMode.MODE_3D
    event.max_distance = 100.0
    event.unit_size = 10.0
    event.attenuation_model = 0  # Inverse

    assert(event.spatial_mode == AudioEvent.SpatialMode.MODE_3D, "Should be 3D mode")
    assert(event.max_distance == 100.0, "Max distance should be set")
    assert(event.unit_size == 10.0, "Unit size should be set")

    print("✅ Test 1.1.7 PASSED: 3D spatial settings")
```

**Success Criteria:**
- ✅ Can set spatial_mode to MODE_2D or MODE_3D
- ✅ 3D mode exposes attenuation_model (Inverse, Inverse Square, Logarithmic)
- ✅ Can set max_distance (audible range)
- ✅ Can set unit_size (distance scaling)
- ✅ Can set doppler_tracking (Disabled, Idle, Physics)
- ✅ Settings persist when saved

---

#### Test Case 1.1.8: Bus Routing
```gdscript
func test_bus_routing():
    var event = AudioEvent.new()

    # Default bus
    assert(event.bus_name == "Master", "Should default to Master bus")

    # Valid bus
    event.bus_name = "SFX"
    assert(event.bus_name == "SFX", "Should accept valid bus name")

    # Invalid bus should fallback to Master
    event.bus_name = "NonExistentBus"
    assert(event.bus_name == "Master", "Should fallback to Master for invalid bus")

    print("✅ Test 1.1.8 PASSED: Bus routing")
```

**Success Criteria:**
- ✅ Default bus is "Master"
- ✅ Can set bus_name to any valid AudioServer bus
- ✅ Invalid bus names fallback to "Master" with warning
- ✅ Bus validation works in editor
- ✅ Bus dropdown shows all available buses

---

#### Test Case 1.1.9: Save and Load Persistence
```gdscript
func test_save_load():
    var event = AudioEvent.new()
    event.event_name = "PersistenceTest"
    event.category = "Test/Category"
    event.volume_range = Vector2(-5.0, 2.0)
    event.pitch_range = Vector2(0.8, 1.2)
    event.max_concurrent_instances = 7
    event.cooldown_time = 0.5
    event.priority = AudioEvent.Priority.HIGH
    event.spatial_mode = AudioEvent.SpatialMode.MODE_3D
    event.bus_name = "SFX"

    # Save
    var save_path = "res://test_audio_event.tres"
    var err = ResourceSaver.save(event, save_path)
    assert(err == OK, "Should save successfully")

    # Load
    var loaded_event = load(save_path) as AudioEvent
    assert(loaded_event != null, "Should load successfully")
    assert(loaded_event.event_name == "PersistenceTest", "Name should persist")
    assert(loaded_event.category == "Test/Category", "Category should persist")
    assert(loaded_event.volume_range == Vector2(-5.0, 2.0), "Volume range should persist")
    assert(loaded_event.pitch_range == Vector2(0.8, 1.2), "Pitch range should persist")
    assert(loaded_event.max_concurrent_instances == 7, "Max instances should persist")
    assert(loaded_event.cooldown_time == 0.5, "Cooldown should persist")
    assert(loaded_event.priority == AudioEvent.Priority.HIGH, "Priority should persist")
    assert(loaded_event.spatial_mode == AudioEvent.SpatialMode.MODE_3D, "Spatial mode should persist")
    assert(loaded_event.bus_name == "SFX", "Bus name should persist")

    print("✅ Test 1.1.9 PASSED: Save and load persistence")
```

**Success Criteria:**
- ✅ Can save AudioEvent as `.tres` file
- ✅ All properties persist after save/load
- ✅ Audio streams persist (as resource paths)
- ✅ Can reload event in new Godot session
- ✅ No data loss during save/load cycle

**Manual Verification:**
1. Create AudioEvent in editor
2. Set all properties
3. Save as `test_event.tres`
4. Close Godot
5. Reopen Godot
6. Load `test_event.tres`
7. Verify all properties are intact

---

### 1.2 LayeredAudioEvent Resource

**File:** `addons/audio_mixer/scripts/layered_audio_event.gd`

#### Test Case 1.2.1: Create Layered Event
```gdscript
func test_create_layered_event():
    var event = LayeredAudioEvent.new()
    event.event_name = "EngineSound"
    event.control_parameter = "engine_rpm"

    assert(event != null, "Should create layered event")
    assert(event.control_parameter == "engine_rpm", "Parameter should be set")
    assert(event.layers.size() == 0, "Should start with no layers")

    print("✅ Test 1.2.1 PASSED: Create layered event")
```

**Success Criteria:**
- ✅ Can instantiate LayeredAudioEvent
- ✅ Has `control_parameter` property (string)
- ✅ Has `layers` array property
- ✅ Has `crossfade_time` property (float)
- ✅ Extends Resource for saving

---

#### Test Case 1.2.2: Layer Management
```gdscript
func test_layer_management():
    var event = LayeredAudioEvent.new()

    # Create layer
    var layer1 = LayeredAudioEvent.AudioLayer.new()
    layer1.layer_name = "Idle"
    layer1.parameter_range = Vector2(0.0, 0.3)
    layer1.streams = [load("res://test_audio/idle.wav")]

    var layer2 = LayeredAudioEvent.AudioLayer.new()
    layer2.layer_name = "High"
    layer2.parameter_range = Vector2(0.7, 1.0)
    layer2.streams = [load("res://test_audio/high.wav")]

    event.layers = [layer1, layer2]

    assert(event.layers.size() == 2, "Should have 2 layers")
    assert(event.layers[0].layer_name == "Idle", "First layer name should match")
    assert(event.layers[1].layer_name == "High", "Second layer name should match")
    assert(event.layers[0].parameter_range == Vector2(0.0, 0.3), "Range should match")

    print("✅ Test 1.2.2 PASSED: Layer management")
```

**Success Criteria:**
- ✅ Can create AudioLayer objects
- ✅ Layers have `layer_name`, `streams`, `parameter_range`
- ✅ Can add multiple layers to event
- ✅ Layers can be accessed by index
- ✅ Each layer has independent settings

---

#### Test Case 1.2.3: Parameter Range Logic
```gdscript
func test_parameter_ranges():
    var layer1 = LayeredAudioEvent.AudioLayer.new()
    layer1.parameter_range = Vector2(0.0, 0.3)

    var layer2 = LayeredAudioEvent.AudioLayer.new()
    layer2.parameter_range = Vector2(0.2, 0.7)

    var layer3 = LayeredAudioEvent.AudioLayer.new()
    layer3.parameter_range = Vector2(0.6, 1.0)

    # Test if parameter value is in range
    # Layer 1: 0.0 to 0.3
    assert(is_in_range(0.15, layer1.parameter_range), "0.15 should be in layer 1 range")
    assert(not is_in_range(0.5, layer1.parameter_range), "0.5 should not be in layer 1 range")

    # Layer 2: 0.2 to 0.7 (overlaps with layer 1)
    assert(is_in_range(0.25, layer2.parameter_range), "0.25 should be in layer 2 range")
    assert(is_in_range(0.5, layer2.parameter_range), "0.5 should be in layer 2 range")

    print("✅ Test 1.2.3 PASSED: Parameter ranges")

func is_in_range(value: float, range: Vector2) -> bool:
    return value >= range.x and value <= range.y
```

**Success Criteria:**
- ✅ Parameter ranges correctly define active zones
- ✅ Can have overlapping ranges (for crossfading)
- ✅ Can have gaps between ranges
- ✅ Ranges are validated (min <= max)
- ✅ Parameter value comparison works correctly

---

#### Test Case 1.2.4: Crossfade Calculation
```gdscript
func test_crossfade_calculation():
    var event = LayeredAudioEvent.new()
    event.crossfade_time = 0.3  # 300ms

    var layer1 = LayeredAudioEvent.AudioLayer.new()
    layer1.parameter_range = Vector2(0.0, 0.5)

    var layer2 = LayeredAudioEvent.AudioLayer.new()
    layer2.parameter_range = Vector2(0.4, 1.0)  # 0.4-0.5 overlap

    event.layers = [layer1, layer2]

    # At parameter value 0.2: only layer1 active
    var volumes_at_02 = calculate_layer_volumes(event, 0.2)
    assert(volumes_at_02[0] > 0.9, "Layer 1 should be at full volume at 0.2")
    assert(volumes_at_02[1] < 0.1, "Layer 2 should be silent at 0.2")

    # At parameter value 0.45: both layers active (crossfade zone)
    var volumes_at_045 = calculate_layer_volumes(event, 0.45)
    assert(volumes_at_045[0] > 0.0, "Layer 1 should be audible at 0.45")
    assert(volumes_at_045[1] > 0.0, "Layer 2 should be audible at 0.45")
    assert(abs(volumes_at_045[0] + volumes_at_045[1] - 1.0) < 0.1, "Volumes should sum to ~1.0")

    # At parameter value 0.8: only layer2 active
    var volumes_at_08 = calculate_layer_volumes(event, 0.8)
    assert(volumes_at_08[0] < 0.1, "Layer 1 should be silent at 0.8")
    assert(volumes_at_08[1] > 0.9, "Layer 2 should be at full volume at 0.8")

    print("✅ Test 1.2.4 PASSED: Crossfade calculation")

func calculate_layer_volumes(event: LayeredAudioEvent, param_value: float) -> Array:
    var volumes = []
    for layer in event.layers:
        var volume = 0.0
        var range = layer.parameter_range

        if param_value >= range.x and param_value <= range.y:
            # Calculate crossfade position in range
            var range_size = range.y - range.x
            var position_in_range = (param_value - range.x) / range_size

            # Simple linear fade (0.0 to 1.0 to 0.0)
            if position_in_range < 0.5:
                volume = position_in_range * 2.0
            else:
                volume = (1.0 - position_in_range) * 2.0

            volume = clamp(volume, 0.0, 1.0)

        volumes.append(volume)

    return volumes
```

**Success Criteria:**
- ✅ Crossfade happens in overlapping parameter ranges
- ✅ Volume sum equals ~1.0 in crossfade zones
- ✅ Smooth transitions (no pops or clicks)
- ✅ `crossfade_time` controls transition speed
- ✅ Can have equal-power or linear crossfade curves

---

#### Test Case 1.2.5: Pitch Follows Parameter
```gdscript
func test_pitch_follows_parameter():
    var event = LayeredAudioEvent.new()
    event.pitch_follows_parameter = true
    event.pitch_parameter_scale = 0.5  # 50% pitch range

    # At parameter 0.0: pitch should be lower
    # At parameter 0.5: pitch should be normal (1.0)
    # At parameter 1.0: pitch should be higher

    var pitch_at_0 = calculate_pitch_from_param(event, 0.0)
    var pitch_at_05 = calculate_pitch_from_param(event, 0.5)
    var pitch_at_1 = calculate_pitch_from_param(event, 1.0)

    assert(pitch_at_0 < 1.0, "Pitch at 0.0 should be less than 1.0")
    assert(abs(pitch_at_05 - 1.0) < 0.01, "Pitch at 0.5 should be ~1.0")
    assert(pitch_at_1 > 1.0, "Pitch at 1.0 should be greater than 1.0")

    print("✅ Test 1.2.5 PASSED: Pitch follows parameter")

func calculate_pitch_from_param(event: LayeredAudioEvent, param_value: float) -> float:
    if not event.pitch_follows_parameter:
        return 1.0

    # Map parameter 0.0-1.0 to pitch range
    var scale = event.pitch_parameter_scale
    return 1.0 + (param_value - 0.5) * scale
```

**Success Criteria:**
- ✅ `pitch_follows_parameter` boolean enables/disables feature
- ✅ `pitch_parameter_scale` controls pitch variation amount
- ✅ Parameter 0.5 maps to pitch 1.0 (normal)
- ✅ Parameter 0.0 maps to lower pitch
- ✅ Parameter 1.0 maps to higher pitch
- ✅ Pitch changes are smooth (no discontinuities)

---

### 1.3 MusicEvent Resource

**File:** `addons/audio_mixer/scripts/music_event.gd`

#### Test Case 1.3.1: Create Music Event
```gdscript
func test_create_music_event():
    var music = MusicEvent.new()
    music.music_name = "CombatTheme"
    music.bpm = 140.0
    music.beats_per_bar = 4
    music.loop = true

    assert(music != null, "Should create music event")
    assert(music.bpm == 140.0, "BPM should be set")
    assert(music.beats_per_bar == 4, "Time signature should be 4/4")
    assert(music.loop == true, "Should be set to loop")
    assert(music.stems.size() == 0, "Should start with no stems")

    print("✅ Test 1.3.1 PASSED: Create music event")
```

**Success Criteria:**
- ✅ Can instantiate MusicEvent
- ✅ Has `music_name`, `bpm`, `beats_per_bar` properties
- ✅ Has `stems` array property
- ✅ Has `loop` boolean
- ✅ BPM range is validated (20-300)

---

#### Test Case 1.3.2: Stem Management
```gdscript
func test_stem_management():
    var music = MusicEvent.new()

    var drums = MusicEvent.MusicStem.new()
    drums.stem_name = "Drums"
    drums.stream = load("res://test_audio/drums.wav")
    drums.default_enabled = true
    drums.volume_offset = 0.0

    var bass = MusicEvent.MusicStem.new()
    bass.stem_name = "Bass"
    bass.stream = load("res://test_audio/bass.wav")
    bass.default_enabled = true
    bass.volume_offset = -3.0

    var intensity = MusicEvent.MusicStem.new()
    intensity.stem_name = "Intensity"
    intensity.stream = load("res://test_audio/intensity.wav")
    intensity.default_enabled = false  # Starts muted
    intensity.control_parameter = "combat_intensity"

    music.stems = [drums, bass, intensity]

    assert(music.stems.size() == 3, "Should have 3 stems")
    assert(music.stems[0].stem_name == "Drums", "First stem should be Drums")
    assert(music.stems[2].control_parameter == "combat_intensity", "Parameter should be set")

    print("✅ Test 1.3.2 PASSED: Stem management")
```

**Success Criteria:**
- ✅ Can create MusicStem objects
- ✅ Stems have `stem_name`, `stream`, `default_enabled`
- ✅ Stems have `volume_offset` (-60 to +6 dB)
- ✅ Stems can have `control_parameter` for dynamic behavior
- ✅ Can add multiple stems to music event

---

#### Test Case 1.3.3: BPM Timing Calculations
```gdscript
func test_bpm_timing():
    var music = MusicEvent.new()
    music.bpm = 120.0  # 120 BPM = 2 beats per second
    music.beats_per_bar = 4

    # Calculate beat duration
    var beat_duration = 60.0 / music.bpm  # seconds per beat
    assert(abs(beat_duration - 0.5) < 0.01, "Beat duration should be 0.5s at 120 BPM")

    # Calculate bar duration
    var bar_duration = beat_duration * music.beats_per_bar
    assert(abs(bar_duration - 2.0) < 0.01, "Bar duration should be 2.0s")

    # At 140 BPM
    music.bpm = 140.0
    beat_duration = 60.0 / music.bpm
    assert(abs(beat_duration - 0.4286) < 0.01, "Beat duration should be ~0.429s at 140 BPM")

    print("✅ Test 1.3.3 PASSED: BPM timing calculations")
```

**Success Criteria:**
- ✅ BPM correctly converts to beat duration (60.0 / BPM)
- ✅ Bar duration = beat_duration × beats_per_bar
- ✅ Calculations work for various BPM values (60-200)
- ✅ Time signature changes affect bar duration
- ✅ Timing is accurate (< 1ms error)

---

#### Test Case 1.3.4: Loop Points and Markers
```gdscript
func test_loop_points_and_markers():
    var music = MusicEvent.new()
    music.loop = true
    music.loop_start_time = 4.0  # Start loop at 4 seconds
    music.loop_end_time = 20.0   # End loop at 20 seconds

    assert(music.loop_start_time == 4.0, "Loop start should be set")
    assert(music.loop_end_time == 20.0, "Loop end should be set")

    # Add markers
    var marker1 = MusicEvent.MusicMarker.new()
    marker1.name = "Intro"
    marker1.time = 0.0

    var marker2 = MusicEvent.MusicMarker.new()
    marker2.name = "LoopStart"
    marker2.time = 4.0

    var marker3 = MusicEvent.MusicMarker.new()
    marker3.name = "Climax"
    marker3.time = 16.0

    music.markers = [marker1, marker2, marker3]

    assert(music.markers.size() == 3, "Should have 3 markers")
    assert(music.markers[0].name == "Intro", "First marker should be Intro")
    assert(music.markers[1].time == 4.0, "Loop start marker at 4.0s")

    print("✅ Test 1.3.4 PASSED: Loop points and markers")
```

**Success Criteria:**
- ✅ Can set loop_start_time and loop_end_time
- ✅ Loop points define custom loop region (not full track)
- ✅ Can create MusicMarker objects with name and time
- ✅ Markers can be added to music event
- ✅ Markers are sorted by time automatically

---

#### Test Case 1.3.5: Parameter-Controlled Stems
```gdscript
func test_parameter_controlled_stems():
    var music = MusicEvent.new()

    var intensity_stem = MusicEvent.MusicStem.new()
    intensity_stem.stem_name = "Intensity"
    intensity_stem.control_parameter = "combat_intensity"
    intensity_stem.parameter_range = Vector2(0.5, 1.0)  # Active when > 0.5
    intensity_stem.default_enabled = false

    music.stems = [intensity_stem]

    # Test if stem should be enabled based on parameter value
    var param_value = 0.3  # Below threshold
    var should_enable = param_value >= intensity_stem.parameter_range.x
    assert(not should_enable, "Stem should be disabled at 0.3")

    param_value = 0.7  # Above threshold
    should_enable = param_value >= intensity_stem.parameter_range.x
    assert(should_enable, "Stem should be enabled at 0.7")

    print("✅ Test 1.3.5 PASSED: Parameter-controlled stems")
```

**Success Criteria:**
- ✅ Stems can have optional `control_parameter`
- ✅ Stems have `parameter_range` for activation threshold
- ✅ Stem enables/disables based on parameter value
- ✅ Transitions are smooth (fade in/out)
- ✅ Multiple stems can respond to same parameter

---

### 1.4 AudioSnapshot Resource

**File:** `addons/audio_mixer/scripts/audio_snapshot.gd`

#### Test Case 1.4.1: Create Snapshot
```gdscript
func test_create_snapshot():
    var snapshot = AudioSnapshot.new()
    snapshot.snapshot_name = "Underwater"
    snapshot.transition_time = 1.5

    assert(snapshot != null, "Should create snapshot")
    assert(snapshot.snapshot_name == "Underwater", "Name should be set")
    assert(snapshot.transition_time == 1.5, "Transition time should be set")
    assert(snapshot.bus_states.size() == 0, "Should start with no bus states")

    print("✅ Test 1.4.1 PASSED: Create snapshot")
```

**Success Criteria:**
- ✅ Can instantiate AudioSnapshot
- ✅ Has `snapshot_name` property
- ✅ Has `transition_time` property (0-10 seconds)
- ✅ Has `bus_states` array
- ✅ Extends Resource

---

#### Test Case 1.4.2: Bus State Management
```gdscript
func test_bus_states():
    var snapshot = AudioSnapshot.new()

    var master_state = AudioSnapshot.BusState.new()
    master_state.bus_name = "Master"
    master_state.volume_db = -6.0
    master_state.enable_lowpass = true
    master_state.lowpass_cutoff = 500.0

    var music_state = AudioSnapshot.BusState.new()
    music_state.bus_name = "Music"
    music_state.volume_db = -12.0
    music_state.enable_lowpass = false

    snapshot.bus_states = [master_state, music_state]

    assert(snapshot.bus_states.size() == 2, "Should have 2 bus states")
    assert(snapshot.bus_states[0].bus_name == "Master", "First bus should be Master")
    assert(snapshot.bus_states[0].volume_db == -6.0, "Volume should be -6dB")
    assert(snapshot.bus_states[0].enable_lowpass == true, "Lowpass should be enabled")
    assert(snapshot.bus_states[0].lowpass_cutoff == 500.0, "Cutoff should be 500Hz")

    print("✅ Test 1.4.2 PASSED: Bus state management")
```

**Success Criteria:**
- ✅ Can create BusState objects
- ✅ BusState has `bus_name`, `volume_db`
- ✅ BusState has `enable_lowpass`, `lowpass_cutoff`
- ✅ Can add multiple bus states to snapshot
- ✅ Each bus state is independent

---

#### Test Case 1.4.3: Capture Current Mixer State
```gdscript
func test_capture_mixer_state():
    var snapshot = AudioSnapshot.new()

    # Set some bus values
    var master_idx = AudioServer.get_bus_index("Master")
    var sfx_idx = AudioServer.get_bus_index("SFX")

    AudioServer.set_bus_volume_db(master_idx, -3.0)
    AudioServer.set_bus_volume_db(sfx_idx, -6.0)

    # Capture current state
    snapshot.capture_current_mixer_state()

    assert(snapshot.bus_states.size() > 0, "Should have captured bus states")

    # Find Master bus state
    var master_state = null
    for state in snapshot.bus_states:
        if state.bus_name == "Master":
            master_state = state
            break

    assert(master_state != null, "Should have captured Master bus")
    assert(abs(master_state.volume_db - (-3.0)) < 0.1, "Volume should match current state")

    print("✅ Test 1.4.3 PASSED: Capture mixer state")
```

**Success Criteria:**
- ✅ `capture_current_mixer_state()` reads all bus volumes
- ✅ Captures effect states (if effects present)
- ✅ Captured state matches AudioServer current state
- ✅ Works for all buses in the mixer
- ✅ Non-destructive (doesn't change current audio)

---

### 1.5 AudioParameter Resource

**File:** `addons/audio_mixer/scripts/audio_parameter.gd`

#### Test Case 1.5.1: Create Parameter
```gdscript
func test_create_parameter():
    var param = AudioParameter.new()
    param.parameter_name = "engine_rpm"
    param.min_value = 0.0
    param.max_value = 1.0
    param.default_value = 0.0
    param.current_value = 0.0

    assert(param != null, "Should create parameter")
    assert(param.parameter_name == "engine_rpm", "Name should be set")
    assert(param.min_value == 0.0, "Min should be 0.0")
    assert(param.max_value == 1.0, "Max should be 1.0")
    assert(param.current_value == 0.0, "Current should be 0.0")

    print("✅ Test 1.5.1 PASSED: Create parameter")
```

**Success Criteria:**
- ✅ Can instantiate AudioParameter
- ✅ Has `parameter_name`, `min_value`, `max_value`
- ✅ Has `default_value`, `current_value`
- ✅ Has `interpolation_speed` for smoothing
- ✅ Extends Resource

---

#### Test Case 1.5.2: Value Clamping
```gdscript
func test_value_clamping():
    var param = AudioParameter.new()
    param.min_value = 0.0
    param.max_value = 1.0

    # Set value within range
    param.set_value(0.5)
    assert(param.current_value == 0.5, "Should accept value in range")

    # Set value above max
    param.set_value(1.5)
    assert(param.current_value == 1.0, "Should clamp to max")

    # Set value below min
    param.set_value(-0.5)
    assert(param.current_value == 0.0, "Should clamp to min")

    print("✅ Test 1.5.2 PASSED: Value clamping")
```

**Success Criteria:**
- ✅ `set_value()` clamps to min/max range
- ✅ Values above max are clamped to max
- ✅ Values below min are clamped to min
- ✅ Valid values are accepted unchanged
- ✅ No errors or warnings on invalid values

---

#### Test Case 1.5.3: Parameter Interpolation
```gdscript
func test_parameter_interpolation():
    var param = AudioParameter.new()
    param.min_value = 0.0
    param.max_value = 1.0
    param.current_value = 0.0
    param.target_value = 1.0
    param.interpolation_speed = 2.0  # 2 units per second

    # Simulate 0.25 seconds passing
    var delta = 0.25
    param.update(delta)

    # Should have moved 2.0 * 0.25 = 0.5 units
    assert(abs(param.current_value - 0.5) < 0.01, "Should interpolate to 0.5")

    # Simulate another 0.25 seconds
    param.update(delta)

    # Should have reached target (1.0)
    assert(abs(param.current_value - 1.0) < 0.01, "Should reach target")

    print("✅ Test 1.5.3 PASSED: Parameter interpolation")
```

**Success Criteria:**
- ✅ `interpolation_speed` controls transition rate
- ✅ `update(delta)` smoothly moves current toward target
- ✅ Interpolation respects delta time
- ✅ Reaches target value eventually
- ✅ No overshoot past target

---

## 🎮 Phase 2: Runtime Systems

### 2.1 AudioPool System

**File:** `addons/audio_mixer/scripts/audio_pool.gd`

#### Test Case 2.1.1: Create Pool
```gdscript
func test_create_pool():
    var pool_2d = AudioPool.new(AudioPool.PoolType.POOL_2D, 10)

    assert(pool_2d != null, "Should create 2D pool")
    assert(pool_2d.pool_size == 10, "Should have 10 players")
    assert(pool_2d.available_count() == 10, "All players should be available")
    assert(pool_2d.active_count() == 0, "No players should be active")

    print("✅ Test 2.1.1 PASSED: Create pool")
```

**Success Criteria:**
- ✅ Can create pool with specified size
- ✅ Can create 2D or 3D pool
- ✅ Pool pre-allocates AudioStreamPlayer nodes
- ✅ All players start in available state
- ✅ `available_count()` returns correct count

**Manual Verification:**
1. Run game
2. Check scene tree
3. Verify AudioStreamPlayer nodes exist
4. Verify they're children of AudioController

---

#### Test Case 2.1.2: Acquire and Release Players
```gdscript
func test_acquire_release():
    var pool = AudioPool.new(AudioPool.PoolType.POOL_2D, 5)

    # Acquire player
    var player1 = pool.acquire()
    assert(player1 != null, "Should acquire player")
    assert(pool.available_count() == 4, "Should have 4 available")
    assert(pool.active_count() == 1, "Should have 1 active")

    # Acquire more
    var player2 = pool.acquire()
    var player3 = pool.acquire()
    assert(pool.available_count() == 2, "Should have 2 available")
    assert(pool.active_count() == 3, "Should have 3 active")

    # Release player
    pool.release(player1)
    assert(pool.available_count() == 3, "Should have 3 available")
    assert(pool.active_count() == 2, "Should have 2 active")

    print("✅ Test 2.1.2 PASSED: Acquire and release")
```

**Success Criteria:**
- ✅ `acquire()` returns available player
- ✅ `acquire()` marks player as active
- ✅ `release(player)` returns player to available pool
- ✅ Counts update correctly
- ✅ Released player can be acquired again

---

#### Test Case 2.1.3: Pool Exhaustion and Expansion
```gdscript
func test_pool_expansion():
    var pool = AudioPool.new(AudioPool.PoolType.POOL_2D, 3)
    pool.max_size = 10
    pool.auto_expand = true

    # Acquire all players
    var player1 = pool.acquire()
    var player2 = pool.acquire()
    var player3 = pool.acquire()
    assert(pool.available_count() == 0, "Pool should be exhausted")

    # Try to acquire when exhausted (should expand)
    var player4 = pool.acquire()
    assert(player4 != null, "Should expand pool and return player")
    assert(pool.pool_size == 4, "Pool should have expanded to 4")

    # Verify max size limit
    for i in range(10):
        pool.acquire()

    assert(pool.pool_size <= 10, "Pool should not exceed max size")

    print("✅ Test 2.1.3 PASSED: Pool expansion")
```

**Success Criteria:**
- ✅ Pool expands when exhausted (if auto_expand enabled)
- ✅ Respects max_size limit
- ✅ Returns null if exhausted and can't expand
- ✅ Expansion creates new AudioStreamPlayer nodes
- ✅ Expansion is logged for debugging

---

## 📝 Complete Test Coverage Document

Due to length constraints, I'm creating a comprehensive testing guide. Would you like me to:

1. **Continue with remaining phases** (Phase 3-7 with detailed test cases)?
2. **Create a separate test automation framework** (actual GDScript test runner)?
3. **Focus on specific high-priority features** (like drag-and-drop testing)?
4. **Create integration test scenarios** (end-to-end workflows)?

This testing guide now includes:
- ✅ Detailed test cases for Phase 1 (Core Resources)
- ✅ Success criteria for each test
- ✅ Manual verification steps
- ✅ Example test code you can run
- ✅ Started Phase 2 (Runtime Systems)

Should I continue with the rest of the phases, or would you like me to focus on a different aspect?
