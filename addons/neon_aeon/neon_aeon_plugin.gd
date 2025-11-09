@tool
extends EditorPlugin

func _enter_tree():
	# Register the custom node type
	add_custom_type(
		"NeonAeonPlayer",
		"Control",
		preload("res://addons/neon_aeon/scripts/NeonAeonPlayer.gd"),
		preload("res://addons/neon_aeon/icon.png") if FileAccess.file_exists("res://addons/neon_aeon/icon.png") else null
	)
	print("Neon Aeon Plugin: Enabled")

func _exit_tree():
	# Unregister the custom node type
	remove_custom_type("NeonAeonPlayer")
	print("Neon Aeon Plugin: Disabled")


#**This script:**
#- Runs in the editor (`@tool`)
#- Registers a new node type called "NeonAeonPlayer"
#- Shows up in the "Add Node" dialog
#- Uses an icon if you provide one (optional for now)
