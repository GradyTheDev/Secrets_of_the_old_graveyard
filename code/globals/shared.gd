extends Node

enum SCENES_ENUM {
	main_menu,
	credits,
	victory,
}

var SCENES: Array[PackedScene]

enum POPUPS_ENUM {
	settings,
	pause
}

var POPUPS: Array[PackedScene]

const SETTING_KEY_WINDOW_WIDTH := 'window:width'
const SETTING_KEY_WINDOW_HEIGHT := 'window:height'
const SETTING_KEY_WINDOW_MODE := 'window:mode'
const SETTING_KEY_WINDOW_SCREEN := 'window:screen'

const SETTING_KEY_AUDIO_MASTER := 'audio_bus:master'
const SETTING_KEY_AUDIO_MUSIC := 'audio_bus:music'
const SETTING_KEY_AUDIO_SFX := 'audio_bus:sfx'
const SETTING_KEY_AUDIO_UI := 'audio_bus:ui'
const SETTING_KEY_AUDIO_VOICE := 'audio_bus:voice'

enum AUDIO_BUS_INDEX {
	SETTING_KEY_AUDIO_MASTER = 0,
	SETTING_KEY_AUDIO_MUSIC = 1,
	SETTING_KEY_AUDIO_SFX = 2,
	SETTING_KEY_AUDIO_UI = 3,
	SETTING_KEY_AUDIO_VOICE = 4,
}

const AUDIO_BUS_NAMES := {
	SETTING_KEY_AUDIO_MASTER: 'Master',
	SETTING_KEY_AUDIO_MUSIC: 'Music',
	SETTING_KEY_AUDIO_SFX: 'SFX',
	SETTING_KEY_AUDIO_UI: 'UI',
	SETTING_KEY_AUDIO_VOICE: 'Voice',
}

signal time_of_day_changed(daytime: bool)
var game_time: float: set = _set_game_time
var game_cycle: float
var day_night_cycle_duration: float = 30
var daytime: bool = true : set = _set_daytime

var items: Array
var grave: PackedScene
var ghosts: Array[PackedScene]
var player: Node2D

var active_items: Array[Item]
var active_ghosts: Array[Ghost]

var scroll_win_count: int = 13

func _set_daytime(v: bool):
	daytime = v
	time_of_day_changed.emit(daytime)
	for x in active_ghosts:
		# not emitting to the ghosts for some reason
		x._time_of_day_changed(daytime)
	print('daytime: ', v)

func _set_game_time(new: float):
	game_time = new
	game_cycle = get_game_cycle()
	if game_cycle > 0:
		# Day
		if not daytime:
			daytime = true
	else:
		# Night
		if daytime:
			daytime = false


## -1.0 to 1.0 [br]
## -1 is night [br]
## 1 is day [br]
func get_game_cycle() -> float:
	return sin(((game_time - floor(game_time / (game_time * 2))) / day_night_cycle_duration) * PI)

func _ready():
	var v = load("res://code/menus/loading/loading_screen.tscn") as PackedScene
	SceneHandler.current_loading_screen = v.instantiate()

	# SCENES
	SCENES.append(load('res://code/menus/main/main_menu.tscn'))
	SCENES.append(load('res://code/menus/credits/credits.tscn'))
	SCENES.append(load('res://code/menus/victory/victory.tscn'))
	
	assert(len(SCENES_ENUM) == len(SCENES), self.name+": SCENES and it's enum doesn't have the same number of elements")
	for key in SCENES_ENUM:
		var scene = SCENES[SCENES_ENUM[key]]
		assert(scene is PackedScene, self.name+": Something went wrong with a scene in SCENES, enum key = " + str(key))

	# POPUPS
	POPUPS.append(load('res://code/menus/settings/settings.tscn'))
	POPUPS.append(load('res://code/menus/pause/pause.tscn'))
	
	assert(len(POPUPS_ENUM) == len(POPUPS), self.name+": POPUPS and it's enum doesn't have the same number of elements")
	for key in POPUPS_ENUM:
		var scene = POPUPS[POPUPS_ENUM[key]]
		assert(scene is PackedScene, self.name+": Something went wrong with a scene in POPUPS, enum key = " + str(key))

	SavesManager.setting_changed.connect(_on_setting_changed)

	# Items
	items.append(load("res://code/items/dagger.tscn"))
	items.append(load("res://code/items/eye.tscn"))

	grave = load("res://code/other/grave/grave.tscn")

	ghosts.append(load("res://code/entities/ghost_1/ghost_1.tscn"))
	ghosts.append(load("res://code/entities/ghost_2/ghost_2.tscn"))
	ghosts.append(load("res://code/entities/ghost_3/ghost_3.tscn"))

