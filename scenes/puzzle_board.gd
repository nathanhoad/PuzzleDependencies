extends GraphEdit


const PuzzleNode = preload("res://scenes/puzzle_node.tscn")
const SaveDialogue = preload("res://scenes/dialogues/save_dialogue.tscn")
const OpenDialogue = preload("res://scenes/dialogues/open_dialogue.tscn")
const UnsavedChangesDialogue = preload("res://scenes/dialogues/unsaved_changes_dialogue.tscn")


onready var context_menu : PopupMenu = $ContextMenu


var next_node_id : int = 0
var nodes : Dictionary = {}
var file_path: String = ""
var has_changed: bool = false
var unsaved_changes_action = "quit"


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	add_valid_connection_type(0, 0)
	empty_project()


func _notification(what) -> void:
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		if yield(save_changes_if_needed_and_continue(), "completed"):
			get_tree().quit()


func get_next_node_id() -> String:
	var id = "Node" + str(next_node_id)
	next_node_id += 1
	return id


func add_node(position: Vector2, id: String = "", text: String = "") -> String:
	if id == "":
		id = get_next_node_id()
	var puzzle_node = PuzzleNode.instance()
	puzzle_node.offset = position
	puzzle_node.name = id
	puzzle_node.connect("close_request", self, "_on_PuzzleNode_close_request", [id])
	nodes[id] = puzzle_node
	add_child(puzzle_node)
	set_selected(puzzle_node)
	
	if text != "":
		puzzle_node.text_edit.text = text
	
	has_changed = true
	
	return id


func save_changes_if_needed_and_continue():
	yield(get_tree(), "idle_frame")
	
	if has_changed:
		var unsaved_changes_dialogue = UnsavedChangesDialogue.instance()
		add_child(unsaved_changes_dialogue)
		unsaved_changes_dialogue.ask_to_save_changes()
		var response = yield(unsaved_changes_dialogue, "button_pressed")
		match response:
			unsaved_changes_dialogue.SAVE:
				yield(save_file(), "completed")
			
			unsaved_changes_dialogue.CANCEL:
				return false
	
	return true


func empty_project() -> void:
	next_node_id = 0
	file_path = ""
	for connection in get_connection_list():
		disconnect_node(connection.get("from"), connection.get("from_port"), connection.get("to"), connection.get("to_port"))
	for node in nodes.values():
		node.queue_free()
	nodes.clear()


func save_file():
	yield(get_tree(), "idle_frame")
	
	var save_file_path = ""
	if file_path == "":
		var save_dialogue = SaveDialogue.instance()
		add_child(save_dialogue)
		save_dialogue.choose_file()
		save_file_path = yield(save_dialogue, "file_chosen")
	
	if save_file_path == "":
		return
		
	if not file_path.ends_with(".puzzles"):
		file_path = file_path + ".puzzles"
	
	var data : Dictionary = {
		"next_node_id": next_node_id,
	}
	
	var serialized_nodes = []
	for node in nodes.values():
		serialized_nodes.append(node.serialize())
	data["nodes"] = serialized_nodes
	
	var serialized_connections = []
	for connection in get_connection_list():
		serialized_connections.append({
			"from": connection.get("from"),
			"to": connection.get("to")
		})
	data["connections"] = serialized_connections
	
	var file = File.new()
	file.open(file_path, File.WRITE)
	file.store_string(to_json(data))
	file.close()
	
	has_changed = false


func open_file() -> void:
	var open_dialogue = OpenDialogue.instance()
	add_child(open_dialogue)
	open_dialogue.choose_file()
	var open_file_path = yield(open_dialogue, "file_chosen")
	
	var file = File.new()
	if open_file_path != "" and file.file_exists(open_file_path):
		empty_project()
		
		file_path = open_file_path
		
		file.open(file_path, File.READ)
		var data = parse_json(file.get_as_text())
		file.close()
		
		next_node_id = data.get("next_node_id")
		for serialized_node in data.get("nodes"):
			var offset = Vector2(serialized_node.get("x"), serialized_node.get("y"))
			add_node(offset, serialized_node.get("id"), serialized_node.get("text"))
		
		for serialized_connection in data.get("connections"):
			connect_node(serialized_connection.get("from"), 0, serialized_connection.get("to"), 0)
		
		has_changed = false
	else:
		printerr("No file! ", open_file_path)


### Signals


func _on_PuzzleBoard_popup_request(position) -> void:
	context_menu.rect_position = position
	context_menu.popup()


func _on_ContextMenu_id_pressed(id) -> void:	
	match id:
		GraphContextMenu.ITEM_NEW_NODE:
			add_node(scroll_offset + context_menu.rect_position)
		
		GraphContextMenu.ITEM_NEW:
			if yield(save_changes_if_needed_and_continue(), "completed"):
				empty_project()
		
		GraphContextMenu.ITEM_OPEN:
			if yield(save_changes_if_needed_and_continue(), "completed"):
				open_file()
		
		GraphContextMenu.ITEM_SAVE:
			save_file()
		
		GraphContextMenu.ITEM_QUIT:
			if yield(save_changes_if_needed_and_continue(), "completed"):
				get_tree().quit()


func _on_PuzzleBoard_connection_request(from, from_slot, to, to_slot) -> void:
	connect_node(from, from_slot, to, to_slot)
	has_changed = true


func _on_PuzzleNode_close_request(id: String) -> void:
	# Disconnect any wires
	for connection in get_connection_list():
		var from = connection.get("from")
		var to = connection.get("to")
		if from == id or to == id:
			disconnect_node(from, 0, to, 0)
	
	# Remove the node itself
	nodes[id].queue_free()
	nodes.erase(id)
	
	has_changed = true


func _on_PuzzleBoard_disconnection_request(from, from_slot, to, to_slot) -> void:
	disconnect_node(from, from_slot, to, to_slot)
	has_changed = true
	

func _on_PuzzleBoard_connection_from_empty(to, to_slot, release_position):
	var id = add_node(scroll_offset + release_position)
	connect_node(id, 0, to, to_slot)


func _on_PuzzleBoard_connection_to_empty(from, from_slot, release_position) -> void:
	var id = add_node(scroll_offset + release_position)
	connect_node(from, from_slot, id, 0)


func _on_PuzzleBoard__end_node_move():
	has_changed = true
