@tool
extends EditorPlugin

## AudioMixer EditorPlugin - Adds a dedicated editor tab for audio management

var audio_mixer_ui: Control = null
var inspector_plugin: EditorInspectorPlugin = null

func _enter_tree() -> void:
	# Load the modern UI scene
	var ui_scene = preload("res://addons/audio_mixer/ui/audio_mixer_ui_modern.tscn")
	audio_mixer_ui = ui_scene.instantiate()
	audio_mixer_ui.editor_plugin = self

	# Add to main screen
	get_editor_interface().get_editor_main_screen().add_child(audio_mixer_ui)

	# Hide initially (Godot will show it when tab is clicked)
	_make_visible(false)

	# Register custom inspector plugin
	inspector_plugin = preload("res://addons/audio_mixer/scripts/audio_event_inspector_plugin.gd").new()
	inspector_plugin.editor_plugin = self
	add_inspector_plugin(inspector_plugin)

	# Add custom resource types to create menu
	add_custom_type("AudioEvent", "Resource", preload("res://addons/audio_mixer/scripts/audio_event.gd"), null)
	add_custom_type("LayeredAudioEvent", "Resource", preload("res://addons/audio_mixer/scripts/layered_audio_event.gd"), null)
	add_custom_type("MusicEvent", "Resource", preload("res://addons/audio_mixer/scripts/music_event.gd"), null)
	add_custom_type("AudioSnapshot", "Resource", preload("res://addons/audio_mixer/scripts/audio_snapshot.gd"), null)
	add_custom_type("AudioParameter", "Resource", preload("res://addons/audio_mixer/scripts/audio_parameter.gd"), null)

	print("AudioMixer Plugin: Enabled")
	print("  - Custom editor tab added")
	print("  - Inspector plugin registered")
	print("  - Resource types registered")

func _exit_tree() -> void:
	if audio_mixer_ui:
		audio_mixer_ui.queue_free()
		audio_mixer_ui = null

	if inspector_plugin:
		remove_inspector_plugin(inspector_plugin)
		inspector_plugin = null

	# Remove custom types
	remove_custom_type("AudioEvent")
	remove_custom_type("LayeredAudioEvent")
	remove_custom_type("MusicEvent")
	remove_custom_type("AudioSnapshot")
	remove_custom_type("AudioParameter")

	print("AudioMixer Plugin: Disabled")

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if audio_mixer_ui:
		audio_mixer_ui.visible = visible

func _get_plugin_name() -> String:
	return "Audio Mixer"

func _get_plugin_icon() -> Texture2D:
	# Use built-in editor icon or custom icon
	return get_editor_interface().get_base_control().get_theme_icon("AudioStreamPlayer", "EditorIcons")

## Called by UI to get the editor interface
func get_editor() -> EditorInterface:
	return get_editor_interface()

## Called by UI to get the file system
func get_filesystem() -> EditorFileSystem:
	return get_editor_interface().get_resource_filesystem()

## Called by UI to get selection
func get_selection() -> EditorSelection:
	return get_editor_interface().get_selection()
