extends Node

signal unloading_game_save
signal saving_game
signal saved_game

signal loading_game
signal loaded_game

signal unloading_settings
signal saving_settings
signal saved_settings

signal loading_settings
signal loaded_settings

signal setting_changed(key, value)
signal game_value_changed(key, value)

# Saves Manager
#
# just a simple system nothing more, using Godot's [ConfigFile] class.
# using combined keys aka "section:key" to get/set values from the [ConfigFile]
#
# Each save file has a "file id"

var _path_settings := ["user://", "settings.cfg", "user://settings.cfg"]
var _path_game_saves := ["user://", "saves", "user://saves"]


var _current_settings: ConfigFile = ConfigFile.new()
var _current_game_save: ConfigFile = ConfigFile.new()
## Array of file names (excluding extension and path)
var _detected_game_saves: PackedStringArray

## don't include file extention or path
var _setting_key_last_game_save_filename := 'SavesManager:last_game_saves_filename'

# scan game saves folder

# load settings from file
# save settings to file

# load game from file
# save game to file

#

# set setting
# get setting

# set game value
# load game value

func _ready():
	if FileAccess.file_exists(_path_settings[-1]):
		load_settings_from_file()
	else:
		save_settings_to_file()

## returns string filename
## returns "default" (null) if no game was last, or other issue occurs
func get_last_game_name(default = null) -> Variant:
	return get_setting(_setting_key_last_game_save_filename, default)

func scan_game_saves_folder():
	_detected_game_saves.clear()
	if DirAccess.dir_exists_absolute(_path_game_saves[-1]):
		_detected_game_saves = DirAccess.get_files_at(_path_game_saves[-1])

	var last_game := get_last_game_name()
	if last_game == null or last_game.replace(' ', '') == '' or not last_game in _detected_game_saves:
		set_setting(_setting_key_last_game_save_filename, null)

## Returns one of the [Error] code constants ([OK] on success).
func load_settings_from_file() -> int:
	if not FileAccess.file_exists(_path_settings[-1]): 
		print("Failed ", ERR_FILE_NOT_FOUND ," to load settings from ", _path_settings[-1])
		return ERR_FILE_NOT_FOUND
	
	var config = ConfigFile.new()
	var err = config.load(_path_settings[-1])
	if err != OK: 
		print("Failed ", err ," to load settings from ", _path_settings[-1])
		return err
	
	unloading_settings.emit()
	_current_settings = config
	loading_settings.emit()
	loaded_settings.emit()

	if err != OK:
		print("Failed ", err ," to load settings from ", _path_settings[-1])

	return OK

## Returns one of the [Error] code constants ([OK] on success).
func save_settings_to_file() -> int:
	if not DirAccess.dir_exists_absolute(_path_settings[0]):
		var err = DirAccess.make_dir_recursive_absolute(_path_settings[0])
		if err != OK:
			print("Failed ", err ," to save settings to ", _path_settings[-1])
			return err

	saving_settings.emit()
	var err = _current_settings.save(_path_settings[-1])
	saved_settings.emit()

	if err != OK:
		print("Failed ", err ," to save settings to ", _path_settings[-1])

	return err

## Returns one of the [Error] code constants ([OK] on success).
func load_game_from_file(file_name: String = get_last_game_name('')) -> int:
	var path = _path_game_saves[-1] + '/' + file_name + '.cfg'

	if not FileAccess.file_exists(path): 
		print("Failed ", ERR_FILE_NOT_FOUND ," to load game ", path)
		return ERR_FILE_NOT_FOUND
	
	var config = ConfigFile.new()
	var err = config.load(path)
	if err != OK: 
		print("Failed ", err ," to load game ", path)
		return err
	
	unloading_game_save.emit()
	_current_game_save = config
	set_setting(_setting_key_last_game_save_filename, file_name)
	loading_settings.emit()
	loaded_settings.emit()

	if err != OK:
		print("Failed ", err ," to load game ", path)

	return OK

## Returns one of the [Error] code constants ([OK] on success).
func save_game_to_file(file_name: String = get_last_game_name('')) -> int:
	var path = _path_game_saves[-1] + '/' + file_name + '.cfg'

	if not DirAccess.dir_exists_absolute(_path_game_saves[-1]):
		var err = DirAccess.make_dir_recursive_absolute(_path_game_saves[-1])
		if err != OK:
			print("Failed ", err ," to save game to ", path)
			return err
	
	saving_settings.emit()
	var err = _current_game_save.save(path)
	saved_settings.emit()

	if err != OK:
		print("Failed ", err ," to load game ", path)

	return err

func set_setting(key: String, value):
	if not _current_settings is ConfigFile:
		print("Failed to set setting, as the settings container is null; ", key, ' = ', value)
		return
	
	var sk = key.split(':', false, 1)
	if len(sk) != 2:
		print("Failed to set setting, key is incorrectly formatted; ", key, ' = ', value)
		return

	_current_settings.set_value(sk[0], sk[1], value)
	setting_changed.emit(key, value)

func get_setting(key: String, default = null) -> Variant:
	if not _current_settings is ConfigFile:
		print("Failed to get setting, as the settings container is null; ", key)
		return null
	
	var sk = key.split(':', false, 1)
	if len(sk) != 2:
		print("Failed to get setting, key is incorrectly formatted; ", key)
		return null
	
	return _current_settings.get_value(sk[0], sk[1], default)

func get_game_value(key: String, default = null) -> Variant:
	if not _current_game_save is ConfigFile:
		print("Failed to get game value, as the game save container is null; ", key)
		return null
	
	var sk = key.split(':', false, 1)
	if len(sk) != 2:
		print("Failed to get game value, key is incorrectly formatted; ", key)
		return null
	
	return _current_game_save.get_value(sk[0], sk[1], default)
	
func set_game_value(key: String, value):
	if not _current_game_save is ConfigFile:
		print("Failed to set game value, the game save container is null; ", key, ' = ', value)
		return
	
	var sk = key.split(':', false, 1)
	if len(sk) != 2:
		print("Failed to set game value, the key is incorrectly formatted; ", key, ' = ', value)
		return

	_current_game_save.set_value(sk[0], sk[1], value)
	game_value_changed.emit(key, value)
