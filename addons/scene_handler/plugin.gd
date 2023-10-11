@tool
extends EditorPlugin

const scene_handler := ['SceneHandler', "res://addons/scene_handler/scene_handler.tscn"]

func _enter_tree():
	# Initialization of the plugin goes here.
	add_autoload_singleton(scene_handler[0], scene_handler[1])


func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_autoload_singleton(scene_handler[0])
