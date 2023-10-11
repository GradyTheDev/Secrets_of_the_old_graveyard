extends EditorExportPlugin

func _get_name() -> String:
	return "build_date_updater"

func _export_begin (
	features: PackedStringArray,
	is_debug: bool,
	path: String,
	flags: int ):
	# ProjectSettings.save() # Don't save, or you'll have constant Git changes to deal with

	var build_stamp = BuildTools.generate_build_stamp(features, is_debug)
	BuildTools.ensure_setting(
		BuildTools.SETTING_INTERNAL_BUILD_STAMP, 
		true,
		TYPE_STRING,
		build_stamp,
		BuildTools.SETTING_DEFAULTS[BuildTools.SETTING_INTERNAL_BUILD_STAMP],
		0,
		'',
		false)
	print(BuildTools.get_build_stamp())

func _export_end():
	BuildTools.remove_setting(BuildTools.SETTING_INTERNAL_BUILD_STAMP)