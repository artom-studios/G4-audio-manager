@tool
extends EditorPlugin

## AudioMixer EditorPlugin - Adds a dedicated editor tab for audio management

var audio_mixer_ui: Control = null
var audio_mixer_button: Button = null

func _enter_tree() -> void:
	# Load the UI scene
	var ui_scene = preload("res://addons/audio_mixer/ui/audio_mixer_ui.tscn")
	audio_mixer_ui = ui_scene.instantiate()
	audio_mixer_ui.editor_plugin = self

	# Add to main screen
	get_editor_interface().get_editor_main_screen().add_child(audio_mixer_ui)

	# Hide initially (Godot will show it when tab is clicked)
	_make_visible(false)

	print("AudioMixer Plugin: Enabled")

func _exit_tree() -> void:
	if audio_mixer_ui:
		audio_mixer_ui.queue_free()
		audio_mixer_ui = null

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
