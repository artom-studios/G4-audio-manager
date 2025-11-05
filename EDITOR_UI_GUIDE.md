# Audio Mixer Editor UI - Complete Workflow Guide

## 🎯 Overview

The Audio Mixer tab is a **complete, standalone audio editor** where sound designers can create, edit, test, and save audio events without ever leaving the tab. No need to use FileSystem or Inspector docks!

## 📐 Layout

The editor uses a professional 3-panel layout:

```
┌────────────────────────────────────────────────────────────────┐
│  Audio Mixer Tab                                                │
├──────────────┬───────────────────────────────┬──────────────────┤
│              │                                │                  │
│  LEFT PANEL  │      CENTER PANEL              │   RIGHT PANEL    │
│              │                                │                  │
│  Event       │  Custom Property Editor        │   Playback       │
│  Browser     │  (Based on event type)         │   Controls       │
│              │                                │                  │
│  - Tree view │  📑 Properties Tab             │   ▶ Play         │
│  - Search    │  🎚 Layers Tab (Layered)      │   ■ Stop         │
│  - Create    │  🎼 Stems Tab (Music)          │                  │
│  - Delete    │  📸 Snapshot Tab               │   Parameter      │
│  - Refresh   │                                │   Sliders        │
│              │  All properties editable here! │                  │
│              │                                │   Stats &        │
│              │  💾 Save button at top         │   BPM Sync       │
│              │                                │                  │
└──────────────┴───────────────────────────────┴──────────────────┘
```

---

## 🎨 Complete Workflow (All in One Tab!)

### Step 1: Create a New Event

1. Open the **Audio Mixer** tab at the top of Godot
2. Click **"+ New Event"** dropdown in the left panel
3. Choose event type:
   - 🎵 Simple Audio Event
   - 🎚 Layered Event (for engines, ambiences)
   - 🎼 Music Event (for adaptive music with stems)
   - 📸 Mixer Snapshot (for mix states)
4. Enter event name and location
5. Click **OK**

**Result:** Event is created, saved, and immediately loaded in the editor!

### Step 2: Edit Properties

The **Center Panel** changes based on event type:

#### For Audio Events (Simple SFX):
```
Properties Tab Shows:
├─ Event Identity
│  ├─ Event Name
│  ├─ Category
│  └─ Description
├─ Audio Streams
│  ├─ Stream list (drag .wav/.ogg files)
│  └─ Playback Mode dropdown
├─ Randomization
│  ├─ Volume Range (Vector2)
│  └─ Pitch Range (Vector2)
├─ Playback Control
│  ├─ Max Concurrent Instances
│  ├─ Priority dropdown
│  ├─ Cooldown Time
│  ├─ Fade In/Out Duration
└─ Spatial Audio
   ├─ Spatial Mode (2D/3D)
   ├─ Max Distance
   └─ Unit Size
```

#### For Layered Events (Engines/Ambiences):
```
Layers Tab Shows:
├─ Event Settings
│  ├─ Event Name
│  ├─ Control Parameter
│  ├─ Crossfade Time
│  └─ Pitch Follows Parameter checkbox
├─ Audio Layers
│  └─ For each layer:
│     ├─ Name
│     ├─ Parameter Range (min, max)
│     ├─ Volume Offset
│     ├─ Pitch Offset
│     ├─ Looping checkbox
│     ├─ Enabled checkbox
│     └─ ✖ Remove button
└─ + Add Layer button
```

####For Music Events (Adaptive Music):
```
Stems Tab Shows:
├─ Music Settings
│  ├─ Music Name
│  ├─ BPM
│  ├─ Beats Per Bar
│  └─ Loop checkbox
├─ Music Stems
│  └─ For each stem:
│     ├─ Name
│     ├─ Default Enabled checkbox
│     ├─ Volume Offset
│     ├─ Control Parameter
│     ├─ Parameter Range
│     ├─ Fade Time
│     └─ ✖ Remove button
└─ + Add Stem button
```

### Step 3: Test Playback

**Right Panel** provides real-time testing:

```
▶ Playback Controls
├─ ▶ Play button (big green button)
├─ ■ Stop button
└─ Status: "Playing..." or "Ready"

🎚 Parameter Control
├─ Auto-detected parameters from event
├─ Real-time sliders (0.0 - 1.0)
└─ Live value display

📊 System Stats
├─ Pool statistics
├─ Active players
├─ BPM controls
└─ Beat counter
```

