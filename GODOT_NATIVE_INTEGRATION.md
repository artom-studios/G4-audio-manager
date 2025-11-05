# Godot-Native Integration Guide
## Making G4 Audio Feel Like a Built-In Feature

---

## 🎯 Philosophy: "It Should Feel Like Godot Built It"

Users should not be able to tell where Godot ends and your plugin begins.

### Core Principles:
1. **Use Godot's UI Theme** - Don't create custom colors/fonts
2. **Follow Godot's Conventions** - Naming, shortcuts, behaviors
3. **Integrate Deeply** - Use FileSystem, Inspector, Scene Tree
4. **Match Godot's UX** - How things work, not just how they look
5. **Respect User Settings** - Editor scale, theme, shortcuts

---

## 🎨 Visual Integration

### 1. Use Godot's Editor Theme

**❌ DON'T DO THIS:**
```gdscript
# Custom colors that clash with theme
label.add_theme_color_override("font_color", Color.RED)
button.modulate = Color(0.2, 0.5, 1.0)
```

**✅ DO THIS:**
```gdscript
# Use theme colors from the editor
var editor_theme = EditorInterface.get_editor_theme()

# Get colors that match the current theme
var font_color = editor_theme.get_color("font_color", "Editor")
var accent_color = editor_theme.get_color("accent_color", "Editor")
var base_color = editor_theme.get_color("base_color", "Editor")
var dark_color_1 = editor_theme.get_color("dark_color_1", "Editor")
var dark_color_2 = editor_theme.get_color("dark_color_2", "Editor")
var contrast_color_1 = editor_theme.get_color("contrast_color_1", "Editor")

# Apply to your UI
label.add_theme_color_override("font_color", font_color)
panel.add_theme_stylebox_override("panel", editor_theme.get_stylebox("panel", "Panel"))
```

### 2. Use Godot's Built-In Icons

**Godot has 600+ built-in icons** - use them!

```gdscript
# Get editor interface
var editor = get_editor_interface()
var base_control = editor.get_base_control()

# Get icons that match any theme
var play_icon = base_control.get_theme_icon("Play", "EditorIcons")
var stop_icon = base_control.get_theme_icon("Stop", "EditorIcons")
var add_icon = base_control.get_theme_icon("Add", "EditorIcons")
var remove_icon = base_control.get_theme_icon("Remove", "EditorIcons")
var folder_icon = base_control.get_theme_icon("Folder", "EditorIcons")
var file_icon = base_control.get_theme_icon("File", "EditorIcons")
var audio_icon = base_control.get_theme_icon("AudioStreamPlayer", "EditorIcons")
var search_icon = base_control.get_theme_icon("Search", "EditorIcons")
var settings_icon = base_control.get_theme_icon("Tools", "EditorIcons")
var refresh_icon = base_control.get_theme_icon("Reload", "EditorIcons")
var save_icon = base_control.get_theme_icon("Save", "EditorIcons")
var duplicate_icon = base_control.get_theme_icon("Duplicate", "EditorIcons")
var visibility_icon = base_control.get_theme_icon("GuiVisibilityVisible", "EditorIcons")
var hidden_icon = base_control.get_theme_icon("GuiVisibilityHidden", "EditorIcons")

# Apply to buttons
play_button.icon = play_icon
stop_button.icon = stop_icon
add_button.icon = add_icon
```

**Useful Icon Names:**
```
Interface:
- "Play", "Stop", "Pause", "Forward", "Back"
- "Add", "Remove", "Clear", "Edit", "Duplicate"
- "Save", "Load", "Reload", "Import", "Export"
- "Search", "Filter", "Sort"
- "Folder", "File", "FolderBrowse"
- "GuiVisibilityVisible", "GuiVisibilityHidden"
- "Lock", "Unlock"
- "ZoomMore", "ZoomLess", "ZoomReset"

Audio:
- "AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D"
- "AudioBusLayout", "AudioListener2D", "AudioListener3D"

Node Types:
- "Node", "Node2D", "Node3D"
- "Control", "Container", "Panel"
- "Label", "Button", "LineEdit"

Status:
- "StatusSuccess", "StatusWarning", "StatusError"
- "GuiChecked", "GuiUnchecked"
- "GuiRadioChecked", "GuiRadioUnchecked"

Tools:
- "Tools", "Settings", "Help"
- "Script", "ScriptCreate"
- "AnimationPlayer", "AnimationTree"
```