func get_random_ghost() -> Ghost:
	return ghosts[randi_range(0, ghosts.size()-1)].instantiate()

func _on_setting_changed(key: String, value):
	match key:
		SETTING_KEY_WINDOW_WIDTH:
			get_window().size = Vector2i(value, get_window().size.y)
		SETTING_KEY_WINDOW_HEIGHT:
			get_window().size = Vector2i(get_window().size.x, value)
		SETTING_KEY_WINDOW_MODE:
			if typeof(value) != TYPE_STRING: return
			var w = get_window()
			match value:
				'fullscreen':
					w.borderless = false
					w.exclusive = false
					w.mode = Window.MODE_FULLSCREEN
				'exclusive':
					w.borderless = false
					w.exclusive = true
					w.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
				'windowed':
					w.borderless = false
					w.exclusive = false
					w.mode = Window.MODE_WINDOWED
				'borderless':
					w.borderless = false
					w.exclusive = false
					w.mode = Window.MODE_WINDOWED
		SETTING_KEY_WINDOW_SCREEN:
			_set_display(value)
		SETTING_KEY_AUDIO_MASTER:
			_set_audio_bus_volume(AUDIO_BUS_INDEX.SETTING_KEY_AUDIO_MASTER, value)
		SETTING_KEY_AUDIO_MUSIC:
			_set_audio_bus_volume(AUDIO_BUS_INDEX.SETTING_KEY_AUDIO_MUSIC, value)
		SETTING_KEY_AUDIO_SFX:
			_set_audio_bus_volume(AUDIO_BUS_INDEX.SETTING_KEY_AUDIO_SFX, value)
		SETTING_KEY_AUDIO_UI:
			_set_audio_bus_volume(AUDIO_BUS_INDEX.SETTING_KEY_AUDIO_UI, value)
		SETTING_KEY_AUDIO_VOICE:
			_set_audio_bus_volume(AUDIO_BUS_INDEX.SETTING_KEY_AUDIO_VOICE, value)


## used when setting is changed, not for external use
func _set_audio_bus_volume(bus: AUDIO_BUS_INDEX, value):
	var type = typeof(value)
	if type == TYPE_INT:
		value = float(value)
		type = TYPE_FLOAT
	
	if type != TYPE_FLOAT:
		return
	
	value = clampf(value, -30, 30)
	value = snappedf(value, 0.01)
	AudioServer.set_bus_volume_db(bus, value)

## used when setting is changed, not for external use
func _set_display(value):
	var type = typeof(value)
	if type != TYPE_INT:
		return

	var screens = DisplayServer.get_screen_count()
	if value < 0 or value >= screens:
		return
	
	get_window().current_screen = value
	


func _input(event):
	

	if event is InputEventKey:
		if not event.is_pressed():
			match event.keycode:
				KEY_F11:
					var m = DisplayServer.window_get_mode()
					if m == DisplayServer.WINDOW_MODE_FULLSCREEN:
						DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
					else:
						DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

			if not OS.is_debug_build(): return
			match event.keycode:
				KEY_PAGEUP:
					game_time = 29
				KEY_PAGEDOWN:
					game_time = 0.1
				KEY_HOME:
					player.scrolls = 0
				KEY_END:
					player.scrolls += 1