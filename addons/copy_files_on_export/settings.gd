@tool
class_name CFOESettings extends Control

const ICON_EDIT: Texture2D = preload("res://addons/copy_files_on_export/assets/edit.svg")
const ICON_DELETE: Texture2D = preload("res://addons/copy_files_on_export/assets/remove.svg")
const PopupScene: PackedScene = preload("res://addons/copy_files_on_export/manage_item_popup.tscn")

# in project settings the file list is stored as an array of string pairs
const SETTING_FILES: String = "copy_files_on_export/files"
const SETTING_PAIR_FILE: int = 0
const SETTING_PAIR_DEST: int = 1

const COL_FILE: int = 0
const COL_DESTINATION: int = 1
const COL_TOOLS: int = 2

const BUTTON_ID_EDIT: int = 0
const BUTTON_ID_DELETE: int = 1


@onready var tree: Tree = %Tree
@onready var tree_root: TreeItem = tree.create_item()


func _ready() -> void:
	_setup_add()
	_setup_tree()


static func initialize() -> void:
	var init: Array[PackedStringArray] = []
	if not ProjectSettings.has_setting(SETTING_FILES):
		ProjectSettings.set_setting(SETTING_FILES, init)
		ProjectSettings.save()

	ProjectSettings.set_initial_value(SETTING_FILES, init)
	ProjectSettings.set_as_internal(SETTING_FILES, true)


static func get_settings_file_list() -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []

	@warning_ignore("unsafe_call_argument")
	result.assign(ProjectSettings.get_setting(SETTING_FILES))

	return result


static func set_settings_file_list(new_list: Array[PackedStringArray]) -> void:
	ProjectSettings.set_setting(SETTING_FILES, new_list)
	ProjectSettings.save()


static func remove_file(path: String) -> void:
	var current_list: Array[PackedStringArray] = get_settings_file_list()
	set_settings_file_list(current_list.filter(
		func(pair: PackedStringArray) -> bool:
			return pair[SETTING_PAIR_FILE] != path
	))


static func get_files() -> Array[CFOEFileSet]:
	var result: Array[CFOEFileSet] = []

	if not ProjectSettings.has_setting(SETTING_FILES):
		return result

	result.assign(
		get_settings_file_list().filter(
			func(pair: PackedStringArray) -> bool: return len(pair) == 2
		).map(
			func(pair: PackedStringArray) -> CFOEFileSet: return CFOEFileSet.create(pair[SETTING_PAIR_FILE], pair[SETTING_PAIR_DEST])
		)
	)

	return result


func add_treeitem(source: String, dest: String) -> TreeItem:
	var item: TreeItem = tree.create_item(tree_root)
	item.set_text(COL_FILE, source)
	item.set_text(COL_DESTINATION, dest)
	item.add_button(COL_TOOLS, ICON_EDIT, BUTTON_ID_EDIT, false, tr("Edit"))
	item.add_button(COL_TOOLS, ICON_DELETE, BUTTON_ID_DELETE, false, tr("Delete"))
	return item


func update_item(source: String, dest: String, idx: int) -> void:
	var item: TreeItem
	var file_list: Array[PackedStringArray] = get_settings_file_list()
	if idx == -1:
		file_list.append(PackedStringArray([source, dest]))
		item = add_treeitem(source, dest)
		tree.scroll_to_item(item)
	else:
		item = tree_root.get_child(idx)
		item.set_text(COL_FILE, source)
		item.set_text(COL_DESTINATION, dest)

		file_list[idx][SETTING_PAIR_FILE] = source
		file_list[idx][SETTING_PAIR_DEST] = dest

	set_settings_file_list(file_list)


func remove_item(item: TreeItem) -> void:
	var source: String = item.get_text(COL_FILE)
	remove_file(source)
	item.free()


func _on_tree_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int) -> void:
	if column != COL_TOOLS:
		return

	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return

	if id == BUTTON_ID_DELETE:
		remove_item(item)
		return

	if id == BUTTON_ID_EDIT:
		var scene: CFOEManageItemPopup = PopupScene.instantiate()
		scene.title = tr("Edit file...")
		scene.destination_path = item.get_text(COL_DESTINATION)
		scene.source_path = item.get_text(COL_FILE)
		scene.index = item.get_index()
		scene.action_text = tr("Edit")
		scene.item_update_requested.connect(update_item, CONNECT_ONE_SHOT)
		add_child(scene)
		scene.show()


func _setup_add() -> void:
	(%AddButton as Button).pressed.connect(
		func() -> void:
			var scene: CFOEManageItemPopup = PopupScene.instantiate()
			add_child(scene)
			scene.title = tr("Add file...")
			scene.item_update_requested.connect(update_item)
			scene.show()
	)


func _setup_tree() -> void:
	tree.set_column_title(COL_FILE, tr("File"))
	tree.set_column_title_alignment(COL_FILE, HORIZONTAL_ALIGNMENT_LEFT)
	tree.set_column_expand(COL_FILE, true)

	tree.set_column_title(COL_DESTINATION, tr("Path in export location"))
	tree.set_column_title_alignment(COL_DESTINATION, HORIZONTAL_ALIGNMENT_LEFT)

	tree.set_column_expand(COL_TOOLS, false)

	tree.button_clicked.connect(_on_tree_button_clicked)

	for pair in get_settings_file_list():
		add_treeitem(pair[SETTING_PAIR_FILE], pair[SETTING_PAIR_DEST])
