@tool
extends EditorPlugin

const AUTOLOAD_AUDIO_MANAGER = "AudioManager"
const AUTOLOAD_MUSIC_MANAGER = "MusicManager"

func _enter_tree():
	# Add autoloads
	add_autoload_singleton(AUTOLOAD_AUDIO_MANAGER, "res://addons/g4_audio/autoloads/audio_manager.gd")
	add_autoload_singleton(AUTOLOAD_MUSIC_MANAGER, "res://addons/g4_audio/autoloads/music_manager.gd")

	print("G4 Audio System enabled")
	print("  - AudioManager singleton added")
	print("  - MusicManager singleton added")
	print("  - Ready to use!")

func _exit_tree():
	# Remove autoloads
	remove_autoload_singleton(AUTOLOAD_AUDIO_MANAGER)
	remove_autoload_singleton(AUTOLOAD_MUSIC_MANAGER)

	print("G4 Audio System disabled")