**How to Find Icons:**
```gdscript
# Print all available icons (run in editor)
func print_all_icons():
    var base_control = get_editor_interface().get_base_control()
    var theme = base_control.get_theme()
    var icon_list = theme.get_icon_list("EditorIcons")

    print("Available icons: ", icon_list.size())
    for icon_name in icon_list:
        if "Audio" in icon_name or "Sound" in icon_name:
            print("  - ", icon_name)
```

### 3. Use Godot's StyleBoxes

```gdscript
# Get common styleboxes
var editor_theme = EditorInterface.get_editor_theme()

# Panel backgrounds
var panel_style = editor_theme.get_stylebox("panel", "Panel")
var bg_style = editor_theme.get_stylebox("Background", "EditorStyles")

# Buttons
var button_normal = editor_theme.get_stylebox("normal", "Button")
var button_pressed = editor_theme.get_stylebox("pressed", "Button")
var button_hover = editor_theme.get_stylebox("hover", "Button")

# Tree items
var tree_selected = editor_theme.get_stylebox("selected", "Tree")
var tree_selected_focus = editor_theme.get_stylebox("selected_focus", "Tree")

# Apply to your controls
my_panel.add_theme_stylebox_override("panel", panel_style)
my_button.add_theme_stylebox_override("normal", button_normal)
my_button.add_theme_stylebox_override("pressed", button_pressed)
my_button.add_theme_stylebox_override("hover", button_hover)
```

### 4. Respect Editor Scale

```gdscript
# Get editor scale (100%, 125%, 150%, 200%)
var editor_scale = EditorInterface.get_editor_scale()

# Scale your UI elements
var base_size = 16  # Base icon size
var scaled_size = base_size * editor_scale

# Scale margins and padding
var base_margin = 8
var scaled_margin = base_margin * editor_scale

# Scale font sizes
var base_font_size = 14
var scaled_font_size = base_font_size * editor_scale

# Apply to your UI
icon.custom_minimum_size = Vector2(scaled_size, scaled_size)
margin_container.add_theme_constant_override("margin_left", scaled_margin)
label.add_theme_font_size_override("font_size", scaled_font_size)
```

### 5. Match Godot's Layout Spacing

```gdscript
# Godot's standard spacing
const SPACING_SMALL = 4   # Between related items
const SPACING_MEDIUM = 8  # Between sections
const SPACING_LARGE = 16  # Between major groups

# Apply with editor scale
var spacing_small = SPACING_SMALL * EditorInterface.get_editor_scale()
var spacing_medium = SPACING_MEDIUM * EditorInterface.get_editor_scale()
var spacing_large = SPACING_LARGE * EditorInterface.get_editor_scale()

# Use in containers
vbox.add_theme_constant_override("separation", spacing_medium)
margin_container.add_theme_constant_override("margin_left", spacing_medium)
margin_container.add_theme_constant_override("margin_right", spacing_medium)
margin_container.add_theme_constant_override("margin_top", spacing_medium)
margin_container.add_theme_constant_override("margin_bottom", spacing_medium)
```

---

## 🔧 Integration with Godot Systems

### 1. FileSystem Integration

**Let users drag files from Godot's FileSystem dock:**

