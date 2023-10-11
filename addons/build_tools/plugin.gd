@tool
extends EditorPlugin

var export_tools = null

func _enter_tree():
	if export_tools == null:
		export_tools = load("res://addons/build_tools/export_tools.gd").new()

	# Initialization of the plugin goes here.
	add_export_plugin(export_tools)

	BuildTools.ensure_setting(
		BuildTools.SETTING_VERSION,
		true,
		TYPE_STRING,
		'0.0.0',
		BuildTools.SETTING_DEFAULTS[BuildTools.SETTING_VERSION],
		PROPERTY_HINT_PLACEHOLDER_TEXT,
		'major.mid.minor.alpha/beta/RCx'
	)

	BuildTools.ensure_setting(
		BuildTools.SETTING_INCLUDE_GIT_COMMIT,
		true,
		TYPE_BOOL,
		false,
		BuildTools.SETTING_DEFAULTS[BuildTools.SETTING_INCLUDE_GIT_COMMIT],
		PROPERTY_HINT_NONE,
		false
	)

	BuildTools.ensure_setting(
		BuildTools.SETTING_INCLUDE_DATETIME,
		true,
		TYPE_BOOL,
		true,
		BuildTools.SETTING_DEFAULTS[BuildTools.SETTING_INCLUDE_DATETIME],
		PROPERTY_HINT_NONE,
		false
	)

	BuildTools.ensure_export_folders()

func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_export_plugin(export_tools)
	export_tools = null

	BuildTools.remove_setting(BuildTools.SETTING_VERSION)
	BuildTools.remove_setting(BuildTools.SETTING_INCLUDE_GIT_COMMIT)
	BuildTools.remove_setting(BuildTools.SETTING_INCLUDE_DATETIME)