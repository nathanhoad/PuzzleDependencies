extends FileDialog


signal file_chosen


func choose_file(default_path: String = ""):
	popup_centered()


func _on_OpenDialog_file_selected(path: String) -> void:
	emit_signal("file_chosen", path)
	queue_free()


func _on_OpenDialog_confirmed():
	emit_signal("file_chosen", current_path)
	queue_free()


func _on_OpenDialog_popup_hide():
	emit_signal("file_chosen", "")
	queue_free()
