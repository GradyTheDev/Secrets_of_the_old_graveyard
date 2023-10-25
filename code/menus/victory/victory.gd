extends Control

@onready var node_credits = get_node("ClipCredits/Credits") as RichTextLabel

func _ready():
	if self.get_parent() == get_tree().root:
		get_parent().remove_child.call_deferred(self)
		get_node("/root/SceneHandler/Main").add_child.call_deferred(self)

	node_credits.position = Vector2(0, -node_credits.size.y)
	var t = node_credits.create_tween()
	t.tween_interval(5) # wait for cutscene to end
	
	# roll credits
	var pos = Vector2(0, -node_credits.size.y)
	var time = node_credits.get_line_count() * 2
	t.tween_callback(_here)
	t.tween_property(node_credits, 'position', pos, time)
	t.tween_callback(SceneHandler.change_main_scene.bind(Shared.SCENES[Shared.SCENES_ENUM.main_menu]))
	t.play()

func _here():
	node_credits.position = Vector2(0, node_credits.size.y)

func _on_main_menu_pressed():
	if get_parent() == get_tree().root:
		queue_free()
	SceneHandler.change_main_scene(Shared.SCENES[Shared.SCENES_ENUM.main_menu])
	

