extends Node


const SETTINGS_PATH = "user://settings.json"


var reopen_file : String = "" setget set_reopen_file


func _ready() -> void:
	load_preferences()


func save_preferences() -> void:
	var file = File.new()
	file.open(SETTINGS_PATH, File.WRITE)
	var data = {
		"reopen_file": reopen_file
	}
	file.store_string(to_json(data))
	file.close()


func load_preferences() -> void:
	var file = File.new()
	if file.file_exists(SETTINGS_PATH):
		file.open(SETTINGS_PATH, File.READ)
		var data = parse_json(file.get_as_text())
		file.close()
		
		reopen_file = data.get("reopen_file")


func set_reopen_file(value: String) -> void:
	reopen_file = value
	save_preferences()
