extends Node

## SceneHandler
##
## Todo: add loading screen functionality
## set loading screen
## remove loading screen

## emitted before node is queued for deletion [br]
## [member current_main_scene_node] still has the old scene
signal unloading_main_scene()

## emitted after node is deleted
signal unloaded_main_scene()

## emitted after the scene is created but before it's added to the tree [br]
## [member current_main_scene_node] has the new scene
## this is for loading stuff into the main scene, before it enters the tree
signal loading_main_scene()

## emitted after the scene is added to the tree
## this is for loading stuff into the main scene, after it enters the tree and has completly loaded
## but the loading screen is still up, for a split second
signal loaded_main_scene()

## emitted after the scene is created but before it's added to the tree[br]
## also called when moving popup to the front
signal adding_popup(popup)

## emitted after the scene is added to the tree[br]
## also called when moving popup to the front
signal added_popup(popup)

## emitted before node is removed from the tree; not queued for deletion yet
signal removing_popup(popup)

## emitted after the node is removed from the tree, but right before queing it for deletion
signal removed_popup(popup)

@onready var main_scene_container = get_node("Main") as Node
@onready var popups_container = get_node("Popups") as Node
@onready var loading_screen_container = get_node("Loading") as Node

## main scenes are freed when changing scenes
var current_main_scene_node: Node = null
## loading screen isn't freed until this node exits the tree
var current_loading_screen: Node = null

## when loading a resource(s) from file
## 100 = complete
var loading_progress: float = 0

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		var c = popups_container.get_children()
		if len(c) == 0: return
		popups_container.remove_child(c[-1])

func _exit_tree():
	if is_instance_valid(current_loading_screen):
		current_loading_screen.queue_free()

## this func blocks until everything in the [member main_scene_container] has been completly removed from the tree. (uses queue_free)
## use call_deferred, to run this in the background
## await this function to block until this func completes
func unload_main_scene():
	main_scene_container.process_mode = Node.PROCESS_MODE_DISABLED
	unloading_main_scene.emit()
	current_main_scene_node = null
	for x in main_scene_container.get_children():
		x.queue_free()
	while main_scene_container.get_child_count() > 0:
		await get_tree().create_timer(0.1).timeout
	unloaded_main_scene.emit()
	

## use_loading_screen: 0 = don't, 1 = use if resource isn't loaded in cache, 2 = always show loading screen
## this func blocks until the scene has been loaded, scene placed into the tree, and the scene is_ready
## use call_deferred, to run this in the background
## await this function to block until this func completes
## value can be [PackedScene], [Node], or [String] (path)
## min_time_show_loading_screen is in milliseconds
func change_main_scene(value, use_loading_screen: int = 0, min_time_show_loading_screen: float = 0):
	if use_loading_screen > 1 or \
		(use_loading_screen == 1 and (value is String and not ResourceLoader.has_cached(value))):
		if is_instance_valid(current_loading_screen) and current_loading_screen is Node:
			if current_loading_screen.is_inside_tree():
				current_loading_screen.get_parent().remove_child(current_loading_screen)
			loading_screen_container.add_child(current_loading_screen)
	
	unload_main_scene()

	if value is String:
		if not ResourceLoader.has_cached(value):
			var rid = ResourceLoader.load_threaded_request(value)
			var progress = []
			var status = 0
			while true:
				await get_tree().create_timer(0.1).timeout
				status = ResourceLoader.load_threaded_get_status(value, progress)
				loading_progress = progress[0] * 100
				if status != ResourceLoader.THREAD_LOAD_LOADED and \
					status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
					print(self.name + ": ERROR ", status, " when loading next main scene", value)
					return
				elif status == ResourceLoader.THREAD_LOAD_LOADED:
					break
		value = ResourceLoader.load_threaded_get(value)
	
	if value is PackedScene:
		value = value.instantiate()
	
	if not value is Node:
		print(self.name + ": Failed to load next main scene, reason unknown ", value)
		return

	current_main_scene_node = value
	loading_main_scene.emit()
	main_scene_container.add_child(current_main_scene_node)
	while is_instance_valid(current_main_scene_node) and \
		not current_main_scene_node.is_node_ready():
		await get_tree().create_timer(0.1).timeout
	loaded_main_scene.emit()
	
	if is_instance_valid(current_loading_screen) and \
		current_loading_screen is Node \
		and current_loading_screen.is_inside_tree():
		await get_tree().create_timer(clamp(min_time_show_loading_screen, 0.01, 10)).timeout
		current_loading_screen.get_parent().remove_child(current_loading_screen)
	
	main_scene_container.process_mode = Node.PROCESS_MODE_INHERIT

func add_popup(pack_or_path_or_node) -> Node:
	var popup: Node = null

	if pack_or_path_or_node is Node:
		popup = pack_or_path_or_node 
	else:
		var pck: PackedScene = null
		if pack_or_path_or_node is String:
			pck = load(pack_or_path_or_node) as PackedScene
		elif pack_or_path_or_node is PackedScene:
			pck = pack_or_path_or_node
		
		if not pck is PackedScene:
			print("Failed to add popup invalid type: ", pack_or_path_or_node)
			return null
		popup = pck.instantiate()
	
	adding_popup.emit(popup)
	if popup.get_parent() == popups_container:
		bring_popup_to_front(popup)
	elif popup.is_inside_tree():
		assert(false, "ERROR: Popup exists outside of the popup container" + str(popup.get_path()))
	else:
		popups_container.add_child(popup)
	added_popup.emit(popup)
	return popup


func remove_popup(popup: Node):
	if popup.is_inside_tree() and popup.get_parent() == popups_container:
		removing_popup.emit(popup)
		popups_container.remove_child(popup)
		removed_popup.emit(popup)
		popup.queue_free()


func clear_all_popups():
	for popup in popups_container.get_children():
		removing_popup.emit(popup)
		popups_container.remove_child(popup)
		removed_popup.emit(popup)
		popup.queue_free()


func bring_popup_to_front(popup: Node):
	adding_popup.emit(popup)
	popups_container.move_child(popup, -1)
	added_popup.emit(popup)