```gdscript
extends Control

func _ready():
    # Enable dropping
    set_drag_forwarding(Callable(), _can_drop_data_fw, _drop_data_fw)

func _can_drop_data_fw(at_position: Vector2, data) -> bool:
    # Check if dropping files
    if typeof(data) == TYPE_DICTIONARY and data.has("files"):
        var files = data["files"]

        # Check if all files are audio
        for file in files:
            if not _is_audio_file(file):
                return false

        return true

    return false

func _drop_data_fw(at_position: Vector2, data) -> void:
    if typeof(data) == TYPE_DICTIONARY and data.has("files"):
        var files = data["files"]

        for file in files:
            if _is_audio_file(file):
                _add_audio_stream(file)

func _is_audio_file(path: String) -> bool:
    var ext = path.get_extension().to_lower()
    return ext in ["wav", "ogg", "mp3"]

func _add_audio_stream(path: String):
    var stream = load(path)
    if stream is AudioStream:
        current_event.streams.append(stream)
        _refresh_stream_list()
```

**Show files in FileSystem context menu:**

```gdscript
# In your EditorPlugin
func _enter_tree():
    # Add to FileSystem context menu
    var filesystem_dock = get_editor_interface().get_file_system_dock()
    filesystem_dock.files_moved.connect(_on_files_moved)
    filesystem_dock.file_removed.connect(_on_file_removed)

func _on_files_moved(old_file: String, new_file: String):
    # Update any events that reference the old file
    _update_event_references(old_file, new_file)

func _on_file_removed(file: String):
    # Warn if any events use this file
    _check_broken_references(file)
```

### 2. Inspector Integration

**Make your resources editable in the Inspector:**

```gdscript
# audio_event_inspector_plugin.gd
extends EditorInspectorPlugin

func _can_handle(object):
    return object is AudioEvent

func _parse_begin(object):
    # Add custom UI above inspector properties
    var header = preload("res://addons/audio_mixer/ui/inspector_header.tscn").instantiate()
    header.event = object
    add_custom_control(header)

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
    # Customize how specific properties are displayed
    if name == "streams":
        var stream_editor = preload("res://addons/audio_mixer/ui/stream_array_editor.tscn").instantiate()
        stream_editor.event = object
        add_property_editor(name, stream_editor)
        return true  # Handled

    return false  # Use default

# Register in plugin
func _enter_tree():
    var inspector_plugin = AudioEventInspectorPlugin.new()
    add_inspector_plugin(inspector_plugin)
```

### 3. Scene Tree Integration

**Add custom nodes to the "Create New Node" dialog:**

```gdscript
# In your EditorPlugin
func _enter_tree():
    # Add custom node types
    add_custom_type(
        "AudioEventPlayer",  # Node name
        "Node",              # Base class
        preload("res://addons/audio_mixer/nodes/audio_event_player.gd"),
        preload("res://addons/audio_mixer/icons/audio_event_player.svg")
    )

    add_custom_type(
        "MusicPlayer",
        "Node",
        preload("res://addons/audio_mixer/nodes/music_player.gd"),
        preload("res://addons/audio_mixer/icons/music_player.svg")
    )

func _exit_tree():
    remove_custom_type("AudioEventPlayer")
    remove_custom_type("MusicPlayer")
```

### 4. Resource Creation Integration

**Add to "Create New Resource" menu:**

```gdscript
# Already done with custom types, but also add templates
func _get_plugin_icon():
    return get_editor_interface().get_base_control().get_theme_icon("AudioStreamPlayer", "EditorIcons")

# Make resources show up in quick search (Ctrl+Shift+O)
# This happens automatically when you use add_custom_type()
```

---

## ⌨️ Keyboard Shortcuts - Godot Style

### 1. Use Godot's Standard Shortcuts

