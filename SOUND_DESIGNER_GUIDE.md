# Sound Designer Workflow Guide

## ✨ Zero-Code Audio Design in Godot 4

This guide is for **sound designers and audio engineers** who want to create and manage game audio **without writing any code**. The developer will simply play your events and update parameters.

---

## 🎯 Your Workflow (No Coding Required!)

1. **Create audio event resources** (right-click in FileSystem)
2. **Edit properties in the Inspector** (Godot's built-in Inspector)
3. **Test playback directly** in the Inspector (using the Test button)
4. **Save as `.tres` files** for developers to use
5. **Organize in folders** (music, sfx, ui, ambient, etc.)

---

## 📁 Getting Started

### Step 1: Open Your Project

1. Open Godot 4
2. Make sure the **Audio Mixer** plugin is enabled:
   - Go to **Project > Project Settings > Plugins**
   - Enable "Audio Mixer"

### Step 2: Understand the Interface

You have **two main tools**:

1. **FileSystem Dock** (bottom-left) - Where you create and organize audio events
2. **Inspector Dock** (right side) - Where you edit event properties and test playback
3. **Audio Mixer Tab** (top) - Where you browse all events and see statistics

---

## 🎵 Creating Different Types of Audio Events

### Type 1: Simple Sound Effect (AudioEvent)

**Use for:** Footsteps, gunshots, UI clicks, explosions, one-shots

**How to create:**

1. In the FileSystem dock, navigate to `res://audio_events/sfx/`
2. Right-click > **New Resource**
3. Search for **"AudioEvent"** and select it
4. Name it (e.g., `footstep.tres`)
5. Click on the new file to select it
6. The Inspector will show all properties

**Properties to configure:**

```
Event Identity
├─ Event Name: "Footstep"           (Human-readable name)
├─ Category: "SFX/Player"            (For organization)
└─ Description: "Player footstep sounds with surface variation"

Audio Sources
├─ Streams: [Drag .wav/.ogg files here from FileSystem]
│   Example: footstep1.wav, footstep2.wav, footstep3.wav
└─ Playback Mode: "Random One"       (Picks random variation)

Randomization
├─ Volume Range: (-3.0, 0.0)         (Random volume ±3dB)
└─ Pitch Range: (0.95, 1.05)         (Random pitch ±5%)

Playback Control
├─ Max Concurrent Instances: 5       (Prevent spam)
└─ Cooldown Time: 0.1                (100ms between plays)

Spatial Audio
├─ Spatial Mode: "3D"                (or "2D" for UI sounds)
└─ Max Distance: 50.0                (How far sound travels)

Audio Routing
└─ Bus Name: "SFX"                   (Which mixer bus to use)
```

**Testing:**

- Scroll to bottom of Inspector
- Click **▶ Test Playback**
- Each click will play with random variation!
- Click **■ Stop** to stop

**Developer Usage:**
```gdscript
# Developer just needs one line:
AudioController.play_event(footstep_event, player_position)
```

---

### Type 2: Layered Audio (LayeredAudioEvent)

**Use for:** Car engines, dynamic ambiences, weapon charge-ups, breathing

**How to create:**

1. Right-click in FileSystem > **New Resource** > **LayeredAudioEvent**
2. Name it (e.g., `car_engine.tres`)

**Properties to configure:**

```
Event Identity
├─ Event Name: "CarEngine"
├─ Category: "Layered/Vehicles"
└─ Description: "3-layer engine with RPM control"

Layers
└─ Layers: [Click to add layers]

    Layer 0: "Idle"
    ├─ Layer Name: "Idle"
    ├─ Streams: [idle_loop.wav]
    ├─ Parameter Range: (0.0, 0.3)      ← Active when param is 0-30%
    ├─ Volume Offset: 0.0 dB
    ├─ Pitch Offset: 1.0
    ├─ Looping: ✓

    Layer 1: "Mid RPM"
    ├─ Layer Name: "Mid RPM"
    ├─ Streams: [mid_rpm_loop.wav]
    ├─ Parameter Range: (0.2, 0.7)      ← Active when param is 20-70%
    ├─ Volume Offset: -2.0 dB
    ├─ Looping: ✓

    Layer 2: "High RPM"
    ├─ Layer Name: "High RPM"
    ├─ Streams: [high_rpm_loop.wav]
    ├─ Parameter Range: (0.6, 1.0)      ← Active when param is 60-100%
    ├─ Volume Offset: -3.0 dB
    ├─ Looping: ✓

Control Parameter: "engine_rpm"         ← Developer will update this
Crossfade Time: 0.3                     ← Smooth 300ms crossfades

Advanced
├─ Pitch Follows Parameter: ✓           ← Pitch increases with RPM
└─ Pitch Parameter Scale: 0.5

Playback
└─ Bus Name: "SFX"
```

**How Layers Work:**

Imagine a slider from 0.0 to 1.0:
```
0.0    0.2    0.3    0.6    0.7    1.0
├──────┼──────┼──────┼──────┼──────┤
│ Idle │ Both │ Mid  │ Both │ High │
```

- At **0.0-0.2**: Only Idle layer plays
- At **0.2-0.3**: Idle and Mid crossfade
- At **0.3-0.6**: Only Mid layer plays
- At **0.6-0.7**: Mid and High crossfade
- At **0.7-1.0**: Only High layer plays

**Testing with Parameter Control:**

1. Click **▶ Test Playback** in Inspector
2. Use the **Parameter Slider** that appears to hear layers crossfade
3. Move slider from 0.0 to 1.0 to hear all layers

**Developer Usage:**
```gdscript
# Developer creates the parameter and updates it
AudioController.create_parameter("engine_rpm", 0.0, 1.0, 0.0)
AudioController.play_layered_event(car_engine_event)

# In game loop, developer updates based on RPM
var rpm_normalized = current_rpm / max_rpm
AudioController.set_parameter_smooth("engine_rpm", rpm_normalized)
```

---

### Type 3: Adaptive Music (MusicEvent)

**Use for:** Background music with stems that adapt to gameplay

**How to create:**

1. Right-click in FileSystem > **New Resource** > **MusicEvent**
2. Name it (e.g., `combat_music.tres`)

**Properties to configure:**

```
Music Identity
├─ Music Name: "CombatMusic"
├─ Category: "Music"
└─ Description: "Adaptive combat music with intensity layers"

Musical Timing
├─ BPM: 140.0                         ← Beats per minute
├─ Beats Per Bar: 4                   ← 4/4 time signature
└─ Quantization: "Quarter Note"

Music Stems
└─ Stems: [Click to add stems]

    Stem 0: "Drums"
    ├─ Stem Name: "Drums"
    ├─ Stream: [combat_drums.wav]      ← MUST be same length as other stems!
    ├─ Default Enabled: ✓              ← Always playing
    ├─ Volume Offset: 0.0 dB
    ├─ Control Parameter: ""           ← Empty = always on

    Stem 1: "Bass"
    ├─ Stem Name: "Bass"
    ├─ Stream: [combat_bass.wav]
    ├─ Default Enabled: ✓
    ├─ Volume Offset: -3.0 dB

    Stem 2: "Intensity"
    ├─ Stem Name: "Intensity"
    ├─ Stream: [combat_intensity.wav]
    ├─ Default Enabled: ✗              ← Starts disabled
    ├─ Control Parameter: "combat_intensity"
    ├─ Parameter Range: (0.5, 1.0)     ← Fades in when intensity > 50%
    ├─ Fade Time: 2.0                  ← 2 second fade

Transitions
├─ Loop: ✓
└─ Loop Start Beat: -1                ← -1 = loop from start

Playback
└─ Bus Name: "Music"
```

**⚠️ IMPORTANT: Stem Requirements**

- **All stems MUST be the same length** (e.g., all 2 minutes long)
- Export stems from your DAW at the same BPM and length
- All stems will play synchronized, like tracks in a DAW

**Testing:**

1. Click **▶ Test Playback**
2. All default-enabled stems will play
3. Use the **Parameter Slider** to control intensity stem

**Developer Usage:**
```gdscript
# Developer starts music
MusicManager.play_music(combat_music, 2.0)  # 2s fade in

# Developer updates intensity based on game state
AudioController.create_parameter("combat_intensity", 0.0, 1.0, 0.0)

# When combat starts:
AudioController.set_parameter_smooth("combat_intensity", 1.0)

# When combat ends:
AudioController.set_parameter_smooth("combat_intensity", 0.0)
```

---

### Type 4: Mixer Snapshot (AudioSnapshot)

**Use for:** Underwater effect, pause menu, cinematic moments

**How to create:**

1. Right-click in FileSystem > **New Resource** > **AudioSnapshot**
2. Name it (e.g., `underwater.tres`)

**Properties to configure:**

```
Snapshot Identity
├─ Snapshot Name: "Underwater"
└─ Description: "Muffled audio for underwater"

Transition
├─ Transition Time: 1.5               ← Smooth 1.5s transition
└─ Transition Curve: 0.5              ← Linear fade

Bus States
└─ Auto Capture All Buses: ✓         ← Captures current mixer state

    OR manually configure:

    Bus 0: Master
    ├─ Bus Name: "Master"
    ├─ Volume DB: -6.0                ← Quieter
    ├─ Mute: ✗
    ├─ Enable Lowpass: ✓
    └─ Lowpass Cutoff: 500.0 Hz       ← Muffled sound

    Bus 1: Music
    ├─ Bus Name: "Music"
    └─ Volume DB: -12.0               ← Very quiet
```

**Testing:**

1. Click **▶ Test Playback** to apply snapshot
2. Listen to how the entire mix changes
3. Test with other sounds playing

**Developer Usage:**
```gdscript
# When player enters water:
AudioController.apply_snapshot("Underwater", 1.5)

# When player exits water:
AudioController.apply_snapshot("Default", 1.5)
```

---

## 🎨 Best Practices for Sound Designers

### File Organization

```
audio_events/
├── music/
│   ├── menu_music.tres
│   ├── gameplay_music.tres
│   └── boss_music.tres
├── sfx/
│   ├── player/
│   │   ├── footstep.tres
│   │   ├── jump.tres
│   │   └── land.tres
│   ├── weapons/
│   │   ├── pistol_fire.tres
│   │   ├── rifle_fire.tres
│   │   └── reload.tres
│   └── environment/
│       ├── door_open.tres
│       └── explosion.tres
├── ui/
│   ├── button_click.tres
│   └── menu_hover.tres
├── ambient/
│   ├── forest_ambient.tres      (LayeredAudioEvent)
│   └── city_ambient.tres        (LayeredAudioEvent)
└── snapshots/
    ├── underwater.tres
    ├── pause_menu.tres
    └── cinematic.tres
```

### Naming Conventions

**Good Names:**
- `footstep_concrete.tres`
- `weapon_pistol_fire.tres`
- `ui_button_confirm.tres`
- `music_combat_intense.tres`

**Bad Names:**
- `sound1.tres`
- `new_audio_event.tres`
- `test.tres`

### Audio File Tips

**Formats:**
- **.wav** - Uncompressed, high quality, use for short SFX
- **.ogg** - Compressed, good for music and long ambiences
- **.mp3** - Also supported, but Ogg is preferred

**Sample Rates:**
- **44.1kHz or 48kHz** - Standard
- **16-bit or 24-bit** - 16-bit is usually fine

**Looping:**
- Use **loop points** in your audio editor (Audacity, etc.)
- Godot respects loop metadata in WAV files

### Volume and Pitch Ranges

**Volume Range Guidelines:**
```
Very Subtle:     (-1.0, 0.0) dB     UI sounds
Subtle:          (-3.0, 0.0) dB     Footsteps
Moderate:        (-6.0, 0.0) dB     Weapon impacts
Noticeable:      (-10.0, 0.0) dB    Explosions (wide variation)
```

**Pitch Range Guidelines:**
```
Minimal:         (0.98, 1.02)       Realistic sounds (dialogue)
Subtle:          (0.95, 1.05)       Footsteps, impacts
Moderate:        (0.90, 1.10)       Cartoon effects
Extreme:         (0.80, 1.20)       Sci-fi, fantasy
```

### Parameter Design

**Good Parameter Names:**
- `engine_rpm` (0.0 to 1.0)
- `combat_intensity` (0.0 to 1.0)
- `player_health` (0.0 to 1.0)
- `surface_type` (0=grass, 1=wood, 2=metal)
- `weather_intensity` (0.0 to 1.0)

**Layer Parameter Ranges (for smooth crossfades):**
```
Layer 1: (0.0, 0.4)    ← Overlap at 0.3-0.4
Layer 2: (0.3, 0.7)    ← Overlaps both sides
Layer 3: (0.6, 1.0)    ← Overlap at 0.6-0.7
```

The **overlaps** create smooth crossfades!

---

## 🎮 Working with Developers

### What You Provide

You create and save `.tres` files. That's it!

**Example deliverable:**
```
audio_events/sfx/weapons/pistol_fire.tres
```

### What Developer Does

Developer loads your resource and plays it:

```gdscript
# Load your event
@export var pistol_fire: AudioEvent

# Play it
func shoot():
    AudioController.play_event(pistol_fire, gun_position)
```

### Parameter Communication

You design parameters in your events. Developer updates them.

**Your work:**
- Create `car_engine.tres` (LayeredAudioEvent)
- Set control parameter name: `"engine_rpm"`
- Design layer ranges (0-0.3, 0.2-0.7, 0.6-1.0)

**Developer's work:**
```gdscript
# Create parameter (usually in _ready)
AudioController.create_parameter("engine_rpm", 0.0, 1.0, 0.0)

# Update it during gameplay
AudioController.set_parameter("engine_rpm", normalized_rpm)
```

### Iteration Workflow

**You:**
1. Adjust properties in Inspector
2. Test with ▶ Test Playback button
3. Save the `.tres` file (Ctrl+S)

**Developer:**
- File automatically updates in game (no code changes needed!)
- They can tweak parameter values in game logic if needed

---

## 🔧 Using the Audio Mixer Tab

The **Audio Mixer** tab (at the top of the editor) provides:

1. **Event Browser** - See all your events organized by folder
2. **Search** - Quickly find events
3. **Quick Test** - Select and test any event
4. **Parameters Panel** - See all active parameters and their values
5. **BPM Sync Panel** - Control global BPM clock
6. **Statistics** - See how many sounds are playing, pool usage, etc.

**How to use:**
1. Click **Audio Mixer** tab at the top
2. Browse your events in the tree view
3. Click an event to see its properties
4. Click **Test Playback** to hear it
5. Use the **Parameters** tab to create/test parameters
6. Use the **BPM Sync** tab to set global tempo

---

## 🎯 Common Scenarios

### Scenario 1: Footsteps with Surface Variation

**Create ONE LayeredAudioEvent:**

```
footstep.tres
├─ Control Parameter: "surface_type"
├─ Layer 0: "Grass" - Streams: [grass1.wav, grass2.wav, grass3.wav]
│   └─ Parameter Range: (-0.5, 0.5)    ← Around 0.0
├─ Layer 1: "Wood" - Streams: [wood1.wav, wood2.wav]
│   └─ Parameter Range: (0.5, 1.5)     ← Around 1.0
├─ Layer 2: "Metal" - Streams: [metal1.wav, metal2.wav]
│   └─ Parameter Range: (1.5, 2.5)     ← Around 2.0
└─ Layer 3: "Water" - Streams: [splash1.wav, splash2.wav]
    └─ Parameter Range: (2.5, 3.5)     ← Around 3.0
```

**Developer sets surface:**
```gdscript
match current_surface:
    GRASS: AudioController.set_parameter("surface_type", 0.0)
    WOOD:  AudioController.set_parameter("surface_type", 1.0)
    METAL: AudioController.set_parameter("surface_type", 2.0)
    WATER: AudioController.set_parameter("surface_type", 3.0)

AudioController.play_layered_event(footstep_event, player_position)
```

### Scenario 2: Dynamic Weather Ambience

**Create ONE LayeredAudioEvent:**

```
weather_ambient.tres
├─ Layer 0: "Wind"
│   ├─ Streams: [wind_loop.wav]
│   ├─ Control Parameter: "wind_intensity"
│   └─ Parameter Range: (0.2, 1.0)
├─ Layer 1: "Rain"
│   ├─ Streams: [rain_light.wav, rain_heavy.wav]
│   ├─ Control Parameter: "rain_intensity"
│   └─ Parameter Range: (0.1, 1.0)
└─ Layer 2: "Thunder"
    ├─ Streams: [thunder_distant.wav]
    ├─ Control Parameter: "storm_intensity"
    └─ Parameter Range: (0.7, 1.0)     ← Only during storms
```

**Developer controls weather:**
```gdscript
AudioController.set_parameter("wind_intensity", wind_level)
AudioController.set_parameter("rain_intensity", rain_level)
AudioController.set_parameter("storm_intensity", storm_level)
```

### Scenario 3: Combat Music with Intensity

**Create MusicEvent:**

```
combat_music.tres (140 BPM, 4/4)
├─ Stem 0: "Drums" - Always on
├─ Stem 1: "Bass" - Always on
├─ Stem 2: "Melody" - Always on
├─ Stem 3: "Intensity Layer"
│   ├─ Default Enabled: ✗
│   ├─ Control Parameter: "combat_intensity"
│   └─ Parameter Range: (0.5, 1.0)    ← Fades in during combat
└─ Stem 4: "Strings (High Danger)"
    ├─ Default Enabled: ✗
    ├─ Control Parameter: "combat_intensity"
    └─ Parameter Range: (0.8, 1.0)    ← Only at high intensity
```

**Developer updates intensity:**
```gdscript
# No enemies: 0.0
# Enemies nearby: 0.5
# Combat: 0.8
# Boss fight: 1.0
AudioController.set_parameter("combat_intensity", current_intensity)
```

---

## ❓ FAQ

**Q: Do I need to know GDScript?**
A: **No!** You work entirely in the editor. Developers handle the code.

**Q: Can I test events without running the game?**
A: **Yes!** Use the **▶ Test Playback** button in the Inspector.

**Q: What if I change an event after the developer uses it?**
A: **It updates automatically!** No code changes needed.

**Q: How do I know what parameters to create?**
A: **Communicate with your developer.** They'll tell you what game states need audio control (health, speed, combat, etc.).

**Q: Can I create parameters in the editor?**
A: Parameters are created by developers, but you reference them by name in your events. Talk with your dev team about naming.

**Q: How do I make music stems?**
A: Export all stems from your DAW at the **same length and BPM**. Import them as separate files, then assign to different stems in a MusicEvent.

**Q: What's the difference between LayeredAudioEvent and MusicEvent?**
- **LayeredAudioEvent**: Crossfading sound layers (engines, ambiences, drones)
- **MusicEvent**: Musical stems that play together (drums, bass, melody, etc.)

**Q: Can I have multiple variations in a stem?**
A: No, each stem has ONE stream. But you can have multiple variations in AudioEvent and LayeredAudioEvent layers.

**Q: How do I make sounds loop?**
A:
- For AudioEvent: Enable loop metadata in your audio file
- For LayeredAudioEvent: Check "Looping" on each layer
- For MusicEvent: Check "Loop" on the event

---

## 🎓 Quick Reference Card

| Need | Use | Key Properties |
|------|-----|----------------|
| Simple SFX | **AudioEvent** | Streams, Volume/Pitch Range, Bus |
| Variations | **AudioEvent** | Multiple Streams, Playback Mode = Random |
| Layered Sound | **LayeredAudioEvent** | Layers, Control Parameter, Crossfade Time |
| Adaptive Music | **MusicEvent** | Stems, BPM, Control Parameters |
| Mix Changes | **AudioSnapshot** | Bus States, Transition Time |

---

**You're ready to create amazing game audio without touching a single line of code! 🎵🎮**
