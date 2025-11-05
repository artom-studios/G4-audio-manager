# G4 Audio System - Professional Audio for Godot 4

A modern, Godot-native audio management system that brings FMOD/Wwise-like features to Godot 4. Built with proper separation of concerns using Resources, Nodes, and Singletons.

## 🎯 Project Status

**✅ Phase 1 Complete** - Core distributed architecture implemented

See [PHASE1_IMPLEMENTATION.md](PHASE1_IMPLEMENTATION.md) for detailed documentation.

---

## 🏗️ Architecture

G4 Audio follows Godot's native patterns with proper separation:

```
📦 RESOURCES (.tres files)
├─ AudioEvent          - Simple sound effects
├─ LayeredAudioEvent   - Multi-layer parameter-driven audio
└─ MusicEvent          - Adaptive music with stems

🎮 NODES (Scene components)
└─ AudioEventPlayer3D  - Play events at 3D positions

🌐 SINGLETONS (Autoloads)
├─ AudioManager        - Global audio coordinator
└─ MusicManager        - Music system
```

---

## 📚 Documentation

- **[Phase 1 Implementation](PHASE1_IMPLEMENTATION.md)** - Complete Phase 1 features and API
- **[Architecture Design](GODOT_ARCHITECTURE.md)** - Distributed Godot-native design
- **[Integration Guide](GODOT_NATIVE_INTEGRATION.md)** - How to integrate with Godot workflow
- **[Design Concept](FMOD_DESIGN_CONCEPT.md)** - Original FMOD-inspired design

---

## 🚀 Quick Start

### Installation

1. Copy `addons/g4_audio/` to your project's `addons/` directory
2. Enable the plugin in **Project → Project Settings → Plugins**
3. The AudioManager and MusicManager singletons are automatically registered

### Creating Your First Sound

1. **Create an AudioEvent resource:**
   - FileSystem → Right-click → New Resource → AudioEvent
   - Save as `footstep.tres`

2. **Configure in Inspector:**
   - Event Name: "Footstep"
   - Add 3 audio streams (variations)
   - Volume Range: -3 to 0 dB
   - Pitch Range: 0.95 to 1.05
   - Playback Mode: Random

3. **Play from code:**
```gdscript
@onready var footstep_event = preload("res://audio_events/footstep.tres")

func _on_footstep():
    AudioManager.play_event_3d(footstep_event, global_position)
```

### Or Use Nodes (No Code!)

```
Player (CharacterBody3D)
└─ FootstepPlayer (AudioEventPlayer3D)
    └─ event: res://audio_events/footstep.tres

# Then call from code or animation:
$FootstepPlayer.play()
```

---

## ✨ Features

### Phase 1 (Current)

✅ Resource-based audio events
✅ Object pooling for performance
✅ Parameter system with interpolation
✅ Layered audio with crossfading
✅ Adaptive music with stems
✅ BPM clock and beat tracking
✅ 2D and 3D spatial audio
✅ Cooldown and voice stealing
✅ Randomization (volume, pitch, variations)

### Coming in Phase 2

⏳ AudioEventPlayer2D
⏳ MusicPlayer node
⏳ AudioParameterDriver
⏳ Inspector plugins
⏳ Audio browser dock

---

## 📖 Examples

### Simple Sound Effect

```gdscript
# Create and configure event in editor
# Then play it:
AudioManager.play_event_3d(explosion_event, global_position)
```

### Layered Audio (Car Engine)

```gdscript
# Create LayeredAudioEvent in editor with 3 layers:
# - Idle (0-0.3)
# - Mid (0.2-0.7)
# - High (0.6-1.0)

# Create parameter
AudioManager.create_parameter("engine_rpm", 0.0, 8000.0, 1000.0)

# Play layered event
var instance_id = AudioManager.play_layered_event(engine_event, global_position)

# Update parameter (layers crossfade automatically!)
AudioManager.set_parameter("engine_rpm", 5000.0)
```

### Adaptive Music

```gdscript
# Create MusicEvent in editor with stems:
# - Drums (always on)
# - Bass (always on)
# - Melody (always on)
# - Intensity (parameter-controlled)

# Play music
MusicManager.play_music(combat_music, 2.0)  # 2s fade in

# Enable/disable stems
MusicManager.set_stem_enabled("Intensity", true, 1.0)

# Stop music
MusicManager.stop_music(3.0)  # 3s fade out
```

---

## 🎮 Workflow

