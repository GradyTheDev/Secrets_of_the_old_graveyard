extends Ghost

var _tim: float = 0

func _ready():
	super._ready()


func _physics_process(delta):
	_tim += delta
	
	if _tim > 15:
		_tim = 0
	elif _tim > 10:
		super._physics_process(delta)



# func calculate_path():
# 	var pos = Graveyard.get_nearest_grid_intersection(position)
# 	var old = Graveyard.get_nav_weight(pos)
# 	Graveyard.set_nav_weight(pos, 10)
# 	super.calculate_path()
# 	Graveyard.set_nav_weight(pos)
