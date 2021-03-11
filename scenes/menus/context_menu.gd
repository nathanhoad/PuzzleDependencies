class_name GraphContextMenu
extends PopupMenu


const ITEM_NEW_NODE = 0

const ITEM_NEW = 100
const ITEM_OPEN = 101
const ITEM_SAVE = 102

const ITEM_QUIT = 300


func _ready() -> void:
#	add_icon_item(preload("res://icon.png"), "Add node", ITEM_NEW_NODE)
#	add_icon_shortcut(preload("res://icon.png"), preload("res://scenes/menus/new_node_shortcut.tres"), ITEM_NEW_NODE)
	add_item("Add node", ITEM_NEW_NODE)
	add_separator()
	add_item("New", ITEM_NEW)
	add_item("Open...", ITEM_OPEN)
	add_item("Save", ITEM_SAVE)
	add_separator()
	add_item("Quit", ITEM_QUIT)