```gdscript
# Match Godot's conventions
const SHORTCUTS = {
    "save": KEY_MASK_CTRL | KEY_S,           # Save
    "new": KEY_MASK_CTRL | KEY_N,            # New
    "duplicate": KEY_MASK_CTRL | KEY_D,      # Duplicate
    "delete": KEY_DELETE,                     # Delete
    "rename": KEY_F2,                         # Rename
    "search": KEY_MASK_CTRL | KEY_F,         # Search
    "copy": KEY_MASK_CTRL | KEY_C,           # Copy
    "paste": KEY_MASK_CTRL | KEY_V,          # Paste
    "undo": KEY_MASK_CTRL | KEY_Z,           # Undo
    "redo": KEY_MASK_CTRL | KEY_Y,           # Redo (Windows)
    "redo_alt": KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_Z,  # Redo (Mac)
    "select_all": KEY_MASK_CTRL | KEY_A,     # Select All
    "play": KEY_SPACE,                        # Play/Stop
}

func _input(event: InputEvent):
    if event is InputEventKey and event.pressed:
        # Check for shortcuts
        var key_combo = event.keycode
        if event.ctrl_pressed:
            key_combo |= KEY_MASK_CTRL
        if event.shift_pressed:
            key_combo |= KEY_MASK_SHIFT
        if event.alt_pressed:
            key_combo |= KEY_MASK_ALT

        match key_combo:
            SHORTCUTS["save"]:
                _on_save_pressed()
                accept_event()
            SHORTCUTS["new"]:
                _on_new_event()
                accept_event()
            SHORTCUTS["duplicate"]:
                _on_duplicate_pressed()
                accept_event()
            SHORTCUTS["search"]:
                search_bar.grab_focus()
                accept_event()
```

### 2. Register Editor Shortcuts Properly

```gdscript
# In your EditorPlugin
func _enter_tree():
    # Add shortcuts to Godot's shortcut system
    var shortcut_save = Shortcut.new()
    var event_save = InputEventKey.new()
    event_save.keycode = KEY_S
    event_save.ctrl_pressed = true
    shortcut_save.events = [event_save]

    save_button.shortcut = shortcut_save
    save_button.shortcut_in_tooltip = true  # Show in tooltip

func _build_shortcuts():
    # Create shortcuts that respect user's custom bindings
    # (This is advanced - check if user has customized shortcuts)
    pass
```

---

## 🎭 UI Behavior - Match Godot's UX

### 1. Use Godot's Confirmation Patterns

```gdscript
# For destructive actions, use ConfirmationDialog
func _on_delete_pressed():
    if not current_event:
        return

    # Create confirmation dialog
    var confirm = ConfirmationDialog.new()
    confirm.dialog_text = "Delete event '%s'?\nThis action cannot be undone." % current_event.event_name
    confirm.title = "Confirm Delete"
    confirm.ok_button_text = "Delete"
    confirm.cancel_button_text = "Cancel"

    # Use Godot's theme
    confirm.confirmed.connect(_delete_confirmed)

    add_child(confirm)
    confirm.popup_centered()

func _delete_confirmed():
    # Actually delete
    DirAccess.remove_absolute(current_event_path)
    current_event = null
    refresh_event_list()
```

### 2. Use Godot's File Dialogs

```gdscript
# Use EditorFileDialog for native feel
func _on_browse_audio_pressed():
    var file_dialog = EditorFileDialog.new()
    file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILES
    file_dialog.access = EditorFileDialog.ACCESS_RESOURCES
    file_dialog.add_filter("*.wav, *.ogg, *.mp3", "Audio Files")
    file_dialog.title = "Select Audio Files"

    file_dialog.files_selected.connect(_on_audio_files_selected)

    add_child(file_dialog)
    file_dialog.popup_centered_ratio(0.6)

func _on_audio_files_selected(paths: PackedStringArray):
    for path in paths:
        var stream = load(path)
        current_event.streams.append(stream)

    _refresh_stream_list()
```

### 3. Match Godot's Tree Behavior

