class_name Ghost
extends Area2D

@onready var node_chase: AudioStreamPlayer2D = get_node("Chase")
@onready var node_appear: AudioStreamPlayer2D = get_node("Appear")
@onready var node_disappear: AudioStreamPlayer2D = get_node("Disappear")
@onready var node_sprite: Sprite2D = get_node("Sprite")
@onready var node_animator: AnimationPlayer = get_node("Animator")

func _ready():
	Shared.time_of_day_changed.connect(_time_of_day_changed)


func _time_of_day_changed(daytime: bool):
	node_animator.play("disappear")


func _on_animation_finished(anim_name: StringName):
	if anim_name != 'chase' and node_chase.playing:
		node_chase.stop()
	
	match anim_name:
		"disappear":
			queue_free()
		"chase":
			node_animator.play('chase')
		"appear":
			pass


func _on_animator_animation_started(anim_name: StringName):
	if anim_name == "chase":
		if not node_chase.playing:
			node_chase.play()


func _on_animator_animation_changed(old_name:StringName, new_name:StringName):
	if old_name == "chase" and new_name != old_name:
		if node_chase.playing:
			node_chase.stop()


func _on_body_entered(v: Node2D):
	if v == Shared.player:
		v.die()
