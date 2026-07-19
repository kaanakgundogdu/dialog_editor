@tool
extends Control

@onready var graph_edit: GraphEdit = $GraphEdit
var popup_menu: PopupMenu

const DIALOG_NODE_SCENE = preload("res://addons/dialog_editor/scenes/dialog_node_ui.tscn")
const CHOICE_NODE_SCENE = preload("res://addons/dialog_editor/scenes/choice_node_ui.tscn")
const LOGIC_NODE_SCENE = preload("res://addons/dialog_editor/scenes/logic_node_ui.tscn")

var last_click_position: Vector2 = Vector2.ZERO

func _ready():
	if popup_menu != null:
		return
		
	popup_menu = PopupMenu.new()
	popup_menu.add_item("Add Dialog Node", 0)
	popup_menu.add_item("Add Choice Node", 1)
	popup_menu.add_item("Add Logic Node", 2)
	
	add_child(popup_menu)

	popup_menu.id_pressed.connect(_on_popup_menu_id_pressed)
	graph_edit.popup_request.connect(_on_graph_edit_popup_request)
	graph_edit.connection_request.connect(_on_graph_edit_connection_request)
	graph_edit.disconnection_request.connect(_on_graph_edit_disconnection_request)
	graph_edit.delete_nodes_request.connect(_on_graph_edit_delete_nodes_request)
	
	# Add the compiler trigger execution button to the top toolbar
	var compile_btn = Button.new()
	compile_btn.text = "Compile Scenario (.txt)"
	compile_btn.pressed.connect(compile_story)
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
			# Remove all associated connections from the graph list before freeing the node
			for conn in graph_edit.get_connection_list():
				if conn["from_node"] == node_name or conn["to_node"] == node_name:
					graph_edit.disconnect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])
			node.queue_free()

func _on_popup_menu_id_pressed(id: int):
	var new_node = null
	
	if id == 0:
		new_node = DIALOG_NODE_SCENE.instantiate()
	elif id == 1:
		new_node = CHOICE_NODE_SCENE.instantiate()
	elif id == 2:
		new_node = LOGIC_NODE_SCENE.instantiate()
		
	if new_node != null:
		graph_edit.add_child(new_node)
		new_node.position_offset = (last_click_position + graph_edit.scroll_offset) / graph_edit.zoom
		
		# Automatically calculate sequential Node ID increments
		var max_id = -1
		for child in graph_edit.get_children():
			if child is GraphNode and child != new_node:
				if child.has_method("get_dialog_id"):
					var child_id = child.get_dialog_id()
					if child_id > max_id:
						max_id = child_id
						
		var next_id = 0 if max_id == -1 else max_id + 1
		if new_node.has_method("set_dialog_id"):
			new_node.set_dialog_id(next_id)

