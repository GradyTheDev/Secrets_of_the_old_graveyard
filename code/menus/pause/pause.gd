extends Control

func _enter_tree():
	get_tree().paused = true

func _exit_tree():
	get_tree().paused = false

func _input(event):
	if event.is_action("ui_cancel") and Input.is_action_just_released("ui_cancel"):
		get_parent().remove_child.call_deferred(self)

func _on_back_button_up():
	get_parent().remove_child.call_deferred(self)

func _on_main_menu_pressed():
	SceneHandler.change_main_scene.call_deferred(Shared.SCENES[Shared.SCENES_ENUM.main_menu])
	_on_back_button_up()