extends GraphEdit


const ContextMenu = preload("res://scenes/menus/context_menu.tscn")
const PuzzleNode = preload("res://scenes/puzzle_node.tscn")
const SaveDialogue = preload("res://scenes/dialogues/save_dialogue.tscn")
const OpenDialogue = preload("res://scenes/dialogues/open_dialogue.tscn")
const UnsavedChangesDialogue = preload("res://scenes/dialogues/unsaved_changes_dialogue.tscn")
const Toast = preload("res://scenes/dialogues/toast.tscn")


var next_node_id : int = 0
var nodes : Dictionary = {}
var file_path: String = ""
var has_changed: bool = false


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	add_valid_connection_type(0, 0)
	empty_project()
	
	OS.center_window()


func _process(delta) -> void:
	if Input.is_action_just_pressed("ui_new_default_node"):
		add_node(get_viewport().get_mouse_position())
	if Input.is_action_just_pressed("ui_new"):
		empty_project()
	if Input.is_action_just_pressed("ui_open"):
		open_file()
	if Input.is_action_just_pressed("ui_save"):
		save_file()
	
	if Input.is_action_just_pressed("ui_quit"):
		if yield(save_changes_if_needed_and_continue(), "completed"):
			get_tree().quit()
	
	set_window_title()


func _notification(what) -> void:
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		if yield(save_changes_if_needed_and_continue(), "completed"):
			get_tree().quit()


func _input(event: InputEvent) -> void:
	# Handle ctrl + mouse wheel
	if event is InputEventMouseButton:
		event = event as InputEventMouseButton
		if event.pressed and Input.is_key_pressed(KEY_CONTROL):
			event.pressed = false
			match event.button_index:
				BUTTON_WHEEL_UP:
					zoom += 0.1
				BUTTON_WHEEL_DOWN:
					zoom -= 0.1


func set_window_title() -> void:
	var suffix = ""
	if has_changed:
		suffix = "*"
	var file = ""
	if file_path != "":
		file = " - " + file_path.get_file()
	OS.set_window_title("Puzzle Key" + file + suffix)


func get_next_node_id() -> String:
	var id = "Node" + str(next_node_id)
	next_node_id += 1
	return id


func add_node(position: Vector2, data: Dictionary = {}):
	var puzzle_node = PuzzleNode.instance()
	puzzle_node.graph = self
	
	if data.size() == 0:
		puzzle_node.name = get_next_node_id()
		puzzle_node.offset = position
	else:
		puzzle_node.name = data.get("id")
		puzzle_node.deserialize(data)
		
	puzzle_node.connect("close_request", self, "_on_PuzzleNode_close_request", [puzzle_node.name])
	puzzle_node.connect("disconnected_left", self, "_on_PuzzleNode_disconnected_left", [puzzle_node.name])
	puzzle_node.connect("disconnected_right", self, "_on_PuzzleNode_disconnected_right", [puzzle_node.name])
	nodes[puzzle_node.name] = puzzle_node
	add_child(puzzle_node)
	set_selected(puzzle_node)
	
	has_changed = true
	
	return puzzle_node


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
	for node in get_children():
		if node is GraphNode:
			node.queue_free()


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
		
		file_path = save_file_path
		
	Settings.reopen_file = file_path
	
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
	
	var toast = Toast.instance()
	toast.global_position = Vector2(20, OS.get_window_safe_area().size.y)
	add_child(toast)


func open_file(open_file_path: String = "") -> void:
	yield(get_tree(), "idle_frame")
	
	if open_file_path == "":
		var open_dialogue = OpenDialogue.instance()
		add_child(open_dialogue)
		open_dialogue.choose_file()
		open_file_path = yield(open_dialogue, "file_chosen")
	
	var file = File.new()
	if open_file_path != "" and file.file_exists(open_file_path):
		empty_project()
		yield(get_tree(), "idle_frame")
		
		file_path = open_file_path
		
		file.open(file_path, File.READ)
		var data = parse_json(file.get_as_text())
		file.close()
		
		Settings.reopen_file = file_path
		
		next_node_id = data.get("next_node_id")
		for serialized_node in data.get("nodes"):
			var offset = Vector2(serialized_node.get("x"), serialized_node.get("y"))
			add_node(offset, serialized_node)
		
		for serialized_connection in data.get("connections"):
			connect_node(serialized_connection.get("from"), 0, serialized_connection.get("to"), 0)
		
		has_changed = false
	else:
		printerr("No file! ", open_file_path)


### Signals


func _on_PuzzleBoard_popup_request(position) -> void:
	var menu = ContextMenu.instance()
	add_child(menu)
	menu.rect_position = position
	menu.popup()
	
	var id = yield(menu, "id_pressed")
	match id:
		menu.ITEM_NEW_DEFAULT_NODE:
			var node = add_node(scroll_offset + position)
			node.select_color(Constants.COLOR_DEFAULT)
		
		menu.ITEM_NEW_RED_NODE:
			var node = add_node(scroll_offset + position)
			node.select_color(Constants.COLOR_RED)
		
		menu.ITEM_NEW_YELLOW_NODE:
			var node = add_node(scroll_offset + position)
			node.select_color(Constants.COLOR_YELLOW)
		
		menu.ITEM_NEW_BLUE_NODE:
			var node = add_node(scroll_offset + position)
			node.select_color(Constants.COLOR_BLUE)
		
		menu.ITEM_NEW_GREEN_NODE:
			var node = add_node(scroll_offset + position)
			node.select_color(Constants.COLOR_GREEN)
		
		menu.ITEM_NEW:
			if yield(save_changes_if_needed_and_continue(), "completed"):
				empty_project()
		
		menu.ITEM_OPEN:
			if yield(save_changes_if_needed_and_continue(), "completed"):
				open_file()
		
		menu.ITEM_REOPEN:
			if yield(save_changes_if_needed_and_continue(), "completed"):
				open_file(Settings.reopen_file)
		
		menu.ITEM_SAVE:
			save_file()
		
		menu.ITEM_QUIT:
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


func _on_PuzzleNode_disconnected_left(id: String) -> void:
	for connection in get_connection_list():
		var from = connection.get("from")
		var to = connection.get("to")
		if to == id:
			disconnect_node(from, 0, to, 0)


func _on_PuzzleNode_disconnected_right(id: String) -> void:
	for connection in get_connection_list():
		var from = connection.get("from")
		var to = connection.get("to")
		if from == id:
			disconnect_node(from, 0, to, 0)


func _on_PuzzleBoard_disconnection_request(from, from_slot, to, to_slot) -> void:
	disconnect_node(from, from_slot, to, to_slot)
	has_changed = true
	

func _on_PuzzleBoard_connection_from_empty(to, to_slot, release_position):
	var node = add_node(scroll_offset + release_position - Vector2(256, 45))
	connect_node(node.name, 0, to, to_slot)


func _on_PuzzleBoard_connection_to_empty(from, from_slot, release_position) -> void:
	var node = add_node(scroll_offset + release_position - Vector2(0, 45))
	connect_node(from, from_slot, node.name, 0)


func _on_PuzzleBoard__end_node_move():
	has_changed = true
