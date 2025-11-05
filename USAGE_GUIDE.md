# Audio Mixer - Complete Usage Guide

## Table of Contents

1. [Getting Started](#getting-started)
2. [Basic Audio Playback](#basic-audio-playback)
3. [Interactive Parameters](#interactive-parameters)
4. [Layered Audio](#layered-audio)
5. [Adaptive Music](#adaptive-music)
6. [BPM Synchronization](#bpm-synchronization)
7. [Mixer Snapshots](#mixer-snapshots)
8. [Advanced Techniques](#advanced-techniques)
9. [Common Game Scenarios](#common-game-scenarios)

---

## Getting Started

### Setup

1. Enable the plugin in Project Settings > Plugins
2. Verify AudioController and MusicManager are in Project Settings > Autoload
3. Open the "Audio Mixer" tab in the editor
4. Create your first audio event

### Basic Concepts

- **AudioEvent**: A reusable sound definition with variations and randomization
- **Parameter**: A value that controls audio behavior in real-time
- **Layer**: A component of a layered event that crossfades based on parameters
- **Stem**: An individual track in adaptive music
- **Snapshot**: A saved mixer state with smooth transitions

---

## Basic Audio Playback

### Simple One-Shot Sound

```gdscript
extends CharacterBody3D

var footstep_event: AudioEvent  # Assigned in editor

func _physics_process(delta):
    if is_on_floor() and velocity.length() > 0.1:
        if not $FootstepTimer.is_stopped():
            return

        # Play footstep at player position
        AudioController.play_event(footstep_event, global_position)
        $FootstepTimer.start(0.4)  # Cooldown between steps
```

### Looping Ambient Sound

```gdscript
extends Node3D

var waterfall_event: AudioEvent  # Looping=true in the event

func _ready():
    # Play looping waterfall sound at this position
    AudioController.play_event(waterfall_event, global_position)

    # To stop: use stop_layered_event or remove the node
```

### Random Variations

Create an AudioEvent with multiple streams:
- `playback_mode = RANDOM_ONE`: Pick random variation each time
- `volume_range = Vector2(-3, 0)`: Randomize volume ±3dB
- `pitch_range = Vector2(0.9, 1.1)`: Randomize pitch ±10%

This prevents repetitive audio!

---

## Interactive Parameters

### Creating Parameters

```gdscript
# In your game's initialization
func _ready():
    # Health parameter (0.0 = dead, 1.0 = full health)
    AudioController.create_parameter("player_health", 0.0, 1.0, 1.0)

    # Speed parameter
    AudioController.create_parameter("movement_speed", 0.0, 20.0, 0.0)

    # Distance parameter
    AudioController.create_parameter("enemy_distance", 0.0, 100.0, 100.0)
```

### Updating Parameters

```gdscript
extends CharacterBody3D

func _process(delta):
    # Update parameters based on game state
    var health_normalized = health / max_health
    AudioController.set_parameter_smooth("player_health", health_normalized)

    # Instant update (no smoothing)
    AudioController.set_parameter("movement_speed", velocity.length())
```

### Parameter-Driven Effects

Parameters can control:
- Layer volumes in LayeredAudioEvents
- Stem volumes in MusicEvents
- Custom game logic (read parameter values)

---

## Layered Audio

### Use Cases
- Vehicle engines (RPM-based layers)
- Dynamic ambiences (weather, crowd density)
- Weapon charge-up sounds
- Player state sounds (breathing, heartbeat)

### Example: Vehicle Engine

```gdscript
extends VehicleBody3D

var engine_event: LayeredAudioEvent
var is_engine_playing = false

func _ready():
    # Create engine event with 3 layers
    engine_event = LayeredAudioEvent.new()
    engine_event.event_name = "VehicleEngine"
    engine_event.control_parameter = "engine_rpm"
    engine_event.crossfade_time = 0.3
    engine_event.pitch_follows_parameter = true
    engine_event.pitch_parameter_scale = 0.8

    # Idle layer (0-3000 RPM → 0.0-0.3 normalized)
    var idle = LayeredAudioEvent.AudioLayer.new()
    idle.layer_name = "Idle"
    idle.streams = [preload("res://audio/engine_idle_loop.wav")]
    idle.parameter_range = Vector2(0.0, 0.3)
    idle.looping = true

    # Mid layer (2000-7000 RPM → 0.2-0.7 normalized)
    var mid = LayeredAudioEvent.AudioLayer.new()
    mid.layer_name = "Mid"
    mid.streams = [preload("res://audio/engine_mid_loop.wav")]
    mid.parameter_range = Vector2(0.2, 0.7)
    mid.looping = true

    # High layer (6000-10000 RPM → 0.6-1.0 normalized)
    var high = LayeredAudioEvent.AudioLayer.new()
    high.layer_name = "High"
    high.streams = [preload("res://audio/engine_high_loop.wav")]
    high.parameter_range = Vector2(0.6, 1.0)
    mid.looping = true

    engine_event.layers = [idle, mid, high]

    # Create parameter
    AudioController.create_parameter("engine_rpm", 0.0, 1.0, 0.0)

func start_engine():
    if not is_engine_playing:
        AudioController.play_layered_event(engine_event, global_position)
        is_engine_playing = true

func stop_engine():
    if is_engine_playing:
        AudioController.stop_layered_event(engine_event, 0.5)
        is_engine_playing = false

func _physics_process(delta):
    if is_engine_playing:
        # Get current RPM from physics
        var rpm = engine_force * 10.0  # Example calculation
        var rpm_normalized = clamp(rpm / 10000.0, 0.0, 1.0)

        # Update parameter
        AudioController.set_parameter_smooth("engine_rpm", rpm_normalized)
```

### Example: Dynamic Weather

```gdscript
extends Node

var weather_ambient: LayeredAudioEvent

func _ready():
    weather_ambient = LayeredAudioEvent.new()
    weather_ambient.control_parameter = "weather_intensity"

    # Layers for different weather elements
    var wind = LayeredAudioEvent.AudioLayer.new()
    wind.control_parameter = "wind_strength"
    wind.parameter_range = Vector2(0.2, 1.0)
    wind.streams = [preload("res://audio/wind_loop.wav")]

    var rain = LayeredAudioEvent.AudioLayer.new()
    rain.control_parameter = "rain_amount"
    rain.parameter_range = Vector2(0.1, 1.0)
    rain.streams = [preload("res://audio/rain_loop.wav")]

    weather_ambient.layers = [wind, rain]

    # Create parameters
    AudioController.create_parameter("wind_strength", 0.0, 1.0, 0.0)
    AudioController.create_parameter("rain_amount", 0.0, 1.0, 0.0)

    # Start ambient
    AudioController.play_layered_event(weather_ambient)

func set_weather(wind: float, rain: float):
    AudioController.set_parameter_smooth("wind_strength", wind)
    AudioController.set_parameter_smooth("rain_amount", rain)
```

---

## Adaptive Music

### Basic Music Playback

```gdscript
var menu_music: MusicEvent  # Assigned in editor

func _ready():
    MusicManager.play_music(menu_music, 2.0)  # 2s fade in

func _exit_tree():
    MusicManager.stop_music(1.0)  # 1s fade out
```

### Music with Stems

```gdscript
extends Node

var gameplay_music: MusicEvent

func _ready():
    # Create music with intensity layers
    gameplay_music = MusicEvent.new()
    gameplay_music.music_name = "GameplayMusic"
    gameplay_music.bpm = 120.0
    gameplay_music.beats_per_bar = 4
    gameplay_music.loop = true

    # Base layer - always playing
    var base = MusicEvent.MusicStem.new()
    base.stem_name = "Base"
    base.stream = preload("res://music/gameplay_base.wav")
    base.default_enabled = true

    # Drums - enabled during action
    var drums = MusicEvent.MusicStem.new()
    drums.stem_name = "Drums"
    drums.stream = preload("res://music/gameplay_drums.wav")
    drums.default_enabled = false

    # Intensity - enabled during combat
    var intensity = MusicEvent.MusicStem.new()
    intensity.stem_name = "Intensity"
    intensity.stream = preload("res://music/gameplay_intensity.wav")
    intensity.control_parameter = "game_intensity"
    intensity.parameter_range = Vector2(0.5, 1.0)  # Active when intensity > 50%

    gameplay_music.stems = [base, drums, intensity]

    # Create parameter
    AudioController.create_parameter("game_intensity", 0.0, 1.0, 0.0)

    # Start music
    MusicManager.play_music(gameplay_music, 2.0)

func on_combat_started():
    # Enable drums immediately
    MusicManager.set_stem_enabled("Drums", true, 1.0)

    # Ramp up intensity
    AudioController.set_parameter_smooth("game_intensity", 1.0)

func on_combat_ended():
    # Disable drums
    MusicManager.set_stem_enabled("Drums", false, 2.0)

    # Lower intensity
    AudioController.set_parameter_smooth("game_intensity", 0.0)
```

### Music Transitions

```gdscript
func transition_to_boss_music():
    # Transition types:
    # 0 = Immediate
    # 1 = End of Bar (default)
    # 2 = End of Section
    # 3 = Crossfade

    MusicManager.transition_to(
        boss_music_event,
        1,    # End of bar
        2.0   # 2 second transition
    )
```

---

## BPM Synchronization

### Setting Up BPM Clock

```gdscript
func _ready():
    # Set BPM
    AudioController.global_bpm = 120.0
    AudioController.time_signature = 4

    # Start clock
    AudioController.start_bpm_clock()

    # Connect to signals
    AudioController.beat.connect(_on_beat)
    AudioController.bar.connect(_on_bar)

func _on_beat(beat_number: int):
    print("Beat: ", beat_number)  # 0, 1, 2, 3, 0, 1, ...

func _on_bar(bar_number: int):
    print("Bar: ", bar_number)  # 0, 1, 2, 3, ...
```

### Quantized Playback

```gdscript
# Play on next beat
AudioController.play_event_quantized(snare_event)

# Play on next bar
AudioController.play_event_quantized(section_change_event, true)
```

### Rhythm Game Example

```gdscript
extends Node2D

var song_bpm = 140.0
var perfect_window = 0.1  # ±10% of beat
var good_window = 0.3     # ±30% of beat

func _ready():
    AudioController.global_bpm = song_bpm
    AudioController.time_signature = 4
    AudioController.start_bpm_clock()
    AudioController.beat.connect(_on_beat)

    MusicManager.play_music(song_music)

func _on_beat(beat_num: int):
    # Spawn note target
    spawn_note()

    # Visual beat indicator
    beat_indicator.flash()

func _input(event):
    if event.is_action_pressed("hit_note"):
        var phase = AudioController.get_beat_phase()

        # Check timing (phase wraps, so check both ends)
        var timing_error = min(phase, 1.0 - phase)

        if timing_error < perfect_window:
            score += 100
            AudioController.play_event(perfect_hit_sfx)
            show_rating("PERFECT!")
        elif timing_error < good_window:
            score += 50
            AudioController.play_event(good_hit_sfx)
            show_rating("Good")
        else:
            AudioController.play_event(miss_sfx)
            show_rating("Miss")
```

### Synced Visual Effects

```gdscript
extends Node3D

var light_intensity_curve: Curve  # Editor-assigned

func _process(_delta):
    # Pulse light with beat
    var beat_phase = AudioController.get_beat_phase()
    var intensity = light_intensity_curve.sample(beat_phase)
    $OmniLight3D.light_energy = intensity

    # Flash on downbeat
    if AudioController.get_current_beat() == 0:
        if AudioController.get_beat_phase() < 0.05:
            $OmniLight3D.light_color = Color.RED
        else:
            $OmniLight3D.light_color = Color.WHITE
```

---

## Mixer Snapshots

### Use Cases
- Underwater/muffled audio
- Pause menu (duck game audio)
- Cinematic moments (boost music, reduce SFX)
- Dynamic mix changes (inside/outside buildings)

### Example: Underwater Effect

```gdscript
extends Area3D  # Water volume

var underwater_snapshot: AudioSnapshot

func _ready():
    # Create underwater snapshot
    underwater_snapshot = AudioSnapshot.new()
    underwater_snapshot.snapshot_name = "Underwater"
    underwater_snapshot.transition_time = 0.8

    # Muffle master bus
    var master = AudioSnapshot.BusState.new()
    master.bus_name = "Master"
    master.enable_lowpass = true
    master.lowpass_cutoff = 500.0
    master.volume_db = -6.0

    # Duck music
    var music = AudioSnapshot.BusState.new()
    music.bus_name = "Music"
    music.volume_db = -12.0

    underwater_snapshot.bus_states = [master, music]

    # Register
    AudioController.register_snapshot(underwater_snapshot)

    # Connect signals
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body):
    if body.name == "Player":
        AudioController.apply_snapshot("Underwater", 0.8)

func _on_body_exited(body):
    if body.name == "Player":
        # Return to default (capture default state first)
        var default_snapshot = AudioSnapshot.new()
        default_snapshot.snapshot_name = "Default"
        default_snapshot.capture_current_mixer_state()
        AudioController.register_snapshot(default_snapshot)
        AudioController.apply_snapshot("Default", 0.8)
```

### Example: Pause Menu Ducking

```gdscript
extends Control  # Pause menu

var pause_snapshot: AudioSnapshot

func _ready():
    # Create pause snapshot - duck everything except UI
    pause_snapshot = AudioSnapshot.new()
    pause_snapshot.snapshot_name = "Paused"
    pause_snapshot.transition_time = 0.3

    var master = AudioSnapshot.BusState.new()
    master.bus_name = "Master"
    master.volume_db = -20.0

    var ui = AudioSnapshot.BusState.new()
    ui.bus_name = "UI"
    ui.volume_db = 0.0

    pause_snapshot.bus_states = [master, ui]
    AudioController.register_snapshot(pause_snapshot)

func _on_pause_pressed():
    get_tree().paused = true
    AudioController.apply_snapshot("Paused", 0.3)
    show()

func _on_resume_pressed():
    get_tree().paused = false
    AudioController.apply_snapshot("Default", 0.3)
    hide()
```

---

## Advanced Techniques

### Voice Stealing

Enable for sounds that can be interrupted:

```gdscript
var bullet_impact_event = AudioEvent.new()
bullet_impact_event.enable_voice_stealing = true
bullet_impact_event.priority = AudioEvent.Priority.LOW
```

High priority sounds will steal voices from lower priority ones.

### Cooldowns

Prevent audio spam:

```gdscript
var jump_event = AudioEvent.new()
jump_event.cooldown_time = 0.3  # 300ms minimum between plays
```

### Delay and Fades

```gdscript
var delayed_explosion = AudioEvent.new()
delayed_explosion.delay = 0.5  # Wait 500ms before playing
delayed_explosion.fade_in_duration = 0.2
delayed_explosion.fade_out_duration = 1.0
```

---

## Common Game Scenarios

### FPS Game

```gdscript
# Weapon system
var weapon_fire_event: AudioEvent
var weapon_reload_event: AudioEvent
var footstep_event: LayeredAudioEvent  # Different surfaces

# Combat music with intensity
var combat_music: MusicEvent  # Stems: Base, Tension, Combat

func _ready():
    AudioController.create_parameter("combat_intensity", 0.0, 1.0, 0.0)
    AudioController.create_parameter("surface_type", 0.0, 3.0, 0.0)
    MusicManager.play_music(combat_music)

func fire_weapon():
    AudioController.play_event(weapon_fire_event, weapon_muzzle.global_position)

func on_enemy_nearby(distance: float):
    var intensity = 1.0 - (distance / 50.0)  # Max 50m
    AudioController.set_parameter_smooth("combat_intensity", intensity)
```

### Racing Game

```gdscript
# Engine with gear-based layering
var engine_event: LayeredAudioEvent
# Parameter: "gear_ratio" (0.0-1.0 per gear)

# Wind sound based on speed
var wind_event: LayeredAudioEvent
# Parameter: "speed" (0-200 km/h)

# Tire sounds based on surface
var tire_event: LayeredAudioEvent
# Parameter: "surface_type"

func _physics_process(delta):
    var speed_kmh = linear_velocity.length() * 3.6
    AudioController.set_parameter("speed", speed_kmh)

    var gear_ratio = (current_rpm - gear_min_rpm) / (gear_max_rpm - gear_min_rpm)
    AudioController.set_parameter("gear_ratio", gear_ratio)
```

### Stealth Game

```gdscript
# Music with 3 stems: Ambient, Suspense, Alert
var stealth_music: MusicEvent

# Footstep volume based on movement speed
var footstep_event: AudioEvent

func _ready():
    AudioController.create_parameter("alert_level", 0.0, 1.0, 0.0)
    MusicManager.play_music(stealth_music)

func update_stealth():
    if player_detected:
        AudioController.set_parameter_smooth("alert_level", 1.0)
    elif enemies_suspicious:
        AudioController.set_parameter_smooth("alert_level", 0.5)
    else:
        AudioController.set_parameter_smooth("alert_level", 0.0)
```

---

## Best Practices

1. **Organize Events**: Use the folder structure (sfx/, music/, ui/, ambient/)
2. **Name Consistently**: Use clear, descriptive names
3. **Test Early**: Use the editor's Test Playback button
4. **Profile Pool**: Monitor Stats tab for pool usage
5. **Compress Audio**: Use Ogg Vorbis for music and long loops
6. **Spatial Awareness**: Use 3D audio for positioned sounds
7. **Parameter Strategy**: Plan parameters before creating layered events
8. **BPM Matters**: Match BPM across all music stems
9. **Snapshot Library**: Create snapshots for common scenarios
10. **Documentation**: Comment complex audio setups

---

**Happy sound designing! 🎵**
