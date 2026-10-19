extends SceneTree
## State-transition smoke test. Run: godot --headless --path . --script res://tests/SmokeTest.gd
## Unlike source grepping, exercises quests, boss, items, roles, persistence.
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, title: String) -> void:
	if condition:
		print("PASS: " + title)
	else:
		failures += 1
		push_error("FAIL: " + title)

func _complete_dialogue(game: Node2D, count: int) -> void:
	for i in range(count):
		game._next_dialogue()

func _run() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn") as PackedScene
	if scene == null:
		push_error("Main scene is missing")
		quit(1)
		return
	var game: Node2D = scene.instantiate() as Node2D
	root.add_child(game)
	await process_frame
	for role in range(3):
		game._new_game(role)
		_check(game.role == role and game.hp == game.max_hp, "role " + str(role) + " starts with correct stats")
	game._new_game(0)
	_check(game.quest_stage == 0 and game.enemy_data[0]["node"].visible == false, "no forced combat at spawn")
	game.hero.position.x = 270.0
	game._interact()
	_check(game.dialogue_panel.visible, "elder opens story dialogue")
	_complete_dialogue(game, 4)
	_check(game.quest_stage == 1, "elder activates quest")
	var locs: Array[Vector2] = [Vector2(830, 550), Vector2(1055, 412), Vector2(1260, 550)]
	for loc in locs:
		game.hero.position = loc
		game._try_pickup()
	_check(game.fragments == 3 and game.quest_stage == 2, "three unique fragments advance quest")
	game.hero.position = Vector2(700, 567)
	game._interact()
	_complete_dialogue(game, 3)
	_check(game.quest_stage == 3, "smith repairs sword and opens forest")
	_check(game.enemy_data[0]["node"].visible, "forest foes spawn only when gate opens")
	game.hero.position = Vector2(475, 567)
	var gold_before: int = game.gold
	var pots_before: int = game.potions
	game._interact()
	_check(game.gold == gold_before - 80 and game.potions == pots_before + 1, "merchant charges gold and delivers healing item")
	for i in range(3):
		var e: Dictionary = game.enemy_data[i]
		game.hero.position = Vector2((e["node"] as Node2D).position.x - 70, (e["node"] as Node2D).position.y)
		game.facing = 1
		game._strike(999, 110)
	_check(game.defeated.count(true) == 3 and game.quest_stage == 4, "three foes and XP unlock altar")
	game.hero.position = Vector2(2615, 550)
	game._interact()
	_complete_dialogue(game, 3)
	_check(game.altar_purified and game.quest_stage == 5, "altar changes persistent world state")
	var boss: Dictionary = game.enemy_data[3]
	game.hero.position = Vector2((boss["node"] as Node2D).position.x - 90, (boss["node"] as Node2D).position.y)
	game.facing = 1
	game._strike(999, 125)
	_check(game.boss_defeated and game.quest_stage == 6, "boss death unlocks return quest")
	game.hero.position = Vector2(270, 567)
	game._interact()
	_complete_dialogue(game, 4)
	_check(game.quest_stage == 7, "chapter ends with covenant and reward")
	game._save_game()
	game._new_game(1)
	_check(game.quest_stage == 0, "fresh role selection resets game")
	game._load_game()
	_check(game.quest_stage == 7 and game.boss_defeated and game.role == 0, "save reload restores completed chapter and chosen role")
	if failures == 0:
		print("SMOKE TEST PASS: all opening-through-boss transitions")
	else:
		push_error("SMOKE TEST FAILED: " + str(failures))
	quit(1 if failures > 0 else 0)