**How to test:**
1. Click **▶ Play** in the right panel
2. For layered/music events: **Move the parameter sliders** to hear crossfades
3. Watch the status indicator
4. Click **■ Stop** when done

### Step 4: Save

Click **💾 Save** button in the center panel header.

**Done!** Event is saved and immediately usable by developers.

---

## 🎯 Example Workflows

### Workflow 1: Creating a Gunshot Sound

1. **Create:**
   - Click "+ New Event" → "🎵 Simple Audio Event"
   - Name: `pistol_fire`
   - Location: `res://audio_events/sfx/weapons/`

2. **Edit (Center Panel):**
   - Event Name: "Pistol Fire"
   - Audio Streams: Drag `gunshot1.wav`, `gunshot2.wav`, `gunshot3.wav`
   - Playback Mode: "Random One"
   - Volume Range: X: `-3.0`, Y: `0.0`
   - Pitch Range: X: `0.92`, Y: `1.08`
   - Max Concurrent Instances: `5`
   - Spatial Mode: "3D"
   - Bus Name: "SFX"

3. **Test (Right Panel):**
   - Click **▶ Play** multiple times
   - Each click = different variation!

4. **Save:**
   - Click **💾 Save**

### Workflow 2: Creating a Car Engine (Layered)

1. **Create:**
   - Click "+ New Event" → "🎚 Layered Event"
   - Name: `car_engine`

2. **Edit (Center Panel - Layers Tab):**

   **Event Settings:**
   - Event Name: "Car Engine"
   - Control Parameter: `engine_rpm`
   - Crossfade Time: `0.3`
   - Pitch Follows Parameter: ✓

   **Click "+ Add Layer" 3 times:**

   **Layer 0:**
   - Name: "Idle"
   - Parameter Range: X: `0.0`, Y: `0.3`
   - Volume Offset: `0.0`
   - Looping: ✓

   **Layer 1:**
   - Name: "Mid RPM"
   - Parameter Range: X: `0.2`, Y: `0.7`
   - Volume Offset: `-2.0`
   - Looping: ✓

   **Layer 2:**
   - Name: "High RPM"
   - Parameter Range: X: `0.6`, Y: `1.0`
   - Volume Offset: `-3.0`
   - Looping: ✓

3. **Test (Right Panel):**
   - Click **▶ Play**
   - **Move the `engine_rpm` slider** from 0.0 to 1.0
   - Listen to layers smoothly crossfade!

4. **Save:**
   - Click **💾 Save**

### Workflow 3: Creating Adaptive Combat Music

1. **Create:**
   - Click "+ New Event" → "🎼 Music Event"
   - Name: `combat_music`

2. **Edit (Center Panel - Stems Tab):**

   **Music Settings:**
   - Music Name: "Combat Music"
   - BPM: `140.0`
   - Beats Per Bar: `4`
   - Loop: ✓

   **Click "+ Add Stem" 3 times:**

   **Stem 0: Drums**
   - Name: "Drums"
   - Default Enabled: ✓
   - Volume Offset: `0.0`
   - Control Parameter: *(leave empty)*

   **Stem 1: Bass**
   - Name: "Bass"
   - Default Enabled: ✓
   - Volume Offset: `-3.0`
   - Control Parameter: *(leave empty)*

   **Stem 2: Intensity**
   - Name: "Intensity"
   - Default Enabled: ✗
   - Volume Offset: `0.0`
   - Control Parameter: `combat_intensity`
   - Parameter Range: X: `0.5`, Y: `1.0`
   - Fade Time: `2.0`

3. **Test (Right Panel):**
   - Click **▶ Play**
   - **Move the `combat_intensity` slider**
   - Hear the intensity stem fade in/out!

4. **Save:**
   - Click **💾 Save**

---

## 🎨 UI Features

### Left Panel Features

**Event Browser:**
- **Tree View**: Hierarchical organization matching folder structure
- **Search Bar**: Type to filter events instantly
- **Icons**: Different icons for each event type
- **Type Column**: Shows event type at a glance

**Toolbar:**
- **+ New Event**: Dropdown menu for creating events
- **🗑 Delete**: Remove selected event (with confirmation)
- **🔄 Refresh**: Reload event list from disk

### Center Panel Features

**Header:**
- **Event Icon**: Visual indicator of event type
- **Event Name**: Current event being edited
- **💾 Save Button**: Save changes to disk

**Tabbed Editor:**
- Different tabs appear based on event type
- All properties exposed in intuitive groups
- Real-time editing (changes apply immediately to the resource)
- Visual organization with section headers