### Sound Designer (No Code)

1. Create Resource → AudioEvent
2. Drag audio files to Inspector
3. Adjust settings (volume, pitch, etc.)
4. Save as `.tres` file
5. Done!

### Developer (Minimal Code)

**Option 1: Direct playback**
```gdscript
AudioManager.play_event_3d(event, position)
```

**Option 2: Using nodes**
```gdscript
# Add AudioEventPlayer3D to scene
# Assign event in Inspector
# Call play():
$AudioPlayer.play()
```

---

## 📊 API Reference

### AudioManager

```gdscript
# Play events
AudioManager.play_event(event: AudioEvent, position: Vector2) -> bool
AudioManager.play_event_3d(event: AudioEvent, position: Vector3) -> bool
AudioManager.play_layered_event(event: LayeredAudioEvent, position: Vector3) -> int
AudioManager.stop_layered_event(instance_id: int, fade_out: float = 0.0)

# Parameters
AudioManager.create_parameter(name: String, min: float, max: float, default: float)
AudioManager.set_parameter(name: String, value: float)
AudioManager.get_parameter(name: String) -> float

# BPM Clock
AudioManager.start_bpm_clock(bpm: float = 120.0, beats_per_bar: int = 4)
AudioManager.stop_bpm_clock()

# Stats
AudioManager.get_pool_stats() -> Dictionary
```

### MusicManager

```gdscript
# Playback
MusicManager.play_music(music: MusicEvent, fade_in: float = 0.0) -> bool
MusicManager.stop_music(fade_out: float = 0.0)

# Stem control
MusicManager.set_stem_enabled(stem_name: String, enabled: bool, fade_time: float = 1.0)

# Query
MusicManager.is_playing() -> bool
MusicManager.get_current_beat() -> int
MusicManager.get_current_bar() -> int
```

### Signals

```gdscript
# AudioManager
AudioManager.parameter_changed(param_name: String, value: float)
AudioManager.beat(beat_number: int)
AudioManager.bar(bar_number: int)

# MusicManager
MusicManager.music_started(music_name: String)
MusicManager.music_stopped(music_name: String)
MusicManager.stem_toggled(stem_name: String, enabled: bool)
MusicManager.beat(beat_number: int)
MusicManager.bar(bar_number: int)
```

---

## 🎯 Design Goals

1. **Godot-Native** - Uses Resources, Nodes, and Singletons properly
2. **Designer-Friendly** - No code required for sound designers
3. **Developer-Friendly** - Simple API, 1-2 lines of code
4. **Performant** - Object pooling, efficient voice management
5. **Professional** - FMOD/Wwise-like features in pure GDScript

---

## 📁 File Structure

```
addons/g4_audio/
├── plugin.gd                    # Plugin entry point
├── plugin.cfg                   # Plugin configuration
├── resources/                   # Resource definitions
│   ├── audio_parameter.gd
│   ├── audio_event.gd
│   ├── audio_layer.gd
│   ├── layered_audio_event.gd
│   ├── music_stem.gd
│   └── music_event.gd
├── autoloads/                   # Singleton managers
│   ├── audio_manager.gd
│   └── music_manager.gd
├── nodes/                       # Scene nodes
│   └── audio_event_player_3d.gd
├── helpers/                     # Helper classes
│   └── audio_pool.gd
└── icons/                       # Node icons (future)
```

---

## 🔧 Performance Tips

1. **Pool Sizing** - AudioManager uses pools of 50 (2D) and 30 (3D) players by default
2. **Max Instances** - Set per-event limits to prevent audio clutter
3. **Cooldowns** - Prevent sound spam with cooldown timers
4. **Streaming** - Use compressed formats (Ogg Vorbis) for music
5. **Voice Stealing** - Lower priority sounds are stolen when pool exhausted

---

## 🐛 Troubleshooting

### Event not playing
- Check plugin is enabled
- Verify event has streams assigned
- Check bus name exists

### Layered audio not crossfading
- Ensure parameter name matches
- Check parameter ranges overlap properly
- Verify crossfade_time > 0

### Music stems not syncing
- All stems must be same length
- Use identical sample rates
- Enable sync_layers

---

## 📝 License

MIT License - Free to use in any project (commercial or non-commercial)

---

## 🙏 Credits

Inspired by FMOD and Wwise, designed for the Godot community.

**Phase 1 Complete!** 🎉 The foundation is ready for building amazing audio experiences.
