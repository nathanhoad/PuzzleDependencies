extends GraphNode


signal disconnected_left
signal disconnected_right


onready var text_edit : TextEdit = $TextEdit


var graph : GraphEdit = null
var color : int = Constants.COLOR_DEFAULT


func _ready() -> void:
	text_edit.grab_focus()
	text_edit.select_all()
	
	var text_menu = text_edit.get_menu()
	
	text_menu.add_separator()
	text_menu.add_radio_check_item("Default", Constants.COLOR_DEFAULT)
	text_menu.set_item_checked(text_menu.get_item_index(Constants.COLOR_DEFAULT), true)
	text_menu.add_radio_check_item("Red", Constants.COLOR_RED)
	text_menu.add_radio_check_item("Yellow", Constants.COLOR_YELLOW)
	text_menu.add_radio_check_item("Blue", Constants.COLOR_BLUE)
	text_menu.add_radio_check_item("Green", Constants.COLOR_GREEN)
	text_menu.add_separator()
	text_menu.add_item("Disconnect all left", 1000)
	text_menu.add_item("Disconnect all right", 1001)
	text_menu.add_separator()
	text_menu.add_item("Delete node", 2000)
	
	text_menu.connect("id_pressed", self, "_on_text_menu_id_pressed")


func serialize() -> Dictionary:
	return {
		"id": name,
		"text": text_edit.text,
		"color": color,
		"x": offset.x,
		"y": offset.y
	}


func deserialize(data: Dictionary) -> void:
	yield(self, "ready")
	text_edit.text = data.get("text")
	select_color(data.get("color"))
	offset = Vector2(int(data.get("x")), int(data.get("y")))


func select_color(id: int) -> void:
	var text_menu = text_edit.get_menu()
	for color_id in Constants.COLORS:
		text_menu.set_item_checked(text_menu.get_item_index(color_id), id == color_id)
	
	color = id
	
	match id:
		Constants.COLOR_DEFAULT:
			theme = preload("res://scenes/themes/grey_node.tres")
		Constants.COLOR_RED:
			theme = preload("res://scenes/themes/red_node.tres")
		Constants.COLOR_YELLOW:
			theme = preload("res://scenes/themes/yellow_node.tres")
		Constants.COLOR_BLUE:
			theme = preload("res://scenes/themes/blue_node.tres")
		Constants.COLOR_GREEN:
			theme = preload("res://scenes/themes/green_node.tres")

func _on_TextEdit_focus_entered() -> void:
	if graph != null:
		graph.set_selected(self)


func _on_TextEdit_focus_exited() -> void:
	text_edit.deselect()


func _on_text_menu_id_pressed(id: int) -> void:
	if Constants.COLORS.find(id) > -1:
		select_color(id)
	elif id == 1000:
		emit_signal("disconnected_left")
	elif id == 1001:
		emit_signal("disconnected_right")
	elif id == 2000:
		emit_signal("close_request")
