class_name BuildTools
extends GDScript

const SETTING_VERSION := "application/buildtools/version"
const SETTING_INCLUDE_GIT_COMMIT := "application/buildtools/include_git_commit"
# UTC datetime
const SETTING_INCLUDE_DATETIME := "application/buildtools/include_datetime"

# UTC datetime
const SETTING_INTERNAL_BUILD_STAMP := "application/buildtools/build_stamp"

const SETTING_DEFAULTS = {
	SETTING_VERSION: '0.0.0',
	SETTING_INCLUDE_GIT_COMMIT: false,
	SETTING_INCLUDE_DATETIME: true,
	SETTING_INTERNAL_BUILD_STAMP: null
}

static func ensure_setting(
	name: String, 
	basic: bool,
	value_type: int,
	value,
	default_value,
	hint_type: PropertyHint = 0,
	hint_value = '',
	overwrite: bool = false):

	var info = {
		'name': name,
		'type': value_type,
		'hint': hint_type,
		'hint_string': hint_value,
	}
	if not ProjectSettings.has_setting(name) or overwrite:
		# add setting only if it doesn't exist, unless overwrite is chosen
		ProjectSettings.set_setting(name, value)
	
	# make sure to add the setting's info each time
	ProjectSettings.add_property_info(info)
	ProjectSettings.set_as_basic(name, basic)
	ProjectSettings.set_initial_value(name, default_value) # if you don't change this value it will not be recorded in the project.godot


static func remove_setting(name: String):
	if ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, null)


static func get_custom_setting(name: String):
	return ProjectSettings.get_setting(name, SETTING_DEFAULTS[name])


static func generate_build_stamp(
	features: PackedStringArray,
	is_debug: bool) -> String:
	var parts = []

	parts.append(ProjectSettings.get_setting("application/config/name", ''))
	
	if 'running_in_editor' in features:
		parts.append('in editor')

	if 'web' in features:
		parts.append('web')
	elif 'linux' in features:
		parts.append('linux')
	elif 'windows' in features:
		parts.append('windows')
	elif 'macos' in features:
		parts.append('macos')
	
	if is_debug:
		parts.append('debug')

	parts.append(get_custom_setting(BuildTools.SETTING_VERSION))

	if get_custom_setting(BuildTools.SETTING_INCLUDE_DATETIME):
		parts.append('%s UTC' % Time.get_datetime_string_from_system(true, true))
	
	if get_custom_setting(BuildTools.SETTING_INCLUDE_GIT_COMMIT):
		parts.append('git?')
		pass
	
	return ' '.join(parts).rstrip(' ')


static func get_build_stamp() -> String:
	var stamp = get_custom_setting(SETTING_INTERNAL_BUILD_STAMP)
	if stamp == null:
		stamp = generate_build_stamp([OS.get_name().to_lower(), 'running_in_editor'], OS.is_debug_build())
	return stamp


static func ensure_export_folders():
	DirAccess.make_dir_recursive_absolute('res://exports/linux')
	DirAccess.make_dir_recursive_absolute('res://exports/windows')
	DirAccess.make_dir_recursive_absolute('res://exports/mac')
	DirAccess.make_dir_recursive_absolute('res://exports/web')
	DirAccess.make_dir_recursive_absolute('res://exports/android')
	DirAccess.make_dir_recursive_absolute('res://exports/ios')
	DirAccess.make_dir_recursive_absolute('res://exports/templates')
	if not FileAccess.file_exists('res://exports/.gdignore'):
		var f = FileAccess.open('res://exports/.gdignore', FileAccess.WRITE)
		f.flush()