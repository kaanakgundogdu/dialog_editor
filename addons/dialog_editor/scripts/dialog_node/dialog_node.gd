@tool
extends GraphNode

# Sahnede isimlerini değiştirdiğimiz node'ları buraya bağlıyoruz
@onready var id_spinbox = $IDSpinBox
@onready var bg_edit = $BgEdit
@onready var music_edit = $MusicEdit
@onready var expression_edit = $ExpressionEdit
@onready var speaker_edit = $SpeakerEdit
@onready var text_edit = $TextEdit

func _ready():
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)

func get_dialog_id() -> int:
	if id_spinbox:
		return int(id_spinbox.value)
	return 0

func set_dialog_id(val: int):
	if id_spinbox:
		id_spinbox.value = val

# Derleyicinin (Compiler) tek seferde tüm bilgileri çekebilmesi için yeni fonksiyon
func get_dialog_data() -> Dictionary:
	return {
		"bg": bg_edit.text.strip_edges() if bg_edit else "",
		"music": music_edit.text.strip_edges() if music_edit else "",
		"speaker": speaker_edit.text.strip_edges() if speaker_edit else "Narrator",
		"expression": expression_edit.text.strip_edges() if expression_edit else "",
		"text": text_edit.text.strip_edges() if text_edit else ""
	}