**Property Types:**
- Text fields: Event names, categories, descriptions
- Number fields: BPM, volume, pitch, etc.
- Vector2 fields: Ranges with X/Y controls
- Dropdowns: Enums, bus names, playback modes
- Checkboxes: Boolean options
- Lists: Layers, stems with add/remove buttons

### Right Panel Features

**Playback Controls:**
- **Large buttons**: Easy to click ▶ Play and ■ Stop
- **Status indicator**: Visual feedback (green = playing)
- **One-click testing**: No need to run the game!

**Parameter Control:**
- **Auto-detection**: Finds all parameters used by current event
- **Real-time sliders**: 0.0 to 1.0 range with live value display
- **Instant feedback**: Hear changes immediately during playback
- **No Params Label**: Shows when event doesn't use parameters

**System Stats:**
- **Pool statistics**: See available/active players
- **Real-time updates**: Refreshes every 300ms
- **BPM controls**: Set global BPM for testing
- **Beat counter**: Visual beat/bar display with flash feedback

---

## 💡 Tips & Best Practices

### Organization
- Use the folder structure: `sfx/`, `music/`, `ui/`, `ambient/`
- Use categories: "SFX/Player", "Music/Combat", etc.
- Name consistently: `weapon_pistol_fire`, `ui_button_click`

### Editing
- **Edit properties in the center panel** - all changes are live!
- **Save frequently** with Ctrl+S or the Save button
- **Test as you go** - click Play after each change
- Changes apply immediately to the resource in memory

### Parameter Design
- **Layered Events**: Design overlapping parameter ranges for smooth crossfades
  - Example: Layer 1 (0.0-0.4), Layer 2 (0.3-0.7), Layer 3 (0.6-1.0)
- **Music Events**: Use meaningful parameter names: `combat_intensity`, `stealth_level`
- **Test with sliders**: Move sliders slowly to hear crossfade behavior

### Testing
- **Simple events**: Click Play multiple times to hear variations
- **Layered events**: Play once, then move parameter sliders
- **Music events**: Play and control stem parameters in real-time
- **Check stats**: Monitor pool usage and active sounds

---

## 🔧 Keyboard Shortcuts

- **Ctrl+S**: Save current event
- **Ctrl+F**: Focus search bar (when implemented)
- **Delete**: Delete selected event (when implemented)
- **Ctrl+N**: New event (when implemented)

---

## ❓ FAQ

**Q: Do I need to use FileSystem or Inspector docks?**
A: No! Everything is in the Audio Mixer tab.

**Q: How do I add audio files to streams?**
A: Currently: Use Inspector dock to drag files (V1 limitation)
   Coming: Drag-and-drop directly in Audio Mixer tab

**Q: Can I edit multiple events at once?**
A: No, select one event at a time from the tree

**Q: Where are events saved?**
A: Default: `res://audio_events/` folder
   You can choose custom location when creating

**Q: Can I rename/move events?**
A: Use FileSystem dock for file operations (rename/move)
   Or delete and recreate with new name/location

**Q: How do I know if changes are saved?**
A: Status shows "✅ Saved!" after clicking Save button
   Unsaved changes will be lost if you select another event!

**Q: Can I test events without AudioController running?**
A: No, AudioController must be registered as autoload
   Plugin will show warnings if it's missing

**Q: What if I can't hear sound during testing?**
A: Check:
   - AudioController is in autoload
   - Audio bus exists in AudioServer
   - System audio is on
   - Event has valid streams assigned

---

## 🎯 Developer Integration

Sound designers create and save events in the Audio Mixer tab.

Developers just load and play them:

```gdscript
# Load event (assign in Inspector or via code)
@export var pistol_fire: AudioEvent
@export var car_engine: LayeredAudioEvent
@export var combat_music: MusicEvent

# Play simple event
AudioController.play_event(pistol_fire, gun_position)

# Play layered event and control parameter
AudioController.play_layered_event(car_engine)
AudioController.set_parameter("engine_rpm", current_rpm / max_rpm)

# Play music
MusicManager.play_music(combat_music, 2.0)
AudioController.set_parameter("combat_intensity", 0.8)
```

**Result:** Complete separation of concerns:
- Sound designers work in Audio Mixer tab
- Developers just play events and update parameters
- No coordination needed for property changes!

---

**The Audio Mixer tab is your complete audio design workspace! 🎵🎮**
