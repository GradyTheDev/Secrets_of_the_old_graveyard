class_name Ghost
extends Area2D

@onready var node_chase: AudioStreamPlayer2D = get_node("Chase")
@onready var node_appear: AudioStreamPlayer2D = get_node("Appear")
@onready var node_disappear: AudioStreamPlayer2D = get_node("Disappear")
@onready var node_sprite: Sprite2D = get_node("Sprite")
@onready var node_animator: AnimationPlayer = get_node("Animator")
@onready var node_line: Line2D = get_node("NavLine")

@export var speed: float

var _time_since_pathing: float
var current_path: Array[Vector2]
var _move_to: Vector2 = -Vector2.ONE

func _ready():
	node_line.visible = OS.is_debug_build()
# 	Shared.time_of_day_changed.connect(_time_of_day_changed) # doesn't work for some reason

func _enter_tree():
	Shared.active_ghosts.append(self)

func _exit_tree():
	Shared.active_ghosts.erase(self)

func _prime():
	current_path.clear()
	calculate_path()
	_time_since_pathing = 0
	if current_path.size() > 1:
		current_path.pop_at(0)
	node_line.clear_points()
	for x in current_path:
		node_line.add_point(x)

func _physics_process(delta):
	if node_animator.current_animation == 'appear':
		return

	_time_since_pathing += delta
	var dis_from_player := Graveyard.world_to_grid(global_position).distance_to(Graveyard.world_to_grid(Shared.player.global_position))

	if dis_from_player > 5:
		if _time_since_pathing > 2:
			_prime()
	elif dis_from_player > 1:
		if _time_since_pathing > 0.5:
			_prime()
	elif _time_since_pathing > 0.5:
		_prime()
	if _move_to == -Vector2.ONE:
		_prime()
		
	if current_path.size() != 0:
		_move_to = current_path[0]
		if position.distance_to(_move_to) < 1:
			_move_to = position
			current_path.pop_at(0)
	
	if _move_to != position:
		var dis = global_position.distance_to(Shared.player.global_position)
		var s = speed
		if dis/24.0 < 3.0:
			s * 0.5
		
		Graveyard.set_nav_weight(position)
		position = position.move_toward(_move_to, s * delta)
		Graveyard.set_nav_weight(position, 99)

		


func _time_of_day_changed(daytime: bool):
	if daytime:
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


## Overwrite this
func calculate_path():
	## basic chasing player ai
	current_path.append_array(Graveyard.nav_to(global_position, Shared.player.global_position))