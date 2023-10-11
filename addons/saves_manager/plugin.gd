@tool
extends EditorPlugin

const scene_handler := ['SavesManager', "res://addons/saves_manager/saves_manager.gd"]


func _enter_tree():
	# Initialization of the plugin goes here.
	add_autoload_singleton(scene_handler[0], scene_handler[1])


func _exit_tree():
	# Clean-up of the plugin goes here.
	add_autoload_singleton(scene_handler[0], scene_handler[1])