func compile_story():
	var dialog_nodes = []
	for child in graph_edit.get_children():
		if child is GraphNode:
			dialog_nodes.append(child)
			
	# Filter out orphaned nodes that have no active input or output lines
	var connections_list = graph_edit.get_connection_list()
	var connected_node_names = {}
	
	for conn in connections_list:
		connected_node_names[conn["from_node"]] = true
		connected_node_names[conn["to_node"]] = true
		
	var filtered_nodes = []
	for node in dialog_nodes:
		# Keep nodes if they have active lines, or if they act as the entry point (ID 0)
		if connected_node_names.has(node.name) or (node.has_method("get_dialog_id") and node.get_dialog_id() == 0):
			filtered_nodes.append(node)
			
	dialog_nodes = filtered_nodes
			
	dialog_nodes.sort_custom(func(a, b):
		if a.has_method("get_dialog_id") and b.has_method("get_dialog_id"):
			return a.get_dialog_id() < b.get_dialog_id()
		return false
	)
	
	# Structure graph lines into a readable source-destination map
	var connections_map = {} 
	for conn in connections_list:
		var from_n = conn["from_node"]
		var from_p = conn["from_port"]
		var to_n = conn["to_node"]
		
		if not connections_map.has(from_n):
			connections_map[from_n] = {}
		connections_map[from_n][from_p] = to_n
			
	var final_text = ""
	
	for node in dialog_nodes:
		if not node.has_method("get_dialog_id"):
			continue
			
		var my_id = node.get_dialog_id()
		final_text += "# id: " + str(my_id) + "\n"
		
		if node.has_method("get_dialog_data"):
			var data = node.get_dialog_data()
			
			if data["bg"] != "":
				final_text += "@bg " + data["bg"] + "\n"
			if data["music"] != "":
				final_text += "@music " + data["music"] + "\n"
				
			var speaker_block = data["speaker"]
			if speaker_block == "":
				speaker_block = "Narrator"
				
			if data["expression"] != "":
				speaker_block += " (" + data["expression"] + ")"
				
			final_text += speaker_block + ": " + data["text"] + "\n"
			
			if connections_map.has(node.name) and connections_map[node.name].has(0):
				var target_node_name = connections_map[node.name][0]
				var target_node = graph_edit.get_node(NodePath(target_node_name))
				var target_id = target_node.get_dialog_id()
				
				var my_index = dialog_nodes.find(node)
				var next_node_id = -1
				if my_index + 1 < dialog_nodes.size():
					next_node_id = dialog_nodes[my_index + 1].get_dialog_id()
					
				if target_id != next_node_id:
					final_text += "@jump " + str(target_id) + "\n"
					
		elif node.has_method("get_choices_data"):
			var choices = node.get_choices_data()
			
			for choice in choices:
				var port = choice["port_index"]
				var text = choice["text"]
				
				var target_id = -1 
				if connections_map.has(node.name) and connections_map[node.name].has(port):
					var target_node_name = connections_map[node.name][port]
					var target_node = graph_edit.get_node(NodePath(target_node_name))
					target_id = target_node.get_dialog_id()
					
				final_text += "- " + text + " -> " + str(target_id) + "\n"
		
		# --- CASE 3: Logic Node Handling ---
		elif node.has_method("get_logic_data"):
			var logic = node.get_logic_data()
			var f_name = logic["flag_name"]
			var op = logic["operator"]
			var f_val = logic["flag_value"]
			
			if logic["type"] == 0: # Modify Variable
				if f_name != "":
					# Example Output: @set_var sadness += 10
					final_text += "@set_var " + f_name + " " + op + " " + f_val + "\n"
				
				if connections_map.has(node.name) and connections_map[node.name].has(0):
					var target_node_name = connections_map[node.name][0]
					var target_node = graph_edit.get_node(NodePath(target_node_name))
					var target_id = target_node.get_dialog_id()
					
					var my_index = dialog_nodes.find(node)
					var next_node_id = -1
					if my_index + 1 < dialog_nodes.size():
						next_node_id = dialog_nodes[my_index + 1].get_dialog_id()
						
					if target_id != next_node_id:
						final_text += "@jump " + str(target_id) + "\n"
						
			elif logic["type"] == 1: # Check Condition
				var target_true = -1
				var target_false = -1
				
				if connections_map.has(node.name):
					if connections_map[node.name].has(0):
						target_true = graph_edit.get_node(NodePath(connections_map[node.name][0])).get_dialog_id()
					if connections_map[node.name].has(1):
						target_false = graph_edit.get_node(NodePath(connections_map[node.name][1])).get_dialog_id()
						
				if f_name != "" and target_true != -1:
					# Example Output: @jump_if sadness >= 100 40
					final_text += "@jump_if " + f_name + " " + op + " " + f_val + " " + str(target_true) + "\n"
					
				if target_false != -1:
					var my_index = dialog_nodes.find(node)
					var next_node_id = -1
					if my_index + 1 < dialog_nodes.size():
						next_node_id = dialog_nodes[my_index + 1].get_dialog_id()
						
					if target_false != next_node_id:
						final_text += "@jump " + str(target_false) + "\n"
						
		final_text += "\n" 
		
	var save_path = "res://compiled_scenario.txt"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(final_text)
		file.close()
		print("[Dialog Engine] Scenario compiled successfully: ", save_path)
		EditorInterface.get_resource_filesystem().update_file(save_path)
