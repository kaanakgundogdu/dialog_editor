@tool
extends GraphNode

@onready var id_spinbox = $IDSpinBox
@onready var add_button = $AddChoiceButton

func _ready():
	# Slot 0 (ID Area): Left port (Input) only
	set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
	
	# Slot 1 (Add Button): Keep both ports closed
	set_slot(1, false, 0, Color.WHITE, false, 0, Color.WHITE)
	
	if not add_button.pressed.is_connected(_on_add_button_pressed):
		add_button.pressed.connect(_on_add_button_pressed)

func get_dialog_id() -> int:
	if id_spinbox:
		return int(id_spinbox.value)
	return 0

func set_dialog_id(val: int):
	if id_spinbox:
		id_spinbox.value = val

func _on_add_button_pressed():
	var container = HBoxContainer.new()
	
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "Choice text for the player..."
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var delete_btn = Button.new()
	delete_btn.text = "X"
	
	delete_btn.pressed.connect(func():
		var idx = container.get_index()
		# Close the slot before removing the UI element
		set_slot(idx, false, 0, Color.WHITE, false, 0, Color.WHITE)
		container.queue_free()
		# Await one frame to let queue_free finish, then resize the node properly
		await get_tree().process_frame
		reset_size()
	)
	
	container.add_child(line_edit)
	container.add_child(delete_btn)
	add_child(container)
	
	# Open the right port (Output) for the newly added choice row
	var new_index = container.get_index()
	set_slot(new_index, false, 0, Color.WHITE, true, 0, Color.GREEN)
	
	reset_size()
	
func get_choices_data() -> Array:
	var choices = []
	var current_right_port = 0
	
	for i in range(get_child_count()):
		# Godot determines port indices based strictly on sequentially enabled slots
		if is_slot_enabled_right(i):
			var child = get_child(i)
			if child is HBoxContainer:
				var line_edit = child.get_child(0) as LineEdit
				var choice_text = line_edit.text.strip_edges() if line_edit else ""
				
				choices.append({
					"port_index": current_right_port, 
					"text": choice_text
				})
			
			# Increment because this slot has an active right port
			current_right_port += 1
			
	return choices
