# G4 Audio Studio - Godot-Native Architecture
## Proper Node/Singleton/Resource Organization

---

## 🎯 The Problem: One Tab is Too Much

You're right! Godot doesn't work this way. Look at how Godot organizes complex systems:

### Godot's Animation System:
```
Resources:     Animation (data file)
Nodes:         AnimationPlayer, AnimationTree (in scene)
Editor:        Animation panel (bottom dock)
              AnimationTree tab (custom)
Singleton:     (none - nodes handle it)
```

### Godot's Navigation System:
```
Resources:     NavigationMesh (data file)
Nodes:         NavigationRegion3D, NavigationAgent3D (in scene)
Editor:        Tools in 3D viewport toolbar
Singleton:     NavigationServer3D (global)
```

### Our Audio System Should Follow This Pattern!

---

## 🏗️ Proposed Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    G4 AUDIO SYSTEM                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  📦 RESOURCES (Data Files - Designer Creates)               │
│  ├─ AudioEvent.tres          (simple sounds)                │
│  ├─ LayeredAudioEvent.tres   (car engines, etc)            │
│  ├─ MusicEvent.tres          (adaptive music)              │
│  ├─ AudioSnapshot.tres       (mixer states)                │
│  └─ AudioParameter.tres      (runtime parameters)          │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  🎮 NODES (Scene Components - Developer Places)             │
│  ├─ AudioEventPlayer2D       (plays events at 2D position) │
│  ├─ AudioEventPlayer3D       (plays events at 3D position) │
│  ├─ MusicPlayer              (manages music playback)      │
│  ├─ AudioZone3D              (reverb zones)                │
│  ├─ AudioOccluder3D          (occlusion geometry)          │
│  └─ AudioParameterDriver     (drives parameters from game) │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  🌐 SINGLETONS (Autoloads - Always Available)              │
│  ├─ AudioManager             (main coordinator)            │
│  │   ├─ Object pooling                                     │
│  │   ├─ Parameter management                               │
│  │   ├─ BPM clock                                          │
│  │   └─ Voice stealing                                     │
│  └─ MusicManager             (music-specific)              │
│      ├─ Stem control                                       │
│      ├─ Transitions                                        │
│      └─ Playlist management                                │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  🔧 EDITOR PLUGINS (Tools - Designer Uses)                 │
│  ├─ Audio Browser Dock       (bottom dock - browse events) │
│  ├─ Audio Inspector Plugin   (right panel - edit props)    │
│  ├─ Audio Mixer Tab          (optional - advanced mixing)  │
│  ├─ Scene Tools              (toolbar - place audio nodes) │
│  └─ Context Menu Additions   (right-click enhancements)    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 1. Resources (Data Files)

### What They Are:
- Pure data definitions
- No runtime logic
- Saved as `.tres` files
- Created and edited by sound designers

### Implementation:

#### AudioEvent.gd
```gdscript
@tool
class_name AudioEvent
extends Resource

@export var event_name: String = ""
@export var category: String = "Uncategorized"
@export var streams: Array[AudioStream] = []
@export var volume_range: Vector2 = Vector2(-3.0, 0.0)
@export var pitch_range: Vector2 = Vector2(0.95, 1.05)
@export var spatial_mode: SpatialMode = SpatialMode.MODE_2D
@export var bus_name: String = "Master"
# ... etc
```

#### LayeredAudioEvent.gd
```gdscript
@tool
class_name LayeredAudioEvent
extends Resource

@export var event_name: String = ""
@export var control_parameter: String = ""
@export var layers: Array[AudioLayer] = []
@export var crossfade_time: float = 0.3
# ... etc
```

#### MusicEvent.gd
```gdscript
@tool
class_name MusicEvent
extends Resource

@export var music_name: String = ""
@export var bpm: float = 120.0
@export var beats_per_bar: int = 4
@export var stems: Array[MusicStem] = []
# ... etc
```

### How Designers Use Them:
1. Right-click in FileSystem → Create New → Resource → AudioEvent
2. Edit in Inspector (right panel)
3. Save as `.tres` file
4. Reference in nodes or code

---

## 🎮 2. Nodes (Scene Components)

### What They Are:
- Runtime instances
- Placed in scenes like any other node
- Can be configured in the editor
- Execute during gameplay

### AudioEventPlayer2D

```gdscript
@icon("res://addons/g4_audio/icons/audio_event_player_2d.svg")
class_name AudioEventPlayer2D
extends Node2D

## Plays AudioEvent at this node's 2D position

@export var event: AudioEvent
@export var autoplay: bool = false
@export var max_distance: float = 2000.0

func _ready():
    if autoplay:
        play()

func play():
    if event:
        AudioManager.play_event(event, global_position)

func stop():
    AudioManager.stop_event_at_position(global_position)
```

