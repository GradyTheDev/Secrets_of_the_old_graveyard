extends Control

func _enter_tree():
	SceneHandler.main_scene_container.paused = true

func _exit_tree():
	SceneHandler.main_scene_container.paused = false

func _on_back_button_up():
	queue_free()
