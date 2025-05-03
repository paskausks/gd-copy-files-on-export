@tool
extends EditorExportPlugin

const MESSAGE_FORMAT: String = "[copy_files_on_export] %s"

var zip_path: String = ""
var _features: PackedStringArray

func _get_name() -> String:
	return "Copy Files On Export"


func _export_begin(features: PackedStringArray, _is_debug: bool, path: String, _flags: int) -> void:
	var path_lower: String = path.to_lower()
	var is_macos: bool = "macos" in features
	var is_zip: bool = path_lower.ends_with(".zip")

	_features = features

	if (is_zip and not is_macos) or path_lower.ends_with("pck"):
		# "Export PCK/ZIP..." option, ignore, unless its MacOS, then
		# we can't really tell that option apart
		return

	if is_zip and is_macos:
		# For MacOS a temp directory is not created, so we'll just append
		# to the zip file that's created.
		zip_path = path
		return

	# we don't have to handle ZIP manually for windows and linux, as for ZIP
	# exports, godot will just pass a tmp folder (e.g. /tmp/gamename/foo.exe)
	# here which will be compressed into the final ZIP.
	var export_path: String = path.get_base_dir()

	if not len(export_path):
		return

	for file_set: CFOEFileSet in _get_files():
		var file_set_features: PackedStringArray = file_set.features

		if len(file_set_features) and not _feature_match(features, file_set_features):
			continue

		_copy(file_set.source, export_path.path_join(file_set.dest))


func _export_end() -> void:
	if not len(zip_path):
		return

	# handle MacOS ZIP export
	var writer: ZIPPacker = ZIPPacker.new()
	var err: Error = writer.open(zip_path, ZIPPacker.ZipAppend.APPEND_ADDINZIP)

	if err != OK:
		_push_err("Could not open the zip file %s for writing! Aborting." % zip_path)
		zip_path = ""
		return

	for file_set: CFOEFileSet in _get_files():
		var file_set_features: PackedStringArray = file_set.features

		if len(file_set_features) and not _feature_match(_features, file_set_features):
			continue

		_write_to_zip(writer, file_set.source, file_set.dest)

	zip_path = ""
	writer.close_file()


func _get_files() -> Array[CFOEFileSet]:
	return CFOESettings.get_files()


func _push_err(error: String) -> void:
	push_error(MESSAGE_FORMAT % error)


func _log(info: String) -> void:
	print(MESSAGE_FORMAT % info)


func _feature_match(requested_features: PackedStringArray, limited_features: PackedStringArray) -> bool:
	for feature: String in limited_features:
		if feature in requested_features:
			return true
	return false


func _copy(source_path: String, dest_path: String) -> void:
	var base: String = dest_path.get_base_dir()

	if not DirAccess.dir_exists_absolute(base):
		var err: int = DirAccess.make_dir_recursive_absolute(base)
		if err != OK:
			push_error("Error creating destination path \"%s\". Skipping." % base)
			return

	if DirAccess.dir_exists_absolute(source_path):
		var sub_paths: PackedStringArray = DirAccess.get_files_at(source_path) 
		sub_paths.append_array(DirAccess.get_directories_at(source_path))

		for sub_path in sub_paths:
			if _ignore_path(source_path.path_join(sub_path)):
				continue
			_copy(source_path.path_join(sub_path), dest_path.path_join(sub_path))
		return

	var source_data: PackedByteArray = FileAccess.get_file_as_bytes(source_path)

	if not len(source_data):
		_push_err("Error reading or file empty - \"%s\"! Skipping." % source_path)
		return

	var dest: FileAccess = FileAccess.open(dest_path, FileAccess.WRITE)

	if not dest:
		_push_err("Error opening destination for \"%s\" writing! Skipping." % dest_path)
		return

	dest.store_buffer(source_data)
	dest.close()

	_log("Copied \"%s\"" % source_path)


func _write_to_zip(zip_packer: ZIPPacker, source_path: String, dest_path: String) -> void:
	if DirAccess.dir_exists_absolute(source_path):
		var sub_paths: PackedStringArray = DirAccess.get_files_at(source_path) 
		sub_paths.append_array(DirAccess.get_directories_at(source_path))

		for sub_path in sub_paths:
			if _ignore_path(source_path.path_join(sub_path)):
				continue
			_write_to_zip(zip_packer, source_path.path_join(sub_path), dest_path.path_join(sub_path))
		return

	var source_data: PackedByteArray = FileAccess.get_file_as_bytes(source_path)

	if not len(source_data):
		_push_err("Error reading \"%s\" or file empty! Skipping." % source_path)
		return

	if zip_packer.start_file(dest_path) != OK:
		_push_err("Error adding \"%s\" to target ZIP! Skipping." % dest_path)
		return

	if zip_packer.write_file(source_data) != OK:
		_push_err("Error writing to \"%s\" in target ZIP! Skipping." % dest_path)
		return

	_log("Wrote \"%s\" to the target ZIP" % source_path)


func _ignore_path(path: String) -> bool:
	# i don't think anyone actually needs "import" and "guid" files to be copied.
	return not DirAccess.dir_exists_absolute(path) and (path.ends_with(".import") or path.ends_with(".uid"))