**Usage in Scene:**
```
Player (CharacterBody2D)
├─ Sprite2D
├─ CollisionShape2D
└─ FootstepPlayer (AudioEventPlayer2D)
    └─ event: res://audio_events/player/footstep.tres
```

### AudioEventPlayer3D

```gdscript
@icon("res://addons/g4_audio/icons/audio_event_player_3d.svg")
class_name AudioEventPlayer3D
extends Node3D

## Plays AudioEvent at this node's 3D position with spatial audio

@export var event: AudioEvent
@export var autoplay: bool = false
@export_range(0.0, 4096.0) var max_distance: float = 100.0
@export var attenuation_model: AttenuationModel = AttenuationModel.INVERSE_DISTANCE

func play():
    if event:
        AudioManager.play_event_3d(event, global_position)
```

**Usage in Scene:**
```
Enemy (CharacterBody3D)
├─ MeshInstance3D
├─ CollisionShape3D
├─ RoarSound (AudioEventPlayer3D)
│   └─ event: res://audio_events/enemies/roar.tres
└─ FootstepSound (AudioEventPlayer3D)
    └─ event: res://audio_events/enemies/footstep_heavy.tres
```

### MusicPlayer

```gdscript
@icon("res://addons/g4_audio/icons/music_player.svg")
class_name MusicPlayer
extends Node

## Manages music playback with transitions and stem control

@export var music: MusicEvent
@export var autoplay: bool = false
@export var fade_in_time: float = 2.0

func _ready():
    if autoplay:
        play()

func play():
    MusicManager.play_music(music, fade_in_time)

func stop(fade_out_time: float = 2.0):
    MusicManager.stop_music(fade_out_time)

func set_stem_enabled(stem_name: String, enabled: bool):
    MusicManager.set_stem_enabled(stem_name, enabled)
```

**Usage in Scene:**
```
MainMenu (Control)
├─ Background
├─ Buttons
└─ MenuMusic (MusicPlayer)
    ├─ music: res://music/menu_theme.tres
    └─ autoplay: true
```

### AudioZone3D

```gdscript
@icon("res://addons/g4_audio/icons/audio_zone_3d.svg")
class_name AudioZone3D
extends Area3D

## Defines a 3D zone that affects audio (reverb, filtering, etc.)

@export var zone_name: String = "Reverb Zone"
@export var effect_type: EffectType = EffectType.REVERB
@export var reverb_preset: ReverbPreset = ReverbPreset.LARGE_ROOM
@export var transition_time: float = 1.0

enum EffectType { REVERB, LOWPASS, HIGHPASS, CUSTOM }
enum ReverbPreset { SMALL_ROOM, LARGE_ROOM, HALL, CAVE, UNDERWATER }

func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D):
    if body.is_in_group("player"):
        AudioManager.enter_audio_zone(self)

func _on_body_exited(body: Node3D):
    if body.is_in_group("player"):
        AudioManager.exit_audio_zone(self)
```

**Usage in Scene:**
```
Cave (Node3D)
├─ MeshInstance3D (cave geometry)
├─ StaticBody3D (collision)
└─ CaveReverbZone (AudioZone3D)
    ├─ effect_type: Reverb
    ├─ reverb_preset: CAVE
    └─ CollisionShape3D (zone bounds)
```

### AudioParameterDriver

```gdscript
@icon("res://addons/g4_audio/icons/audio_parameter_driver.svg")
class_name AudioParameterDriver
extends Node

## Automatically drives an audio parameter from a property

@export var parameter_name: String = ""
@export var target_node: NodePath
@export var property_name: String = ""
@export_range(0.0, 10.0) var update_rate: float = 0.1

var _timer: float = 0.0

func _process(delta):
    _timer += delta
    if _timer >= update_rate:
        _timer = 0.0
        _update_parameter()

func _update_parameter():
    var node = get_node_or_null(target_node)
    if node and node.get(property_name) != null:
        var value = node.get(property_name)
        AudioManager.set_parameter(parameter_name, value)
```

**Usage in Scene:**
```
Car (VehicleBody3D)
├─ MeshInstance3D
├─ EngineSound (AudioEventPlayer3D)
│   └─ event: res://audio_events/car_engine_layered.tres
└─ SpeedParameterDriver (AudioParameterDriver)
    ├─ parameter_name: "car_speed"
    ├─ target_node: ".."
    └─ property_name: "linear_velocity.length()"
```