```gdscript
# In your event tree
func _setup_tree():
    event_tree.columns = 2
    event_tree.hide_root = true
    event_tree.select_mode = Tree.SELECT_ROW
    event_tree.allow_rmb_select = true  # Right-click to select

    # Match Godot's tree styling
    var editor_theme = EditorInterface.get_editor_theme()
    event_tree.add_theme_stylebox_override("selected", editor_theme.get_stylebox("selected", "Tree"))
    event_tree.add_theme_stylebox_override("selected_focus", editor_theme.get_stylebox("selected_focus", "Tree"))
    event_tree.add_theme_color_override("title_button_color", editor_theme.get_color("font_color", "Tree"))

func _create_tree_item(parent: TreeItem, event: Resource) -> TreeItem:
    var item = event_tree.create_item(parent)

    # Column 0: Name with icon
    item.set_text(0, event.event_name)
    item.set_icon(0, _get_icon_for_event(event))
    item.set_metadata(0, event)

    # Column 1: Type
    item.set_text(1, _get_event_type_name(event))

    # Make it clickable
    item.set_selectable(0, true)
    item.set_selectable(1, true)

    return item
```

### 4. Use Godot's Context Menu Style

```gdscript
func _on_tree_item_rmb_clicked(position: Vector2):
    var item = event_tree.get_selected()
    if not item:
        return

    # Create context menu
    var context_menu = PopupMenu.new()

    # Use Godot's theme
    var editor_theme = EditorInterface.get_editor_theme()
    context_menu.add_theme_stylebox_override("panel", editor_theme.get_stylebox("panel", "PopupMenu"))

    # Add items with icons
    var base_control = get_editor_interface().get_base_control()
    context_menu.add_icon_item(base_control.get_theme_icon("Edit", "EditorIcons"), "Edit", 0)
    context_menu.add_icon_item(base_control.get_theme_icon("Duplicate", "EditorIcons"), "Duplicate", 1)
    context_menu.add_icon_item(base_control.get_theme_icon("ActionCopy", "EditorIcons"), "Copy Path", 2)
    context_menu.add_separator()
    context_menu.add_icon_item(base_control.get_theme_icon("Remove", "EditorIcons"), "Delete", 3)

    # Connect signal
    context_menu.id_pressed.connect(_on_context_menu_selected)

    add_child(context_menu)
    context_menu.popup(Rect2(position, Vector2.ZERO))
```

---

## 📦 Resource Handling - Godot Way

### 1. Use Resource UIDs

```gdscript
# Always save resources with UIDs for proper tracking
func _save_event(event: AudioEvent, path: String):
    # Godot 4 automatically handles UIDs
    var err = ResourceSaver.save(event, path)

    if err != OK:
        push_error("Failed to save event: %s" % error_string(err))
        return false

    # Force filesystem rescan
    EditorInterface.get_resource_filesystem().scan()

    return true

# When loading, use UIDs so references don't break
func _load_event(path: String) -> AudioEvent:
    var event = load(path)

    if not event is AudioEvent:
        push_error("File is not an AudioEvent: %s" % path)
        return null

    return event
```

### 2. Handle Resource Changes

```gdscript
# Watch for external changes
func _enter_tree():
    var filesystem = EditorInterface.get_resource_filesystem()
    filesystem.resources_reimported.connect(_on_resources_reimported)
    filesystem.resources_reload.connect(_on_resources_reload)

func _on_resources_reimported(resources: PackedStringArray):
    # Check if any audio files were reimported
    for res_path in resources:
        if _is_audio_file(res_path):
            # Refresh UI for events using this audio
            _refresh_events_using_audio(res_path)

func _on_resources_reload(resources: PackedStringArray):
    # Reload events if their files changed externally
    if current_event_path in resources:
        _reload_current_event()
```

### 3. Show Resources in Project Manager

```gdscript
# Make your resources searchable in Godot
# This happens automatically with proper Resource setup

# But you can add custom thumbnails
func _generate_thumbnail(event: AudioEvent) -> Image:
    # Generate a visual representation of the event
    # This shows up in FileSystem dock
    var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)

    # Draw waveform or icon
    # ... drawing code ...

    return img
```

---

