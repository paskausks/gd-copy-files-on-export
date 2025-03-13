class_name CFOEFileSet

var source: String
var dest: String


static func create(new_source: String, new_dest: String) -> CFOEFileSet:
	var instance: CFOEFileSet = CFOEFileSet.new()
	instance.source = new_source
	instance.dest = new_dest
	return instance
