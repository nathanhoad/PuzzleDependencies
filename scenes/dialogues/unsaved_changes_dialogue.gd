extends WindowDialog


signal button_pressed(response)


const SAVE = 0
const DISCARD = 1
const CANCEL = 3


func ask_to_save_changes():
	popup_centered()


func _on_Save_pressed():
	emit_signal("button_pressed", SAVE)
	queue_free()


func _on_Discard_pressed():
	emit_signal("button_pressed", DISCARD)
	queue_free()


func _on_Cancel_pressed():
	emit_signal("button_pressed", CANCEL)
	queue_free()


func _on_UnsavedChangesDialog_popup_hide():
	queue_free()
