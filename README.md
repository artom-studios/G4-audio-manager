# Audio Mixer - FMOD-like Audio System for Godot 4

A comprehensive, professional-grade audio management system for Godot 4 that brings FMOD and Wwise-like features to GDScript. Built entirely with native Godot tools and pure GDScript.

## 📖 Documentation

- **[Sound Designer Guide](SOUND_DESIGNER_GUIDE.md)** - Complete no-code workflow for audio designers
- **[Usage Guide](USAGE_GUIDE.md)** - In-depth programming guide with examples
- **[API Reference](#api-reference)** - Complete API documentation (below)

## Features

### 🎵 Core Audio System
- **AudioEvent Resources**: Reusable sound definitions with randomization and variations
- **Layered Audio Events**: Multi-layer sounds with parameter-driven crossfading (perfect for car engines, ambiences)
- **Music Events**: Adaptive music with synchronized stems, transitions, and beat-quantized changes
- **Audio Snapshots**: Complete mixer state capture and smooth transitions

### 🎚️ Interactive Audio
- **Global Parameters**: Control audio behavior in real-time (volume, pitch, layer mixing, filters)
- **Parameter Smoothing**: Automatic interpolation for smooth transitions
- **Voice Stealing**: Priority-based system for managing concurrent sounds
- **Cooldown System**: Prevent sound spam with per-event cooldowns

### 🎼 Music System
- **Adaptive Music**: Dynamic stem mixing based on game state
- **BPM Synchronization**: Global clock with beat and bar callbacks
- **Musical Transitions**: Quantized transitions (immediate, end of bar, crossfade)
- **Loop Points & Markers**: Custom cue points and loop regions

### ⚡ Performance
- **Object Pooling**: Efficient 2D/3D audio player management
- **Auto-Expansion**: Dynamic pool growth with configurable limits
- **Instance Limiting**: Per-event max concurrent playback
- **Spatial Audio**: Full 3D audio support with attenuation models

### 🎨 Editor Integration
- **Custom Editor Tab**: Dedicated "Audio Mixer" tab in the Godot editor
- **Event Browser**: Tree view of all audio events with search
- **Inspector**: Edit event properties directly in the editor
- **Test Playback**: Instant preview of audio events
- **Parameter Editor**: Create and manage global parameters
- **BPM Controls**: Live BPM clock with visual feedback
- **Statistics Panel**: Real-time pool and performance stats

---

## Installation

1. Copy the `addons/audio_mixer` folder to your Godot project's `addons/` directory
2. Enable the plugin in **Project > Project Settings > Plugins**
3. The "Audio Mixer" tab will appear at the top of the editor
4. AudioController and MusicManager are automatically added as autoloads

---

## Quick Start Guide

### 1. Creating a Simple Audio Event

```gdscript
# Create in editor or via code
var footstep_event = AudioEvent.new()
footstep_event.event_name = "Footstep"
footstep_event.category = "SFX/Player"

# Add audio stream variations
footstep_event.streams = [
    preload("res://audio/footstep1.wav"),
    preload("res://audio/footstep2.wav"),
    preload("res://audio/footstep3.wav")
]

# Configure randomization
footstep_event.volume_range = Vector2(-3.0, 0.0)  # -3dB to 0dB variation
footstep_event.pitch_range = Vector2(0.9, 1.1)    # ±10% pitch variation
footstep_event.playback_mode = AudioEvent.PlaybackMode.RANDOM_ONE
footstep_event.bus_name = "SFX"
footstep_event.max_concurrent_instances = 5

# Save as .tres resource
ResourceSaver.save(footstep_event, "res://audio_events/sfx/footstep.tres")
```

### 2. Playing Audio Events

```gdscript
# Play a simple event
AudioController.play_event(footstep_event)

# Play at a 3D position
AudioController.play_event(explosion_event, Vector3(10, 0, 5))

# Play quantized to next beat
AudioController.play_event_quantized(drum_hit_event)

# Play quantized to next bar
AudioController.play_event_quantized(music_stinger, true)
```

### 3. Creating a Layered Event (Car Engine)

```gdscript
# Create a layered event
var engine_event = LayeredAudioEvent.new()
engine_event.event_name = "CarEngine"
engine_event.control_parameter = "engine_rpm"  # Parameter name

# Create layers
var idle_layer = LayeredAudioEvent.AudioLayer.new()
idle_layer.layer_name = "Idle"
idle_layer.streams = [preload("res://audio/engine_idle.wav")]
idle_layer.parameter_range = Vector2(0.0, 0.3)  # Active when RPM is 0-0.3
idle_layer.looping = true

var mid_layer = LayeredAudioEvent.AudioLayer.new()
mid_layer.layer_name = "Mid RPM"
mid_layer.streams = [preload("res://audio/engine_mid.wav")]
mid_layer.parameter_range = Vector2(0.2, 0.7)  # Active when RPM is 0.2-0.7
mid_layer.looping = true

var high_layer = LayeredAudioEvent.AudioLayer.new()
high_layer.layer_name = "High RPM"
high_layer.streams = [preload("res://audio/engine_high.wav")]
high_layer.parameter_range = Vector2(0.6, 1.0)  # Active when RPM is 0.6-1.0
high_layer.looping = true

engine_event.layers = [idle_layer, mid_layer, high_layer]
engine_event.crossfade_time = 0.3  # 300ms crossfade
engine_event.pitch_follows_parameter = true
engine_event.pitch_parameter_scale = 0.5  # Pitch increases with RPM

# Create the parameter
AudioController.create_parameter("engine_rpm", 0.0, 1.0, 0.0)

# Play the layered event
AudioController.play_layered_event(engine_event)

# Update parameter in real-time (e.g., in _process)
func _process(delta):
    var rpm_normalized = current_rpm / max_rpm
    AudioController.set_parameter_smooth("engine_rpm", rpm_normalized)
```

### 4. Creating Adaptive Music with Stems

```gdscript
# Create music event
var combat_music = MusicEvent.new()
combat_music.music_name = "CombatMusic"
combat_music.bpm = 140.0
combat_music.beats_per_bar = 4
combat_music.loop = true

# Create stems
var drums_stem = MusicEvent.MusicStem.new()
drums_stem.stem_name = "Drums"
drums_stem.stream = preload("res://music/combat_drums.wav")
drums_stem.default_enabled = true
drums_stem.volume_offset = 0.0

var bass_stem = MusicEvent.MusicStem.new()
bass_stem.stem_name = "Bass"
bass_stem.stream = preload("res://music/combat_bass.wav")
bass_stem.default_enabled = true
bass_stem.volume_offset = -3.0

var intensity_stem = MusicEvent.MusicStem.new()
intensity_stem.stem_name = "Intensity"
intensity_stem.stream = preload("res://music/combat_intensity.wav")
intensity_stem.default_enabled = false  # Starts disabled
intensity_stem.control_parameter = "combat_intensity"
intensity_stem.parameter_range = Vector2(0.5, 1.0)  # Active when intensity > 0.5

combat_music.stems = [drums_stem, bass_stem, intensity_stem]

# Create parameter for combat intensity
AudioController.create_parameter("combat_intensity", 0.0, 1.0, 0.0)

# Play music
MusicManager.play_music(combat_music, 2.0)  # 2 second fade in

# Control stems
MusicManager.set_stem_enabled("Intensity", true, 1.0)  # Fade in intensity layer

# Update intensity based on game state
AudioController.set_parameter_smooth("combat_intensity", 0.8)
```

### 5. BPM Synchronization

```gdscript
# Start global BPM clock
AudioController.start_bpm_clock()

# Set BPM manually
AudioController.set_bpm(120.0)

# Connect to beat signals
AudioController.beat.connect(_on_beat)
AudioController.bar.connect(_on_bar)

func _on_beat(beat_number: int):
    # Flash visual indicator
    beat_indicator.flash()

func _on_bar(bar_number: int):
    # Trigger bar-synced events
    if bar_number % 4 == 0:
        AudioController.play_event(downbeat_event)

# Get timing information
var current_beat = AudioController.get_current_beat()
var time_to_next_beat = AudioController.get_time_to_next_beat()
var beat_phase = AudioController.get_beat_phase()  # 0.0 to 1.0
```

### 6. Audio Snapshots

```gdscript
# Create a snapshot for underwater audio
var underwater_snapshot = AudioSnapshot.new()
underwater_snapshot.snapshot_name = "Underwater"

# Capture current mixer state
underwater_snapshot.capture_current_mixer_state()

# Or manually configure bus states
var master_state = AudioSnapshot.BusState.new()
master_state.bus_name = "Master"
master_state.enable_lowpass = true
master_state.lowpass_cutoff = 500.0  # Hz
master_state.volume_db = -6.0

var music_state = AudioSnapshot.BusState.new()
music_state.bus_name = "Music"
music_state.volume_db = -12.0

underwater_snapshot.bus_states = [master_state, music_state]
underwater_snapshot.transition_time = 1.5

# Register snapshot
AudioController.register_snapshot(underwater_snapshot)

# Apply snapshot
AudioController.apply_snapshot("Underwater", 1.5)  # 1.5 second transition
```

---

## Use Case Examples

### Example 1: Footsteps with Surface Types

```gdscript
# Use parameters to change footstep sounds based on surface
AudioController.create_parameter("surface_type", 0.0, 3.0, 0.0)  # 0=grass, 1=wood, 2=metal, 3=water

var footstep = LayeredAudioEvent.new()
footstep.control_parameter = "surface_type"

# Each layer represents a different surface
var grass_layer = LayeredAudioEvent.AudioLayer.new()
grass_layer.streams = [preload("res://audio/footstep_grass_1.wav"), ...]
grass_layer.parameter_range = Vector2(-0.5, 0.5)  # Active around 0

# ... add other surface layers ...

# In game code
func _on_player_step():
    match current_surface:
        Surface.GRASS:
            AudioController.set_parameter("surface_type", 0.0)
        Surface.WOOD:
            AudioController.set_parameter("surface_type", 1.0)
        # ...

    AudioController.play_layered_event(footstep_event, player.global_position)
```

### Example 2: Dynamic Weather Ambience

```gdscript
# Create parameters for weather intensity
AudioController.create_parameter("rain_intensity", 0.0, 1.0, 0.0)
AudioController.create_parameter("wind_intensity", 0.0, 1.0, 0.0)

# Create layered ambient event
var weather_ambient = LayeredAudioEvent.new()

# Rain layer controlled by rain_intensity
var rain_layer = LayeredAudioEvent.AudioLayer.new()
rain_layer.control_parameter = "rain_intensity"
rain_layer.parameter_range = Vector2(0.1, 1.0)
rain_layer.streams = [preload("res://audio/rain_loop.wav")]

# Wind layer controlled by wind_intensity
var wind_layer = LayeredAudioEvent.AudioLayer.new()
wind_layer.control_parameter = "wind_intensity"
wind_layer.parameter_range = Vector2(0.2, 1.0)
wind_layer.streams = [preload("res://audio/wind_loop.wav")]

weather_ambient.layers = [rain_layer, wind_layer]

# Start ambient
AudioController.play_layered_event(weather_ambient)

# Update based on weather system
func update_weather(rain: float, wind: float):
    AudioController.set_parameter_smooth("rain_intensity", rain)
    AudioController.set_parameter_smooth("wind_intensity", wind)
```

### Example 3: Rhythm Game

```gdscript
# Start BPM clock at song tempo
AudioController.set_bpm(140.0)
AudioController.time_signature = 4
AudioController.start_bpm_clock()

# Play music
MusicManager.play_music(song_music_event)

# Sync gameplay to beats
AudioController.beat.connect(_on_beat)

var beat_targets = []

func _on_beat(beat_num: int):
    # Spawn note on each beat
    spawn_note_target()

    # Play metronome on downbeat
    if beat_num == 0:
        AudioController.play_event(downbeat_sfx)

# Player input scoring
func _input(event):
    if event.is_action_pressed("hit_note"):
        var beat_phase = AudioController.get_beat_phase()

        # Perfect timing window
        if beat_phase < 0.1 or beat_phase > 0.9:
            score += 100
            AudioController.play_event(perfect_hit_sfx)
        # Good timing
        elif beat_phase < 0.3 or beat_phase > 0.7:
            score += 50
            AudioController.play_event(good_hit_sfx)
```

### Example 4: Stealth Game with Music Stems

```gdscript
# Music with different intensity layers
var stealth_music = MusicEvent.new()
stealth_music.bpm = 90.0

# Ambient layer - always playing
var ambient_stem = MusicEvent.MusicStem.new()
ambient_stem.stem_name = "Ambient"
ambient_stem.default_enabled = true

# Tension layer - plays when enemies nearby
var tension_stem = MusicEvent.MusicStem.new()
tension_stem.stem_name = "Tension"
tension_stem.control_parameter = "stealth_tension"
tension_stem.parameter_range = Vector2(0.3, 0.7)

# Combat layer - plays when detected
var combat_stem = MusicEvent.MusicStem.new()
combat_stem.stem_name = "Combat"
combat_stem.control_parameter = "stealth_tension"
combat_stem.parameter_range = Vector2(0.7, 1.0)

stealth_music.stems = [ambient_stem, tension_stem, combat_stem]

# Create parameter
AudioController.create_parameter("stealth_tension", 0.0, 1.0, 0.0)

# Game logic
func update_stealth_state():
    var tension = 0.0

    if player.is_detected:
        tension = 1.0  # Combat
    elif enemies_nearby:
        tension = 0.5  # Tension
    else:
        tension = 0.0  # Calm

    AudioController.set_parameter_smooth("stealth_tension", tension)
```

---

## API Reference

### AudioController (Autoload)

#### Event Playback
- `play_event(event: AudioEvent, position: Vector3 = Vector3.ZERO) -> bool`
- `play_event_quantized(event: AudioEvent, quantize_to_bar: bool = false, position: Vector3 = Vector3.ZERO)`
- `play_layered_event(event: LayeredAudioEvent, position: Vector3 = Vector3.ZERO) -> bool`
- `stop_layered_event(event: LayeredAudioEvent, fade_out_time: float = 0.5)`

#### Parameters
- `create_parameter(name: String, min: float, max: float, default: float) -> AudioParameter`
- `get_parameter(name: String) -> AudioParameter`
- `set_parameter(name: String, value: float)`
- `set_parameter_smooth(name: String, value: float)`
- `get_parameter_value(name: String) -> float`

#### BPM Clock
- `start_bpm_clock()`
- `stop_bpm_clock()`
- `reset_bpm_clock()`
- `set_bpm(bpm: float, transition_time: float = 0.0)`
- `get_current_beat() -> int`
- `get_current_bar() -> int`
- `get_time_to_next_beat() -> float`
- `get_time_to_next_bar() -> float`
- `get_beat_phase() -> float`
- `get_bar_phase() -> float`

#### Snapshots
- `register_snapshot(snapshot: AudioSnapshot)`
- `apply_snapshot(name: String, transition_time: float = -1.0)`

#### Signals
- `beat(beat_number: int)` - Emitted on each beat
- `bar(bar_number: int)` - Emitted on each bar
- `bpm_changed(new_bpm: float)` - Emitted when BPM changes
- `parameter_changed(param_name: String, value: float)` - Emitted when parameter value changes

---

### MusicManager (Autoload)

#### Playback
- `play_music(music: MusicEvent, fade_in_time: float = 0.0) -> bool`
- `stop_music(fade_out_time: float = 1.0)`
- `pause_music()`
- `resume_music()`
- `is_playing() -> bool`
- `get_current_music() -> MusicEvent`

#### Stem Control
- `set_stem_enabled(stem_name_or_index: Variant, enabled: bool, fade_time: float = -1.0)`
- `solo_stem(stem_name_or_index: Variant, fade_time: float = -1.0)`
- `unsolo_all(fade_time: float = -1.0)`

#### Transitions
- `transition_to(new_music: MusicEvent, transition_type: int = 1, transition_time: float = 2.0)`

#### Signals
- `music_started(music_name: String)`
- `music_stopped(music_name: String)`
- `stem_toggled(stem_name: String, enabled: bool)`
- `music_transitioned(from_music: String, to_music: String)`
- `beat(beat_number: int)`
- `bar(bar_number: int)`
- `marker_reached(marker_name: String)`

---

## Performance Tips

1. **Pool Sizing**: Adjust `initial_pool_size_2d` and `initial_pool_size_3d` in AudioController based on your game's needs
2. **Max Instances**: Set appropriate `max_concurrent_instances` for each event to prevent audio clutter
3. **Voice Stealing**: Enable `enable_voice_stealing` for non-critical sounds
4. **Cooldowns**: Use `cooldown_time` to prevent rapid-fire sounds
5. **Streaming**: Use compressed audio formats (Ogg Vorbis) for music and long ambiences
6. **2D vs 3D**: Use 2D players for UI and music, reserve 3D players for spatial audio

---

## Troubleshooting

### Event Not Playing
- Check if AudioController is registered as autoload
- Verify the event has streams assigned
- Check `max_concurrent_instances` limit
- Verify bus name exists in AudioServer

### Layered Event Not Crossfading
- Ensure `control_parameter` matches a created parameter
- Check parameter ranges don't have gaps
- Verify `crossfade_time` > 0

### Music Not Syncing
- Ensure all stems have the same length
- Enable `sync_stems` in MusicEvent
- Check that stems are compatible file formats

### BPM Clock Not Working
- Call `AudioController.start_bpm_clock()`
- Check `enable_bpm_sync` is true
- Verify signals are connected

---

## License

This plugin is open source. Feel free to use, modify, and distribute in your projects.

## Credits

Designed to bring FMOD and Wwise-style workflows to Godot 4 developers.

---

**Enjoy creating immersive soundscapes! 🎵🎮**
