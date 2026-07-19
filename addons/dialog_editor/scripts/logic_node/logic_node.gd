@tool
extends GraphNode

@onready var id_spinbox = $IDSpinBox
@onready var type_button = $TypeButton
@onready var op_container = $OpContainer
@onready var flag_name_edit = $OpContainer/FlagNameEdit
@onready var operator_button = $OpContainer/OperatorButton
@onready var flag_value_edit = $OpContainer/FlagValueEdit
@onready var true_label = $TrueLabel
@onready var false_label = $FalseLabel

func _ready():
	if type_button and type_button.item_count == 0:
		type_button.add_item("Modify Variable (Set/Add)")
		type_button.add_item("Check Condition (If)")
		
	if type_button and not type_button.item_selected.is_connected(_on_type_selected):
		type_button.item_selected.connect(_on_type_selected)

	if type_button:
		_on_type_selected(type_button.selected)

func get_dialog_id() -> int:
	if id_spinbox: return int(id_spinbox.value)
	return 0

func set_dialog_id(val: int):
	if id_spinbox: id_spinbox.value = val

func _on_type_selected(index: int):
	# Clear out all active slots before remodeling the port layout
	for i in range(get_child_count()):
		set_slot(i, false, 0, Color.WHITE, false, 0, Color.WHITE)

	# Populate operators dynamically based on the selected node logic execution path
	if operator_button:
		operator_button.clear()
		if index == 0: # Modify Variable
			operator_button.add_item("=")
			operator_button.add_item("+=")
			operator_button.add_item("-=")
		elif index == 1: # Check Condition
			operator_button.add_item("==")
			operator_button.add_item("!=")
			operator_button.add_item(">")
			operator_button.add_item(">=")
			operator_button.add_item("<")
			operator_button.add_item("<=")

	if index == 0: # Modify Variable
		true_label.visible = false
		false_label.visible = false
		set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)

	elif index == 1: # Check Condition
		true_label.visible = true
		false_label.visible = true
		
		# Slot 0 configuration: Input (Left) port only
		set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)

		# Fetch exact sibling UI indices to map output port signals accurately
		var true_idx = true_label.get_index()
		var false_idx = false_label.get_index()

		set_slot(true_idx, false, 0, Color.WHITE, true, 0, Color.GREEN)
		set_slot(false_idx, false, 0, Color.WHITE, true, 0, Color.RED)

	reset_size()

func get_logic_data() -> Dictionary:
	return {
		"type": type_button.selected if type_button else 0,
		"flag_name": flag_name_edit.text.strip_edges() if flag_name_edit else "",
		"operator": operator_button.get_item_text(operator_button.selected) if operator_button and operator_button.item_count > 0 else "==",
		"flag_value": flag_value_edit.text.strip_edges() if flag_value_edit else ""
	}
