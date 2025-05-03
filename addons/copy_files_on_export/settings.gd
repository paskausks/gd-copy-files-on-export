@tool
class_name CFOESettings extends Control

const ICON_EDIT: Texture2D = preload("res://addons/copy_files_on_export/assets/edit.svg")
const ICON_DELETE: Texture2D = preload("res://addons/copy_files_on_export/assets/remove.svg")
const PopupScene: PackedScene = preload("res://addons/copy_files_on_export/manage_item_popup.tscn")

# in project settings the file list is stored as an array of strings
const SETTING_FILES: String = "copy_files_on_export/files"
const SETTING_ARR_SOURCE: int = 0
const SETTING_ARR_DEST: int = 1
const SETTING_ARR_FEATURES: int = 2

const COL_SOURCE: int = 0
const COL_DESTINATION: int = 1
const COL_FEATURES: int = 2
const COL_TOOLS: int = 3

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
		func(arr: PackedStringArray) -> bool:
			return arr[SETTING_ARR_SOURCE] != path
	))


static func get_files() -> Array[CFOEFileSet]:
	var result: Array[CFOEFileSet] = []

	if not ProjectSettings.has_setting(SETTING_FILES):
		return result

	result.assign(
		get_settings_file_list().filter(
			func(arr: PackedStringArray) -> bool: return len(arr) > 2
		).map(
			func(arr: PackedStringArray) -> CFOEFileSet:
				var features: PackedStringArray

				if len(arr) == 2:
					# handle v0.1.0 data which did not have features yet
					features = PackedStringArray()
				else:
					var features_raw: String = arr[SETTING_ARR_FEATURES]
					if not len(features_raw):
						features = PackedStringArray()
					else:
						# can't map() a PackedStringArray yet.
						var features_arr: PackedStringArray = features_raw.split(",")
						for i: int in len(features_arr):
							features_arr[i] = features_arr[i].strip_edges()
						features = features_arr

				return CFOEFileSet.create(
					arr[SETTING_ARR_SOURCE],
					arr[SETTING_ARR_DEST],
					features,
				),
		)
	)

	return result


func add_treeitem(source: String, dest: String, features: String) -> TreeItem:
	var item: TreeItem = tree.create_item(tree_root)
	item.set_text(COL_SOURCE, source)
	item.set_text(COL_DESTINATION, dest)
	item.set_text(COL_FEATURES, features)
	item.add_button(COL_TOOLS, ICON_EDIT, BUTTON_ID_EDIT, false, tr("Edit"))
	item.add_button(COL_TOOLS, ICON_DELETE, BUTTON_ID_DELETE, false, tr("Delete"))
	return item


func update_item(source: String, dest: String, features: String, idx: int) -> void:
	var item: TreeItem
	var file_list: Array[PackedStringArray] = get_settings_file_list()
	if idx == -1:
		file_list.append(PackedStringArray([source, dest, features]))
		item = add_treeitem(source, dest, features)
		tree.scroll_to_item(item)
	else:
		item = tree_root.get_child(idx)
		item.set_text(COL_SOURCE, source)
		item.set_text(COL_DESTINATION, dest)
		item.set_text(COL_FEATURES, features)

		var entry: PackedStringArray = file_list[idx]
		entry[SETTING_ARR_SOURCE] = source
		entry[SETTING_ARR_DEST] = dest

		if len(entry) == 2:
			# v0.1.0 entry
			entry.append(features)
		else:
			entry[SETTING_ARR_FEATURES] = features

	set_settings_file_list(file_list)


func remove_item(item: TreeItem) -> void:
	var source: String = item.get_text(COL_SOURCE)
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
		scene.title = tr("Edit file or directory...")
		scene.destination_path = item.get_text(COL_DESTINATION)
		scene.source_path = item.get_text(COL_SOURCE)
		scene.features = item.get_text(COL_FEATURES)
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
			scene.title = tr("Add File or Directory...")
			scene.item_update_requested.connect(update_item)
			scene.show()
	)


func _setup_tree() -> void:
	tree.set_column_title(COL_SOURCE, tr("Path"))
	tree.set_column_title_alignment(COL_SOURCE, HORIZONTAL_ALIGNMENT_LEFT)
	tree.set_column_expand(COL_SOURCE, true)

	tree.set_column_title(COL_DESTINATION, tr("Path in export location"))
	tree.set_column_title_alignment(COL_DESTINATION, HORIZONTAL_ALIGNMENT_LEFT)

	tree.set_column_title(COL_FEATURES, tr("Limited to features"))
	tree.set_column_title_alignment(COL_FEATURES, HORIZONTAL_ALIGNMENT_LEFT)

	tree.set_column_expand(COL_TOOLS, false)

	tree.button_clicked.connect(_on_tree_button_clicked)

	for arr in get_settings_file_list():
		add_treeitem(arr[SETTING_ARR_SOURCE], arr[SETTING_ARR_DEST], arr[SETTING_ARR_FEATURES] if len(arr) > 2 else "")