---

## 🌐 3. Singletons (Autoloads)

### What They Are:
- Global managers
- Always accessible via their name
- Handle system-wide coordination
- No need to place in scenes

### AudioManager (Autoload)

```gdscript
# addons/g4_audio/autoloads/audio_manager.gd
extends Node

## Global audio system coordinator
## Access via: AudioManager.play_event(event)

# Signals
signal parameter_changed(param_name: String, value: float)
signal beat(beat_number: int)
signal bar(bar_number: int)

# Object pools
var _pool_2d: AudioPool
var _pool_3d: AudioPool

# Parameters
var _parameters: Dictionary = {}

# BPM Clock
var _bpm: float = 120.0
var _is_clock_running: bool = false

func _ready():
    # Initialize pools
    _pool_2d = AudioPool.new(AudioPool.PoolType.POOL_2D, 50)
    _pool_3d = AudioPool.new(AudioPool.PoolType.POOL_3D, 30)
    add_child(_pool_2d)
    add_child(_pool_3d)

## Play an AudioEvent at a position
func play_event(event: AudioEvent, position: Vector2 = Vector2.ZERO) -> bool:
    if not event or not event.is_valid():
        return false

    # Check cooldown
    if not event.can_play():
        return false

    # Get player from pool
    var player = _pool_2d.acquire()
    if not player:
        return false

    # Configure player
    player.stream = event.get_random_stream()
    player.volume_db = event.get_random_volume_db()
    player.pitch_scale = event.get_random_pitch()
    player.bus = event.bus_name
    player.position = position

    # Play
    player.play()
    event.mark_played()

    return true

## Set a parameter value
func set_parameter(name: String, value: float):
    if not _parameters.has(name):
        push_warning("Parameter '%s' not found" % name)
        return

    var param: AudioParameter = _parameters[name]
    param.set_value(value)
    parameter_changed.emit(name, value)

## Get a parameter value
func get_parameter(name: String) -> float:
    if _parameters.has(name):
        return _parameters[name].current_value
    return 0.0

## Create a new parameter
func create_parameter(name: String, min_val: float, max_val: float, default: float) -> AudioParameter:
    var param = AudioParameter.new()
    param.parameter_name = name
    param.min_value = min_val
    param.max_value = max_val
    param.default_value = default
    param.current_value = default

    _parameters[name] = param
    return param
```

### MusicManager (Autoload)

```gdscript
# addons/g4_audio/autoloads/music_manager.gd
extends Node

## Global music system
## Access via: MusicManager.play_music(music_event)

signal music_started(music_name: String)
signal music_stopped(music_name: String)
signal stem_toggled(stem_name: String, enabled: bool)

var current_music: MusicEvent = null
var _stem_players: Array[AudioStreamPlayer] = []

## Play a music event
func play_music(music: MusicEvent, fade_in: float = 0.0) -> bool:
    if not music:
        return false

    # Stop current music
    if current_music:
        stop_music()

    # Create players for each stem
    _stem_players.clear()

    for stem in music.stems:
        var player = AudioStreamPlayer.new()
        player.stream = stem.stream
        player.volume_db = stem.volume_offset
        player.bus = "Music"
        add_child(player)

        if stem.default_enabled:
            player.play()
        else:
            player.volume_db = -80.0  # Muted
            player.play()

        _stem_players.append(player)

    current_music = music
    music_started.emit(music.music_name)

    return true

## Enable or disable a stem
func set_stem_enabled(stem_name: String, enabled: bool, fade_time: float = 1.0):
    if not current_music:
        return

    # Find stem index
    var stem_idx = -1
    for i in range(current_music.stems.size()):
        if current_music.stems[i].stem_name == stem_name:
            stem_idx = i
            break

    if stem_idx == -1:
        return

    # Fade player volume
    var player = _stem_players[stem_idx]
    var target_volume = 0.0 if enabled else -80.0

    var tween = create_tween()
    tween.tween_property(player, "volume_db", target_volume, fade_time)

    stem_toggled.emit(stem_name, enabled)
```

### Project Settings Autoload Configuration:
```
Project → Project Settings → Autoload:
├─ AudioManager: res://addons/g4_audio/autoloads/audio_manager.gd
└─ MusicManager: res://addons/g4_audio/autoloads/music_manager.gd
```

---

## 🔧 4. Editor Plugins (Split into Multiple Tools)

### Instead of One Big Tab, Create:

#### 4.1 Audio Browser Dock (Bottom Dock)

