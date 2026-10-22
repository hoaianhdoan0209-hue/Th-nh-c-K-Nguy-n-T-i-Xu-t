extends SceneTree
## Real rendered stills; run with a display and an OpenGL renderer.
func _initialize() -> void:
	call_deferred("_run")

func _capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image.save_png(path) != OK:
		push_error("Could not write " + path)

func _run() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn") as PackedScene
	var game: Variant = scene.instantiate()
	root.add_child(game)
	await process_frame
	DirAccess.make_dir_recursive_absolute("res://captures")
	game._begin_story(0)
	await _capture("res://captures/opening.png")
	for i in range(4):
		game._next_dialogue()
	game.touch_right = true
	for i in range(45):
		await physics_frame
	game.touch_right = false
	game._perform_action("jump")
	for i in range(20):
		await physics_frame
	await _capture("res://captures/jump.png")
	game.quest_stage = 3
	game._refresh_world()
	game.hero.position = Vector2(1550, 567)
	game.camera.reset_smoothing()
	for i in range(30):
		await physics_frame
	game._normal_attack()
	await _capture("res://captures/combat.png")
	quit()
