@tool
class_name CFOEManageItemPopup
extends Window

signal item_update_requested(source: String, dest: String, features: String, index: int)


@export var source_path: String
@export var destination_path: String
@export var features: String
@export var index: int = -1
@export var action_text: String = tr("Add")

@onready var destination_text_edit: LineEdit = %DestinationTextEdit
@onready var add_button: Button = %AddButton
@onready var file_dialog: FileDialog = %FileDialog
@onready var source_path_text_edit: LineEdit = %SourcePathTextEdit
@onready var source_error_label: Label = %SourceErrorLabel
@onready var path_error_label: Label = %PathErrorLabel


func _ready() -> void:
	(%CloseButton as Button).pressed.connect(_close_window)
	(%FilePopupButton as Button).pressed.connect(_open_file_dialog)

	var features_line_edit: LineEdit = %FeaturesLineEdit
	add_button.pressed.connect(
		func() -> void:
			item_update_requested.emit(source_path_text_edit.text, destination_text_edit.text, features_line_edit.text, index)
			_close_window()
	)

	destination_text_edit.text = destination_path
	destination_text_edit.text_changed.connect(_validate.unbind(1))

	source_path_text_edit.text = source_path
	file_dialog.current_path = source_path

	features_line_edit.text = features

	add_button.text = action_text

	file_dialog.file_selected.connect(_on_dialog_path_selected)
	file_dialog.dir_selected.connect(_on_dialog_path_selected)

	close_requested.connect(_close_window)

	_validate()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		_close_window()


func _validate() -> void:
	var valid: bool = true

	_set_source_error("")
	_set_dest_error("")

	var destination_text: String = destination_text_edit.text
	if not len(destination_text):
		valid = false
	elif not destination_text.get_file().is_valid_filename():
		_set_dest_error(tr("Path invalid!"))
		valid = false

	var source_text: String = source_path_text_edit.text
	if not len(source_text):
		valid = false
	elif not FileAccess.file_exists(source_text) and not DirAccess.dir_exists_absolute(source_text):
		_set_source_error(tr("Source path does not exist!"))
		valid = false

	add_button.disabled = not valid


func _set_source_error(text: String) -> void:
	source_error_label.text = text


func _set_dest_error(text: String) -> void:
	path_error_label.text = text


func _close_window() -> void:
	queue_free()


func _open_file_dialog() -> void:
	file_dialog.show()


func _on_dialog_path_selected(path: String) -> void:
	source_path_text_edit.text = path

	if not len(destination_text_edit.text):
		destination_text_edit.text = path.get_file()

	_validate()
