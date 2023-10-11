extends Node2D


func _ready():
	var e = $Icon as Node2D
	var t = e.create_tween()
	t.tween_property(e, "position", e.position + Vector2(100,100), 2)
	t.play()

func _on_back_pressed():
	SceneHandler.change_main_scene(Shared.SCENES[Shared.SCENES_ENUM.main_menu], 0)
	if get_parent() == get_tree().root:
		queue_free()