```gdscript
# Like Animation panel - sits at bottom
extends Control

var _tree: Tree

func _ready():
    # Browser showing all audio events
    _tree = Tree.new()
    _tree.columns = 2
    _tree.column_titles_visible = true
    _tree.set_column_title(0, "Event")
    _tree.set_column_title(1, "Type")

    # Double-click to edit
    _tree.item_activated.connect(_on_item_activated)

# Register in plugin
func _enter_tree():
    var audio_browser = AudioBrowserDock.new()
    add_control_to_bottom_panel(audio_browser, "Audio Events")
```

**Where it goes:**
```
┌─────────────────────────────────────────┐
│  Godot Editor                           │
│  ┌───────────────────────────────────┐  │
│  │  3D Viewport                      │  │
│  │                                   │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │ [Scene] [Import] [Audio Events]  │  │ ← Bottom Dock
│  │  🎵 Footstep.tres                 │  │
│  │  🎵 Explosion.tres                │  │
│  │  🎚️ CarEngine.tres                │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

#### 4.2 Inspector Plugin (Right Panel)

```gdscript
# Custom inspector for audio resources
extends EditorInspectorPlugin

func _can_handle(object):
    return object is AudioEvent or object is LayeredAudioEvent or object is MusicEvent

func _parse_begin(object):
    # Add test button at top
    var test_button = Button.new()
    test_button.text = "▶ Test Audio"
    test_button.pressed.connect(func(): _test_audio(object))
    add_custom_control(test_button)

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
    # Custom editors for complex properties
    if name == "streams":
        var stream_editor = StreamArrayEditor.new()
        stream_editor.event = object
        add_property_editor(name, stream_editor)
        return true

    return false
```

**Where it goes:**
```
┌─────────────────────────────────────────┐
│  Inspector                       │ ← Right Panel
│  ┌─────────────────────────────┐ │
│  │ AudioEvent (footstep.tres)  │ │
│  │ [▶ Test Audio] [■ Stop]     │ │  ← Custom controls
│  │                             │ │
│  │ Event Name: Footstep        │ │
│  │ Category: SFX/Player        │ │
│  │                             │ │
│  │ Streams (3):                │ │
│  │ ┌─────────────────────────┐ │ │
│  │ │ 🎵 footstep1.wav        │ │ │
│  │ │ 🎵 footstep2.wav        │ │ │  ← Custom editor
│  │ │ 🎵 footstep3.wav        │ │ │
│  │ │ [+ Add...]              │ │ │
│  │ └─────────────────────────┘ │ │
│  └─────────────────────────────┘ │
└─────────────────────────────────────────┘
```

#### 4.3 Scene Editor Tools (Toolbar)

```gdscript
# Add audio-specific tools to 3D/2D editor toolbar
extends EditorPlugin

func _enter_tree():
    # Add to 3D editor toolbar
    add_control_to_container(
        CONTAINER_SPATIAL_EDITOR_MENU,
        create_audio_tools_menu()
    )

func create_audio_tools_menu() -> MenuButton:
    var menu = MenuButton.new()
    menu.text = "Audio Tools"
    menu.icon = get_editor_interface().get_base_control().get_theme_icon("AudioStreamPlayer3D", "EditorIcons")

    var popup = menu.get_popup()
    popup.add_item("Place Audio Event Player", 0)
    popup.add_item("Place Music Player", 1)
    popup.add_item("Place Reverb Zone", 2)
    popup.add_item("Place Occlusion Volume", 3)

    return menu
```

**Where it goes:**
```
┌─────────────────────────────────────────────────────┐
│ [3D] [Select] [Move] [Rotate] [Audio Tools ▼]      │ ← Toolbar
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │  3D Viewport                                  │ │
│  │                                               │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

#### 4.4 Optional: Advanced Mixer Tab

```gdscript
# Only for advanced users who want full control
# This is your original "Audio Mixer" main screen tab
func _has_main_screen() -> bool:
    return true  # But it's optional!

func _get_plugin_name() -> String:
    return "Audio Mixer"
```

**When to use:**
- Creating/editing many events at once
- Batch operations
- Advanced parameter setup
- Visual crossfade editing
- Timeline editing for music

---

## 📊 Comparison: Before vs After

### ❌ OLD APPROACH (Everything in One Tab):
```
One massive "Audio Mixer" tab with:
├─ Event browser
├─ Property editors
├─ Test controls
├─ Parameter sliders
├─ Profiler
├─ BPM controls
└─ Everything else...

Problems:
- Overwhelming for beginners
- Not how Godot works
- Can't use while editing scenes
- Separate from normal workflow
```

