extends Control

@export var main_menu: PackedScene

func _ready():
	var v = get_node_or_null('Background/Version')
	if v is Label:
		v.text = BuildTools.get_build_stamp()
	
	var node_title = get_node("Background/Title")
	if node_title is Label:
		node_title.text = ProjectSettings.get_setting("application/config/name", "Game Title")

func _on_timer_timeout():
	if main_menu != null:
		SceneHandler.change_main_scene(Shared.SCENES[Shared.SCENES_ENUM.main_menu])
		if get_parent() == get_tree().root:
			queue_free()

func _input(event: InputEvent):
	if event is InputEventKey or \
		event is InputEventMouseButton or \
		event is InputEventJoypadButton or \
		event is InputEventScreenTouch:
		_on_timer_timeout()