extends Control

func _ready():
	if get_parent() == get_tree().root:
		# this is only used when deploying from the editor
		# when you launch this specific scene from the editor
		await get_tree().process_frame
		await get_tree().process_frame
		get_parent().remove_child(self)
		SceneHandler.change_main_scene(self)
		await get_tree().process_frame
		await get_tree().process_frame
	
	SceneHandler.add_popup(Shared.POPUPS[Shared.POPUPS_ENUM.pause])