### ✅ NEW APPROACH (Distributed):
```
Resources:
├─ Create in FileSystem: Right-click → New Resource
├─ Edit in Inspector: Select .tres file
└─ Test in Inspector: Custom "Test" button

Nodes:
├─ Add to Scene: Add Node → AudioEventPlayer3D
├─ Configure in Inspector: Like any other node
└─ Connect in Scene: Drag event resource to node

Singletons:
├─ AudioManager: Always available
└─ MusicManager: Always available

Editor Tools:
├─ Audio Events dock (bottom): Browse/manage events
├─ Audio Tools menu (toolbar): Quick node placement
└─ Audio Mixer tab (optional): Advanced operations

Benefits:
✅ Familiar Godot workflow
✅ Use while editing scenes
✅ Inspector shows relevant info
✅ Gradual complexity
✅ Separate concerns
```

---

## 🎯 Developer Workflows

### Workflow 1: Creating a Simple Sound Effect

**Designer (no code):**
1. FileSystem → Right-click → New Resource → AudioEvent
2. Name it `footstep.tres`
3. Inspector → Drag 3 WAV files to "Streams"
4. Set Volume Range: -3 to 0 dB
5. Set Pitch Range: 0.95 to 1.05
6. Click "▶ Test Audio" button in Inspector
7. Save (Ctrl+S)

**Developer (code):**
```gdscript
# In player script
@onready var footstep_event = preload("res://audio/footstep.tres")

func _on_footstep():
    AudioManager.play_event(footstep_event, global_position)
```

**OR with nodes (no code):**
```
Player
└─ FootstepPlayer (AudioEventPlayer3D)
    └─ event: res://audio/footstep.tres

# Call from animation or code:
$FootstepPlayer.play()
```

### Workflow 2: Setting Up Music

**Designer:**
1. Create Resource → MusicEvent → `combat_music.tres`
2. Set BPM: 140
3. Add 4 stems (Drums, Bass, Melody, Intensity)
4. Set "Intensity" stem to parameter-controlled
5. Test in Inspector

**Developer:**
```
Scene: BattleArena
└─ CombatMusic (MusicPlayer)
    ├─ music: res://music/combat_music.tres
    └─ autoplay: true

# In game script:
func _on_enemy_spotted():
    AudioManager.set_parameter("combat_intensity", 1.0)
    # Intensity stem automatically fades in!
```

### Workflow 3: Creating Audio Zones

**Level Designer (visual):**
1. Scene Editor → Add Node → AudioZone3D
2. Name it "CaveReverb"
3. Inspector → Set Effect Type: Reverb
4. Inspector → Set Preset: CAVE
5. Add CollisionShape3D child → Size it to cave bounds
6. Done! Players entering get reverb automatically

---

## 🚀 Implementation Priority

### Phase 1: Core (Week 1-2)
```
✅ Resources:
   - AudioEvent.gd
   - LayeredAudioEvent.gd
   - MusicEvent.gd

✅ Singletons:
   - AudioManager (basic pooling + playback)
   - MusicManager (basic music)

✅ One Node:
   - AudioEventPlayer3D (simplest)
```

### Phase 2: Editor Integration (Week 3)
```
✅ Inspector Plugin:
   - Custom property editors
   - Test button

✅ Bottom Dock:
   - Event browser
   - Simple tree view
```

### Phase 3: More Nodes (Week 4)
```
✅ AudioEventPlayer2D
✅ MusicPlayer
✅ AudioParameterDriver
```

### Phase 4: Advanced (Week 5+)
```
✅ AudioZone3D
✅ Advanced mixer tab (optional)
✅ Scene editor tools
```

---

## 📝 Summary: Distributed Architecture

| Component | Where | Purpose |
|-----------|-------|---------|
| **AudioEvent** | Resource file (.tres) | Sound definition |
| **AudioEventPlayer3D** | Scene node | Play event at position |
| **AudioManager** | Autoload singleton | Global coordination |
| **Inspector Plugin** | Right panel | Edit resources |
| **Audio Browser** | Bottom dock | Browse events |
| **Audio Mixer Tab** | Main screen (optional) | Advanced operations |

**Result:** Feels like Godot built it! 🎮

---

## ✅ Next Steps

Should I:
1. **Create the full file structure** with all nodes, singletons, and plugins?
2. **Implement AudioEventPlayer3D** as the first node example?
3. **Build the Inspector Plugin** for resource editing?
4. **Create the distributed architecture diagram** in more detail?
5. **Write a migration guide** from the old single-tab approach?

This architecture properly separates concerns the Godot way!
