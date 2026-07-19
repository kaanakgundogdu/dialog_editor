@tool
extends EditorPlugin

var main_panel

func _enter_tree():
	# Instantiate the main custom panel workspace viewport scene
	var MainPanelScene = preload("res://addons/dialog_editor/scenes/editor_main.tscn")
	main_panel = MainPanelScene.instantiate()

	# Configure anchors to expand across the full editor panel layout bounds
	main_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Mount the instantiated layout directly inside Godot's core workspace screen
	EditorInterface.get_editor_main_screen().add_child(main_panel)
	
	# Keep the interface layout hidden initially until its specific workspace tab is focused
	_make_visible(false)

func _exit_tree():
	if main_panel:
		main_panel.queue_free()

func _has_main_screen():
	return true

func _make_visible(visible):
	if main_panel:
		main_panel.visible = visible

func _get_plugin_name():
	return "Dialog Engine"

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("GraphEdit", "EditorIcons")
