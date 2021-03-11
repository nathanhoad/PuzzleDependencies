extends FileDialog


signal file_chosen


func choose_file(default_path: String = ""):
	if default_path == "":
		popup_centered()
	else:
		yield(get_tree(), "idle_frame")
		emit_signal("file_chosen", default_path)


func get_current_path() -> String:
	var path = current_path
	if path != "" and not path.ends_with(".puzzles"):
		path = path + ".puzzles"
	return path


func _on_SaveDialog_file_selected(path: String) -> void:
	emit_signal("file_chosen", get_current_path())
	queue_free()


func _on_SaveDialog_confirmed():
	emit_signal("file_chosen", get_current_path())
	queue_free()


func _on_SaveDialog_popup_hide():
	queue_free()