## 🎬 Editor Main Screen Integration

### 1. Proper Tab Registration

```gdscript
# In your EditorPlugin
func _has_main_screen() -> bool:
    return true

func _make_visible(visible: bool) -> void:
    if audio_mixer_ui:
        audio_mixer_ui.visible = visible

func _get_plugin_name() -> String:
    return "Audio Mixer"  # Shows in tab

func _get_plugin_icon() -> Texture2D:
    # Use a built-in icon or custom SVG
    return get_editor_interface().get_base_control().get_theme_icon("AudioStreamPlayer", "EditorIcons")

# Make tab priority reasonable (not too high)
func _get_priority() -> int:
    return 50  # Lower than Script (100) and 2D/3D (200), but visible
```

### 2. Handle Tab Switching

```gdscript
# Pause heavy operations when tab not visible
func _make_visible(visible: bool):
    audio_mixer_ui.visible = visible

    if visible:
        # Resume updates
        _start_profiler_updates()
        _start_waveform_drawing()
    else:
        # Pause updates to save CPU
        _stop_profiler_updates()
        _stop_waveform_drawing()
```

---

## 🎨 Custom Theme Integration

### Complete Theme Setup Example

```gdscript
# theme_manager.gd
class_name AudioMixerTheme

static func apply_editor_theme(control: Control):
    var editor_interface = EditorInterface
    var editor_theme = editor_interface.get_editor_theme()
    var editor_scale = editor_interface.get_editor_scale()
    var base_control = editor_interface.get_base_control()

    # Colors
    var font_color = editor_theme.get_color("font_color", "Editor")
    var accent_color = editor_theme.get_color("accent_color", "Editor")
    var base_color = editor_theme.get_color("base_color", "Editor")
    var dark_color_1 = editor_theme.get_color("dark_color_1", "Editor")
    var dark_color_2 = editor_theme.get_color("dark_color_2", "Editor")

    # StyleBoxes
    var panel_style = editor_theme.get_stylebox("panel", "Panel")
    var bg_style = editor_theme.get_stylebox("Background", "EditorStyles")

    # Icons
    var icon_size = 16 * editor_scale

    # Apply recursively to all children
    _apply_theme_recursive(control, editor_theme, editor_scale)

static func _apply_theme_recursive(node: Node, theme: Theme, scale: float):
    if node is Control:
        var control = node as Control

        # Match Godot's control styling
        if control is Panel:
            control.add_theme_stylebox_override("panel", theme.get_stylebox("panel", "Panel"))

        elif control is Button:
            control.add_theme_stylebox_override("normal", theme.get_stylebox("normal", "Button"))
            control.add_theme_stylebox_override("pressed", theme.get_stylebox("pressed", "Button"))
            control.add_theme_stylebox_override("hover", theme.get_stylebox("hover", "Button"))
            control.add_theme_color_override("font_color", theme.get_color("font_color", "Button"))

        elif control is Label:
            control.add_theme_color_override("font_color", theme.get_color("font_color", "Label"))

        elif control is LineEdit:
            control.add_theme_stylebox_override("normal", theme.get_stylebox("normal", "LineEdit"))
            control.add_theme_stylebox_override("focus", theme.get_stylebox("focus", "LineEdit"))
            control.add_theme_color_override("font_color", theme.get_color("font_color", "LineEdit"))

        elif control is Tree:
            control.add_theme_stylebox_override("selected", theme.get_stylebox("selected", "Tree"))
            control.add_theme_stylebox_override("selected_focus", theme.get_stylebox("selected_focus", "Tree"))
            control.add_theme_color_override("font_color", theme.get_color("font_color", "Tree"))

    # Recurse to children
    for child in node.get_children():
        _apply_theme_recursive(child, theme, scale)
```

---

## 🔊 Audio Preview Integration

### Use Godot's Audio System Properly

