@tool
extends GraphNode

@onready var id_spinbox = $IDSpinBox
@onready var bg_edit = $BgContainer/BgEdit
@onready var bg_button = $BgContainer/BgButton
@onready var music_edit = $MusicContainer/MusicEdit
@onready var music_button = $MusicContainer/MusicButton
@onready var expression_edit = $ExpressionEdit
@onready var speaker_edit = $SpeakerEdit
@onready var text_edit = $TextEdit

var file_dialog: FileDialog
var current_target_line_edit: LineEdit

func _ready():
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	
	# Programmatically configure a workspace-bounded FileDialog
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.min_size = Vector2(600, 400)
	file_dialog.use_native_dialog = true
	
	file_dialog.file_selected.connect(_on_file_selected)
	add_child(file_dialog)
	
	if bg_button:
		bg_button.pressed.connect(_on_bg_button_pressed)
	if music_button:
		music_button.pressed.connect(_on_music_button_pressed)

func get_dialog_id() -> int:
	if id_spinbox:
		return int(id_spinbox.value)
	return 0

func set_dialog_id(val: int):
	if id_spinbox:
		id_spinbox.value = val

func get_dialog_data() -> Dictionary:
	return {
		"bg": bg_edit.text.strip_edges() if bg_edit else "",
		"music": music_edit.text.strip_edges() if music_edit else "",
		"speaker": speaker_edit.text.strip_edges() if speaker_edit else "Narrator",
		"expression": expression_edit.text.strip_edges() if expression_edit else "",
		"text": text_edit.text.strip_edges() if text_edit else ""
	}

func _on_bg_button_pressed():
	current_target_line_edit = bg_edit
	file_dialog.clear_filters()
	file_dialog.add_filter("*.png, *.jpg, *.jpeg, *.webp", "Images")
	file_dialog.popup_centered()

func _on_music_button_pressed():
	current_target_line_edit = music_edit
	file_dialog.clear_filters()
	file_dialog.add_filter("*.mp3, *.wav, *.ogg", "Audio")
	file_dialog.popup_centered()

func _on_file_selected(path: String):
	if current_target_line_edit:
		# Extract and populate only the raw asset name without directories or extensions
		current_target_line_edit.text = path.get_file().get_basename()
