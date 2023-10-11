extends Control

func _on_start_button_up():
	# TODO: Replace this
	SceneHandler.change_main_scene("res://code/levels/lvl_1/lvl_1.tscn", 2, 3)


func _on_settings_button_up():
	SceneHandler.add_popup(Shared.POPUPS[Shared.POPUPS_ENUM.settings])


func _on_credits_button_up():
	SceneHandler.add_popup(Shared.SCENES[Shared.SCENES_ENUM.credits])


func _on_exit_button_up():
	if OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		get_tree().quit()
