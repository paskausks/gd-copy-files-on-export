@tool
extends EditorPlugin


var export_plugin: EditorExportPlugin
var settings_window: Control


func _enter_tree() -> void:
	CFOESettings.initialize()

	export_plugin = (load(_get_path("copy_files_on_export.gd")) as GDScript).new()
	add_export_plugin(export_plugin)

	settings_window = (load(_get_path("settings.tscn")) as PackedScene).instantiate()
	add_control_to_container(CONTAINER_PROJECT_SETTING_TAB_RIGHT, settings_window)


func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	remove_control_from_container(CONTAINER_PROJECT_SETTING_TAB_RIGHT, settings_window)


func _get_path(sub_path: String) -> String:
	@warning_ignore("unsafe_method_access")
	return get_script().resource_path.get_base_dir().path_join(sub_path)
