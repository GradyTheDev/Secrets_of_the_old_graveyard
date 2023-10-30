extends Ghost

func calculate_path():
	super.calculate_path()
	if current_path.size() > 5:
		var pos = current_path[-2]
		var old = Graveyard.get_nav_weight(pos)
		Graveyard.set_nav_weight(pos, 15)
		current_path.clear()
		super.calculate_path()
		Graveyard.set_nav_weight(pos, old)
	
	