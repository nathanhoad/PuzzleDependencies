extends GraphNode


onready var text_edit : TextEdit = $TextEdit


func _ready() -> void:
	text_edit.grab_focus()
	text_edit.select_all()


func serialize() -> Dictionary:
	return {
		"id": name,
		"text": text_edit.text,
		"x": offset.x,
		"y": offset.y
	}
