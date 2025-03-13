@tool
class_name CFOEManageItemPopup
extends Window

signal item_upsert_requested(source: String, dest: String)


@export var source_path: String
@export var destination_path: String
@export var action_text: String = tr("Add")

@onready var destination_text_edit: LineEdit = %DestinationTextEdit
@onready var add_button: Button = %AddButton
@onready var file_dialog: FileDialog = %FileDialog
@onready var source_file_text_edit: LineEdit = %SourceFileTextEdit


func _ready() -> void:
	(%CloseButton as Button).pressed.connect(_close_window)
	(%FilePopupButton as Button).pressed.connect(_open_file_dialog)
	add_button.pressed.connect(
		func() -> void:
			item_upsert_requested.emit(source_file_text_edit.text, destination_text_edit.text)
			_close_window()
	)

	destination_text_edit.text = destination_path
	destination_text_edit.text_changed.connect(_validate.unbind(1))

	source_file_text_edit.text = source_path
	file_dialog.current_path = source_path
	add_button.text = action_text

	file_dialog.file_selected.connect(_on_file_dialog_selected)

	close_requested.connect(_close_window)

	_validate()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		_close_window()


func _validate() -> void:
	var valid: bool = true

	var destination_text: String = destination_text_edit.text
	if not len(destination_text) or not destination_text.get_file().is_valid_filename():
		valid = false

	if not FileAccess.file_exists(source_file_text_edit.text):
		valid = false

	add_button.disabled = not valid


func _close_window() -> void:
	queue_free()


func _open_file_dialog() -> void:
	file_dialog.show()


func _on_file_dialog_selected(path: String) -> void:
	source_file_text_edit.text = path
	_validate()
