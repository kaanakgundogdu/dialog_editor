@tool
extends EditorPlugin

var main_panel

func _enter_tree():
	# 1. Adımda oluşturduğumuz sahneyi yüklüyoruz
	var MainPanelScene = preload("res://addons/dialog_editor/scenes/editor_main.tscn")
	main_panel = MainPanelScene.instantiate()

	# Bu iki satır panelin editördeki boşluğu dikey ve yatay olarak tamamen kaplamasını sağlar
	main_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Sahneyi Godot'nun ana çalışma ekranına (2D, 3D sekmelerinin olduğu yer) ekliyoruz
	EditorInterface.get_editor_main_screen().add_child(main_panel)
	
	# Eklenti ilk yüklendiğinde görünmez yapıyoruz (sadece sekmesine tıklanınca açılacak)
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
