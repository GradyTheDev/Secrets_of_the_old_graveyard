extends Ghost

var _tim: float = 0

func _ready():
	super._ready()


func _physics_process(delta):
	_tim += delta
	
	if _tim > 10:
		_tim = 0
	elif _tim > 5:
		super._physics_process(delta)


func calculate_path():
	super.calculate_path()
	var pos = current_path[-2]
	var old = Graveyard.get_nav_weight(pos)
	Graveyard.set_nav_weight(pos, 15)
	current_path.clear()
	super.calculate_path()
	Graveyard.set_nav_weight(pos, old)
	
	