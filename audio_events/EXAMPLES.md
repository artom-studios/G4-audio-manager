# Audio Events Examples

This folder contains example audio event resources that demonstrate the capabilities of the Audio Mixer system.

## Folder Structure

```
audio_events/
├── music/          # Music events with stems
├── sfx/            # Sound effects
│   ├── player/     # Player-related sounds
│   ├── weapons/    # Weapon sounds
│   └── environment/# Environmental sounds
├── ui/             # UI sounds
├── ambient/        # Ambient loops and layered ambiences
└── snapshots/      # Mixer snapshots for different game states
```

## Creating Audio Events

### In the Editor

1. Open the **Audio Mixer** tab at the top of the Godot editor
2. Click **"Create New Event"** and choose the event type:
   - **AudioEvent**: Simple one-shot or looping sounds
   - **LayeredAudioEvent**: Multi-layer sounds with parameter control
   - **MusicEvent**: Adaptive music with stems
   - **AudioSnapshot**: Mixer state capture
3. Select the event in the list
4. Edit properties in the Inspector panel
5. Drag audio files from FileSystem into the `streams` array
6. Click **"Test Playback"** to preview

### Via Code

```gdscript
# Create AudioEvent
var event = AudioEvent.new()
event.event_name = "MySound"
event.streams = [preload("res://audio/sound.wav")]
event.bus_name = "SFX"
ResourceSaver.save(event, "res://audio_events/sfx/my_sound.tres")
```

## Example Use Cases

### Simple SFX

```gdscript
# Footstep with variations
var footstep = AudioEvent.new()
footstep.event_name = "Footstep"
footstep.streams = [
    preload("res://audio/step1.wav"),
    preload("res://audio/step2.wav"),
    preload("res://audio/step3.wav")
]
footstep.volume_range = Vector2(-3, 0)
footstep.pitch_range = Vector2(0.9, 1.1)
footstep.playback_mode = AudioEvent.PlaybackMode.RANDOM_ONE
```

### Car Engine (Layered)

```gdscript
var engine = LayeredAudioEvent.new()
engine.event_name = "CarEngine"
engine.control_parameter = "engine_rpm"

# Idle layer (0-30% RPM)
var idle = LayeredAudioEvent.AudioLayer.new()
idle.streams = [preload("res://audio/engine_idle.wav")]
idle.parameter_range = Vector2(0.0, 0.3)
idle.looping = true

# Mid layer (20-70% RPM)
var mid = LayeredAudioEvent.AudioLayer.new()
mid.streams = [preload("res://audio/engine_mid.wav")]
mid.parameter_range = Vector2(0.2, 0.7)
mid.looping = true

# High layer (60-100% RPM)
var high = LayeredAudioEvent.AudioLayer.new()
high.streams = [preload("res://audio/engine_high.wav")]
high.parameter_range = Vector2(0.6, 1.0)
high.looping = true

engine.layers = [idle, mid, high]
engine.pitch_follows_parameter = true
```

### Adaptive Combat Music

```gdscript
var combat = MusicEvent.new()
combat.music_name = "CombatTheme"
combat.bpm = 140.0
combat.beats_per_bar = 4

# Drums - always playing
var drums = MusicEvent.MusicStem.new()
drums.stem_name = "Drums"
drums.stream = preload("res://music/combat_drums.wav")
drums.default_enabled = true

# Intensity layer - controlled by parameter
var intensity = MusicEvent.MusicStem.new()
intensity.stem_name = "Intensity"
intensity.stream = preload("res://music/combat_intensity.wav")
intensity.control_parameter = "combat_intensity"
intensity.parameter_range = Vector2(0.5, 1.0)

combat.stems = [drums, intensity]
```

## Tips

- Use **RandomOne** playback mode for variation
- Set **max_concurrent_instances** to prevent audio flooding
- Use **cooldown_time** for rapid-fire events
- Enable **enable_voice_stealing** for less important sounds
- Use **fade_in/fade_out** for smooth playback
- Test in editor with the **Test Playback** button
