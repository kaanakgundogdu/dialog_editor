@tool
extends Control

@onready var graph_edit: GraphEdit = $GraphEdit
var popup_menu: PopupMenu

const DIALOG_NODE_SCENE = preload("res://addons/dialog_editor/scenes/dialog_node_ui.tscn")
var last_click_position: Vector2 = Vector2.ZERO

func _ready():
	if popup_menu != null:
		return
		
	popup_menu = PopupMenu.new()
	popup_menu.add_item("Add Dialog Node", 0)
	add_child(popup_menu)

	popup_menu.id_pressed.connect(_on_popup_menu_id_pressed)
	graph_edit.popup_request.connect(_on_graph_edit_popup_request)
	graph_edit.connection_request.connect(_on_graph_edit_connection_request)
	graph_edit.disconnection_request.connect(_on_graph_edit_disconnection_request)
	graph_edit.delete_nodes_request.connect(_on_graph_edit_delete_nodes_request)
	
	# --- YENİ EKLENEN KISIM: Üst Bara Derleme Butonu Ekleme ---
	var compile_btn = Button.new()
	compile_btn.text = "Compile Scenario (.txt)"
	compile_btn.pressed.connect(compile_story)
	
	# Butonu GraphEdit'in kendi üst menüsüne yerleştiriyoruz
	graph_edit.get_menu_hbox().add_child(compile_btn)

func _on_graph_edit_popup_request(p_position: Vector2):
	last_click_position = p_position
	popup_menu.position = Vector2i(graph_edit.get_screen_position() + p_position)
	popup_menu.popup()


func _on_graph_edit_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	graph_edit.connect_node(from_node, from_port, to_node, to_port)

func _on_graph_edit_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int):
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)

func _on_graph_edit_delete_nodes_request(nodes: Array[StringName]):
	for node_name in nodes:
		var node = graph_edit.get_node_or_null(NodePath(node_name))
		if node:
			for conn in graph_edit.get_connection_list():
				if conn["from_node"] == node_name or conn["to_node"] == node_name:
					graph_edit.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
			node.queue_free()
			

func _on_popup_menu_id_pressed(id: int):
	if id == 0:
		var new_node = DIALOG_NODE_SCENE.instantiate()
		graph_edit.add_child(new_node)
		new_node.position_offset = (last_click_position + graph_edit.scroll_offset) / graph_edit.zoom
		
		var max_id = -1
		for child in graph_edit.get_children():
			if child is GraphNode and child != new_node:
				# Scriptin yüklenip yüklenmediğini kontrol ederek güvenli çağrı yapıyoruz
				if child.has_method("get_dialog_id"):
					var child_id = child.get_dialog_id()
					if child_id > max_id:
						max_id = child_id
						
		# ID'yi 1'er 1'er artırıyoruz
		var next_id = 0 if max_id == -1 else max_id + 1
		
		if new_node.has_method("set_dialog_id"):
			new_node.set_dialog_id(next_id)

func compile_story():
	var dialog_nodes = []
	for child in graph_edit.get_children():
		if child is GraphNode:
			dialog_nodes.append(child)
			
	# Düğümleri artık ekrandaki yerlerine göre DEĞİL, senin belirlediğin ID numarasına göre küçükten büyüğe sıralıyoruz
	dialog_nodes.sort_custom(func(a, b):
		return a.get_dialog_id() < b.get_dialog_id()
	)
	
	var connections = graph_edit.get_connection_list()
	var next_nodes_map = {} 
	
	for conn in connections:
		if conn["from_port"] == 0: 
			next_nodes_map[conn["from_node"]] = conn["to_node"]
			
	var final_text = ""
	
	for node in dialog_nodes:
		# Scriptin güncellenip güncellenmediğini kontrol edelim
		if not node.has_method("get_dialog_data"):
			continue
			
		var my_id = node.get_dialog_id()
		var data = node.get_dialog_data()
		
		final_text += "# id: " + str(my_id) + "\n"
		
		# Eğer arkaplan yazılmışsa ekle
		if data["bg"] != "":
			final_text += "@bg " + data["bg"] + "\n"
			
		# Eğer müzik yazılmışsa ekle
		if data["music"] != "":
			final_text += "@music " + data["music"] + "\n"
			
		# İsim ve ifade (expression) formatını parser'ına uygun hale getiriyoruz
		var speaker_block = data["speaker"]
		if data["expression"] != "":
			speaker_block += " (" + data["expression"] + ")"
			
		final_text += speaker_block + ": " + data["text"] + "\n"
		
		# Bağlı olduğu hedef node'un ID'sini bulma ve jump atama kısmı (Aynı kalıyor)
		if next_nodes_map.has(node.name):
			var target_node_name = next_nodes_map[node.name]
			var target_node = graph_edit.get_node(NodePath(target_node_name))
			var target_id = target_node.get_dialog_id()
			
			var my_index = dialog_nodes.find(node)
			var next_node_id = -1
			if my_index + 1 < dialog_nodes.size():
				next_node_id = dialog_nodes[my_index + 1].get_dialog_id()
				
			if target_id != next_node_id:
				final_text += "@jump " + str(target_id) + "\n"
				
		final_text += "\n"
		
	var save_path = "res://compiled_scenario.txt"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(final_text)
		file.close()
		print("[Dialog Engine] Explicit ID derleme tamamlandı! Çıktı: ", save_path)
		
		# Editörün dosyayı zorla yenilemesini sağlayan komut
		EditorInterface.get_resource_filesystem().update_file(save_path)
