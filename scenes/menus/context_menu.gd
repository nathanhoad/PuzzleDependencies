extends PopupMenu


const ITEM_NEW_DEFAULT_NODE = 0
const ITEM_NEW_RED_NODE = 1
const ITEM_NEW_YELLOW_NODE = 2
const ITEM_NEW_BLUE_NODE = 3
const ITEM_NEW_GREEN_NODE = 4

const ITEM_NEW = 100
const ITEM_OPEN = 101
const ITEM_REOPEN = 102
const ITEM_SAVE = 103

const ITEM_QUIT = 300


func _ready() -> void:
	add_item("Add default node", ITEM_NEW_DEFAULT_NODE, KEY_MASK_ALT | KEY_N)
	add_item("Add red node", ITEM_NEW_RED_NODE)
	add_item("Add yellow node", ITEM_NEW_YELLOW_NODE)
	add_item("Add blue node", ITEM_NEW_BLUE_NODE)
	add_item("Add green node", ITEM_NEW_GREEN_NODE)
	add_separator()
	add_icon_item(preload("res://scenes/menus/new.svg"), "New", ITEM_NEW, KEY_MASK_CTRL | KEY_N)
	add_icon_item(preload("res://scenes/menus/open.svg"), "Open...", ITEM_OPEN, KEY_MASK_CTRL | KEY_O)
	if Settings.reopen_file != "":
		add_item("Reopen " + Settings.reopen_file.get_file(), ITEM_REOPEN)
	add_icon_item(preload("res://scenes/menus/save.svg"), "Save", ITEM_SAVE, KEY_MASK_CTRL | KEY_S)
	# TODO about and help?
	add_separator()
	add_item("Quit", ITEM_QUIT, KEY_MASK_CTRL | KEY_Q)


func _on_ContextMenu_popup_hide():
	queue_free()