```gdscript
# Don't create your own preview system - use the editor's
func _preview_audio_stream(stream: AudioStream):
    # Use EditorInterface's preview system
    var preview = get_editor_interface().get_resource_previewer()

    # Or use AudioStreamPreviewGenerator for waveforms
    var preview_gen = AudioStreamPreviewGenerator.instantiate()
    add_child(preview_gen)
    preview_gen.stream = stream

    # Wait for preview to be ready
    await preview_gen.ready

    # Get preview data
    var preview_data = preview_gen.get_preview()

    # Draw waveform using preview data
    _draw_waveform(preview_data)
```

---

## 📝 Documentation Integration

### 1. Add Built-In Help

```gdscript
# Make your classes show up in Godot's help
## AudioEvent is a reusable sound effect definition
##
## AudioEvent allows sound designers to configure audio playback
## without writing code. It supports randomization, 3D spatial audio,
## voice stealing, and more.
##
## [b]Example:[/b]
## [codeblock]
## var footstep = preload("res://audio/footstep.tres")
## AudioController.play_event(footstep, player.position)
## [/codeblock]
##
## @tutorial(Audio System Guide): https://docs.yoursite.com/audio
class_name AudioEvent extends Resource
```

### 2. Add Tooltips (Godot Style)

```gdscript
# Use Godot's rich text tooltips
play_button.tooltip_text = "Play audio event\n[color=gray](Space)[/color]"
stop_button.tooltip_text = "Stop playback\n[color=gray](Esc)[/color]"

# For complex tooltips, use hint_tooltip
volume_slider.hint_tooltip = """[b]Volume Randomization[/b]

Randomly vary the volume of each playback instance within this range.

[color=gray]• -3 dB = About 70% perceived loudness
• 0 dB = Full volume
• +3 dB = About 140% perceived loudness[/color]"""
```

---

## 🎯 Best Practices Summary

### ✅ DO:
- Use `EditorInterface.get_editor_theme()` for all colors/styles
- Use built-in icons from "EditorIcons"
- Match Godot's keyboard shortcuts
- Integrate with FileSystem, Inspector, Scene Tree
- Respect editor scale and user preferences
- Use ConfirmationDialog for destructive actions
- Use EditorFileDialog for file browsing
- Add proper tooltips with shortcuts shown
- Handle resource UIDs properly
- Pause heavy operations when tab not visible

### ❌ DON'T:
- Hard-code colors or create custom themes
- Create custom file browsers (use EditorFileDialog)
- Ignore editor scale
- Use non-standard keyboard shortcuts
- Create floating windows (stay in main editor)
- Block the main thread with heavy operations
- Ignore Godot's UX conventions
- Create your own confirmation dialogs
- Bypass FileSystem for file operations

---

## 🚀 Implementation Checklist

```
[ ] Use EditorInterface.get_editor_theme() everywhere
[ ] Use get_theme_icon() for all icons
[ ] Respect EditorInterface.get_editor_scale()
[ ] Integrate with FileSystem drag-and-drop
[ ] Add Inspector plugin for custom property editors
[ ] Register shortcuts properly with tooltips
[ ] Use ConfirmationDialog for deletes
[ ] Use EditorFileDialog for file browsing
[ ] Apply theme recursively to all UI
[ ] Add rich tooltips with keyboard shortcuts
[ ] Handle tab visibility to pause operations
[ ] Add class documentation with ## comments
[ ] Test with light and dark themes
[ ] Test with different editor scales (100%, 150%, 200%)
[ ] Test all keyboard shortcuts
```

---

## 📚 Reference: Godot Editor Classes

```gdscript
# Key classes for native integration
EditorInterface         # Main editor API
EditorPlugin           # Your plugin base
EditorTheme            # Editor theme
EditorSettings         # User settings
EditorFileSystem       # File tracking
EditorInspectorPlugin  # Custom inspector
EditorFileDialog       # File browser
EditorResourcePreview  # Thumbnails
```

This guide ensures your plugin feels like it was built by Godot itself! 🎮
