@tool
extends EditorExportPlugin

var zip_path: String = ""

func _get_name() -> String:
	return "Copy Files On Export"


func _export_begin(features: PackedStringArray, _is_debug: bool, path: String, _flags: int) -> void:
	var path_lower: String = path.to_lower()
	var is_macos: bool = "macos" in features
	var is_zip: bool = path_lower.ends_with(".zip")

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
		var dest_path: String = export_path.path_join(file_set.dest)
		var base: String = dest_path.get_base_dir()

		if not DirAccess.dir_exists_absolute(base):
			var err: int = DirAccess.make_dir_recursive_absolute(base)
			if err != OK:
				push_error("Error creating destination path \"%s\". Skipping." % base)
				continue

		var source_data: PackedByteArray = FileAccess.get_file_as_bytes(file_set.source)

		if not len(source_data):
			_push_err("Error reading or file empty - \"%s\"! Skipping." % file_set.source)
			continue

		var dest: FileAccess = FileAccess.open(dest_path, FileAccess.WRITE)

		if not dest:
			_push_err("Error opening destination for \"%s\" writing! Skipping." % dest_path)
			continue

		dest.store_buffer(source_data)
		dest.close()


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
		var source_data: PackedByteArray = FileAccess.get_file_as_bytes(file_set.source)
		if not len(source_data):
			_push_err("Error reading \"%s\" or file empty! Skipping." % file_set.source)
			continue

		if writer.start_file(file_set.dest) != OK:
			_push_err("Error adding \"%s\" to target ZIP! Skipping." % file_set.dest)
			continue

		if writer.write_file(source_data) != OK:
			_push_err("Error writing to \"%s\" in target ZIP! Skipping." % file_set.dest)
			continue

	zip_path = ""
	writer.close_file()


func _get_files() -> Array[CFOEFileSet]:
	return CFOESettings.get_files()


func _push_err(error: String) -> void:
	push_error("[copy_files_on_export] %s" % error)
