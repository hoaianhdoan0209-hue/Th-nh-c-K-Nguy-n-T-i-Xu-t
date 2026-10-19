extends Node2D
## Game 9 — Original first-chapter vertical slice.
## Godot 4.x GDScript. Three linked zones, quest state machine, role skills,
## NPCs, telegraphed combat, inventory, XP and durable local save.
## Real Godot runtime playtest pending until an engine runner is available.

const WIDTH: float = 4200.0
const FLOOR_Y: float = 610.0
const GRAVITY: float = 1600.0
const SPEED: float = 285.0
const JUMP_SPEED: float = -770.0
const SAVE_PATH: String = "user://thanh_uoc_save.cfg"

const ROLE_NAMES: Array[String] = ["Vệ Ước", "Tinh Thuật Sư", "Thánh Y"]
const ROLE_ART: Array[String] = [
	"res://assets/guardian.svg",
	"res://assets/scholar.svg",
	"res://assets/healer.svg"
]
const QUESTS: Array[String] = [
	"Gặp Bà Mộc bên cây đèn thánh.",
	"Nhặt 3 mảnh thần tích trong Làng Tro Sáng.",
	"Mang mảnh thần tích đến Thợ rèn Vân.",
	"Đánh bại 3 sinh vật Vực tại Rừng Tàn Quang.",
	"Thanh tẩy tế đàn ở cuối Rừng Tàn Quang.",
	"Đánh bại Kẻ Giữ Vực trong Đền Phong Ấn.",
	"Trở về Làng Tro Sáng, nói chuyện với Bà Mộc.",
	"Chương I hoàn thành: Thánh Ước Đầu Tiên."
]
const NPCS: Array[Dictionary] = [
	{"x": 270.0, "name": "Bà Mộc", "kind": "elder", "art": "elder"},
	{"x": 475.0, "name": "Thương nhân Nghi", "kind": "shop", "art": "shop"},
	{"x": 700.0, "name": "Thợ rèn Vân", "kind": "smith", "art": "smith"},
	{"x": 1090.0, "name": "Trinh sát Diệp", "kind": "scout", "art": "scout"}
]

var started: bool = false
var role: int = 0
var hero_name: String = "Người Giữ Ước"
var quest_stage: int = 0
var fragments: int = 0
var collected: Array[bool] = [false, false, false]
var defeated: Array[bool] = [false, false, false]
var boss_defeated: bool = false
var altar_purified: bool = false
var gold: int = 100
var potions: int = 1
var level: int = 1
var xp: int = 0
var hp: int = 170
var max_hp: int = 170
var mp: int = 80
var max_mp: int = 80
var attack_power: int = 20

var hero: CharacterBody2D
var hero_visual: Sprite2D
var world: Node2D
var camera: Camera2D
var enemy_data: Array[Dictionary] = []
var pickup_nodes: Array[Node2D] = []
var altar_sprite: Sprite2D
var gate_village: Label
var gate_temple: Label

var hud_layer: CanvasLayer
var ui: Control
var title_panel: Control
var name_input: LineEdit
var hp_text: Label
var mp_text: Label
var stats_text: Label
var quest_text: Label
var zone_text: Label
var hint_text: Label
var notice_text: Label
var detail_panel: Panel
var detail_text: Label
var dialogue_panel: Panel
var dialogue_name: Label
var dialogue_text: Label
var dialogue_lines: Array[String] = []
var dialogue_index: int = 0
var dialogue_result: String = ""
var active_detail: String = ""
var notice_left: float = 0.0

var touch_left: bool = false
var touch_right: bool = false
var jump_queued: bool = false
var facing: int = 1
var combo_index: int = 0
var combo_left: float = 0.0
var attack_cd: float = 0.0
var skill_cd: float = 0.0
var dash_left: float = 0.0
var dash_cd: float = 0.0
var invincible_left: float = 0.0
var guard_left: float = 0.0
var mp_recovery: float = 0.0

func _ready() -> void:
	_build_world()
	_build_hero()
	_build_ui()
	_refresh_world()
	_update_hud()

func _build_world() -> void:
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	for i in range(3):
		var bg := Sprite2D.new()
		if i == 0:
			bg.texture = load("res://assets/bg_village.svg") as Texture2D
		elif i == 1:
			bg.texture = load("res://assets/bg_forest.svg") as Texture2D
		else:
			bg.texture = load("res://assets/bg_temple.svg") as Texture2D
		bg.position = Vector2(float(i) * 1400.0 + 700.0, 360.0)
		world.add_child(bg)
		var ground := ColorRect.new()
		ground.color = Color("#263b3b") if i == 0 else (Color("#26312f") if i == 1 else Color("#303044"))
		ground.position = Vector2(float(i) * 1400.0, FLOOR_Y)
		ground.size = Vector2(1400.0, 110.0)
		world.add_child(ground)
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(WIDTH / 2.0, FLOOR_Y + 60.0)
	var floor_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(WIDTH, 120.0)
	floor_shape.shape = rect
	floor_body.add_child(floor_shape)
	world.add_child(floor_body)
	_make_platform(930.0, 458.0, 210.0)
	_make_platform(1720.0, 440.0, 230.0)
	_make_platform(2150.0, 457.0, 215.0)
	_make_platform(3180.0, 447.0, 220.0)
	for n in NPCS:
		var npc := Sprite2D.new()
		npc.texture = load("res://assets/npc_%s.svg" % str(n["art"])) as Texture2D
		npc.position = Vector2(float(n["x"]), FLOOR_Y - 63.0)
		world.add_child(npc)
		var nametag := _world_label(str(n["name"]), Vector2(float(n["x"]) - 93.0, FLOOR_Y - 148.0), 16)
		world.add_child(nametag)
	for i in range(3):
		var item := Sprite2D.new()
		item.texture = load("res://assets/fragment.svg") as Texture2D
		item.position = Vector2([830.0, 1055.0, 1260.0][i], [550.0, 412.0, 550.0][i])
		world.add_child(item)
		pickup_nodes.append(item)
	altar_sprite = Sprite2D.new()
	altar_sprite.texture = load("res://assets/altar.svg") as Texture2D
	altar_sprite.position = Vector2(2615.0, FLOOR_Y - 91.0)
	world.add_child(altar_sprite)
	world.add_child(_world_label("Tế đàn Thất Ước [E]", Vector2(2525.0, FLOOR_Y - 180.0), 17))
	gate_village = _world_label("CỔNG RỪNG: CẦN SỬA KIẾM", Vector2(1245.0, 325.0), 16)
	world.add_child(gate_village)
	gate_temple = _world_label("PHONG ẤN: CẦN THANH TẨY", Vector2(2675.0, 320.0), 16)
	world.add_child(gate_temple)
	_spawn_enemy(0, 1650.0, "Bóng Đen", "enemy_wisp", 73, 8)
	_spawn_enemy(1, 2010.0, "Lính Vực", "enemy_knight", 95, 12)
	_spawn_enemy(2, 2330.0, "Thú Biến Dị", "enemy_beast", 125, 15)
	_spawn_enemy(3, 3530.0, "Kẻ Giữ Vực", "boss", 360, 23)

func _make_platform(x: float, y: float, width: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x, y)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 15.0)
	shape.shape = rect
	shape.one_way_collision = true
	body.add_child(shape)
	world.add_child(body)
	var platform := ColorRect.new()
	platform.color = Color("#a9cbb1")
	platform.size = Vector2(width, 15.0)
	platform.position = Vector2(-width * 0.5, -7.5)
	body.add_child(platform)

func _world_label(value: String, at: Vector2, size: int) -> Label:
	var lbl := Label.new()
	lbl.text = value
	lbl.position = at
	lbl.custom_minimum_size.x = 188.0
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", Color("#fff4d6"))
	lbl.add_theme_color_override("font_shadow_color", Color("#101627"))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	return lbl

func _spawn_enemy(idx: int, x: float, label: String, art: String, health: int, damage: int) -> void:
	var root := Node2D.new()
	root.position = Vector2(x, FLOOR_Y - 70.0)
	var spr := Sprite2D.new()
	spr.texture = load("res://assets/%s.svg" % art) as Texture2D
	root.add_child(spr)
	var name_label := _world_label(label, Vector2(-66.0, -116.0), 15)
	root.add_child(name_label)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color("#5d2237")
	bar_bg.position = Vector2(-43.0, -88.0)
	bar_bg.size = Vector2(86.0, 8.0)
	root.add_child(bar_bg)
	var bar := ColorRect.new()
	bar.color = Color("#f1c785")
	bar.position = Vector2(-43.0, -88.0)
	bar.size = Vector2(86.0, 8.0)
	root.add_child(bar)
	world.add_child(root)
	enemy_data.append({
		"node": root, "sprite": spr, "bar": bar, "idx": idx,
		"home": x, "name": label, "hp": health, "maxhp": health,
		"damage": damage, "cool": 1.6, "windup": 0.0,
		"attack_range": 115.0 if idx != 3 else 170.0,
		"dead": false, "alerted": false
	})

func _build_hero() -> void:
	hero = CharacterBody2D.new()
	hero.position = Vector2(100.0, FLOOR_Y - 43.0)
	hero.collision_layer = 1
	hero.collision_mask = 1
	var body_shape := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 22.0
	cap.height = 85.0
	body_shape.shape = cap
	hero.add_child(body_shape)
	hero_visual = Sprite2D.new()
	hero_visual.texture = load(ROLE_ART[0]) as Texture2D
	hero_visual.position = Vector2(0.0, -16.0)
	hero.add_child(hero_visual)
	world.add_child(hero)
	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_right = int(WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 720
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.5
	hero.add_child(camera)
	camera.make_current()
	hero.visible = false

func _build_ui() -> void:
	hud_layer = CanvasLayer.new()
	add_child(hud_layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_layer.add_child(ui)
	var header := Panel.new()
	header.position = Vector2(12, 12)
	header.size = Vector2(440, 139)
	header.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.077, 0.13, 0.85)))
	ui.add_child(header)
	hp_text = _label_at(ui, "", Vector2(25, 18), Vector2(420, 28), 20)
	mp_text = _label_at(ui, "", Vector2(25, 47), Vector2(420, 24), 17)
	stats_text = _label_at(ui, "", Vector2(25, 75), Vector2(420, 22), 17)
	zone_text = _label_at(ui, "", Vector2(25, 106), Vector2(420, 26), 16)
	quest_text = _label_at(ui, "", Vector2(490, 16), Vector2(780, 63), 20)
	quest_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice_text = _label_at(ui, "", Vector2(475, 98), Vector2(785, 50), 19)
	notice_text.add_theme_color_override("font_color", Color("#fff2a1"))
	hint_text = _label_at(ui, "[E] Tương tác   [J] Đánh   [K] Kỹ năng   [L] Né   [H] Hồi máu", Vector2(22, 657), Vector2(950, 30), 16)
	for spec in [
		["TÚI [I]", "inventory", 708.0],
		["NV [Q]", "quest", 814.0],
		["BĐ [M]", "map", 910.0],
		["LƯU", "save", 1005.0],
		["TẢI", "load", 1100.0]
	]:
		var action := str(spec[1])
		var btn := _button(ui, str(spec[0]), Vector2(float(spec[2]), 168.0), Vector2(92, 40))
		btn.pressed.connect(_perform_action.bind(action))
	var controls := [
		{"text": "◀", "action": "left", "pos": Vector2(24, 551), "size": Vector2(74, 76)},
		{"text": "▶", "action": "right", "pos": Vector2(111, 551), "size": Vector2(74, 76)},
		{"text": "NHẢY", "action": "jump", "pos": Vector2(890, 540), "size": Vector2(84, 84)},
		{"text": "ĐÁNH", "action": "attack", "pos": Vector2(990, 560), "size": Vector2(74, 70)},
		{"text": "THÁNH ƯỚC", "action": "skill", "pos": Vector2(1076, 540), "size": Vector2(124, 78)},
		{"text": "NÉ", "action": "dash", "pos": Vector2(1205, 580), "size": Vector2(70, 62)},
		{"text": "NÓI", "action": "interact", "pos": Vector2(780, 555), "size": Vector2(92, 65)}
	]
	for item in controls:
		var b := _button(ui, str(item["text"]), item["pos"], item["size"])
		if str(item["action"]) == "left":
			b.button_down.connect(func() -> void: touch_left = true)
			b.button_up.connect(func() -> void: touch_left = false)
		elif str(item["action"]) == "right":
			b.button_down.connect(func() -> void: touch_right = true)
			b.button_up.connect(func() -> void: touch_right = false)
		else:
			var a := str(item["action"])
			b.pressed.connect(_perform_action.bind(a))
	detail_panel = Panel.new()
	detail_panel.position = Vector2(300, 174)
	detail_panel.size = Vector2(690, 348)
	detail_panel.add_theme_stylebox_override("panel", _panel_style(Color("#18253d")))
	ui.add_child(detail_panel)
	detail_text = _label_at(detail_panel, "", Vector2(25, 24), Vector2(638, 255), 20)
	detail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var close_detail := _button(detail_panel, "ĐÓNG", Vector2(515, 291), Vector2(146, 40))
	close_detail.pressed.connect(_close_detail)
	detail_panel.hide()
	dialogue_panel = Panel.new()
	dialogue_panel.position = Vector2(225, 460)
	dialogue_panel.size = Vector2(830, 206)
	dialogue_panel.add_theme_stylebox_override("panel", _panel_style(Color("#15243e")))
	ui.add_child(dialogue_panel)
	dialogue_name = _label_at(dialogue_panel, "", Vector2(22, 17), Vector2(500, 28), 22)
	dialogue_text = _label_at(dialogue_panel, "", Vector2(22, 55), Vector2(785, 96), 20)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var next_btn := _button(dialogue_panel, "TIẾP ▶", Vector2(666, 157), Vector2(141, 39))
	next_btn.pressed.connect(_next_dialogue)
	dialogue_panel.hide()
	_build_title()

func _build_title() -> void:
	title_panel = Control.new()
	title_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(title_panel)
	var veil := ColorRect.new()
	veil.color = Color(0.025, 0.045, 0.09, 0.97)
	veil.size = Vector2(1280, 720)
	title_panel.add_child(veil)
	_label_at(title_panel, "THÁNH ƯỚC", Vector2(375, 35), Vector2(590, 70), 49)
	_label_at(title_panel, "KỶ NGUYÊN TÁI SINH  •  CHƯƠNG I: TRO SÁNG", Vector2(324, 109), Vector2(730, 43), 22)
	_label_at(title_panel, "Ba trăm năm các vị thần im lặng. Một lời thề vẫn còn sống.", Vector2(273, 172), Vector2(830, 38), 19)
	_label_at(title_panel, "Đặt tên hiệp sĩ:", Vector2(375, 222), Vector2(490, 30), 18)
	name_input = LineEdit.new()
	name_input.position = Vector2(375, 255)
	name_input.size = Vector2(530, 42)
	name_input.text = "Người Giữ Ước"
	name_input.max_length = 22
	title_panel.add_child(name_input)
	_label_at(title_panel, "Chọn MỘT con đường:", Vector2(375, 316), Vector2(540, 30), 20)
	for i in range(3):
		var idx: int = i
		var desc: String = ["HIỆP SĨ • phản công và chịu đòn", "PHÁP SƯ • đánh xa và ấn thuật", "THÁNH Y • chữa lành và thanh tẩy"][i]
		var choice := _button(title_panel, "%s — %s" % [ROLE_NAMES[i], desc], Vector2(306, 359 + 67 * i), Vector2(672, 55))
		choice.pressed.connect(_new_game.bind(idx))
	var load_btn := _button(title_panel, "TIẾP TỤC ĐIỂM LƯU", Vector2(459, 580), Vector2(353, 56))
	load_btn.pressed.connect(_load_game)
	_label_at(title_panel, "Di chuyển A/D, nhảy Space, tương tác E. Có nút cảm ứng khi xoay ngang.", Vector2(265, 651), Vector2(880, 44), 16)

func _panel_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("#8fa3ad")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style

func _label_at(parent: Node, txt: String, at: Vector2, area: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = txt
	label.position = at
	label.size = area
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#f2eee2"))
	parent.add_child(label)
	return label

func _button(parent: Node, txt: String, at: Vector2, area: Vector2) -> Button:
	var button := Button.new()
	button.text = txt
	button.position = at
	button.size = area
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("#fff2dc"))
	button.add_theme_stylebox_override("normal", _panel_style(Color("#314b63")))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#4d7186")))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#997752")))
	parent.add_child(button)
	return button

func _new_game(selected_role: int) -> void:
	role = selected_role
	hero_name = name_input.text.strip_edges()
	if hero_name.is_empty():
		hero_name = "Người Giữ Ước"
	quest_stage = 0
	fragments = 0
	collected = [false, false, false]
	defeated = [false, false, false]
	boss_defeated = false
	altar_purified = false
	gold = 100
	potions = 1
	level = 1
	xp = 0
	_set_role_stats()
	hp = max_hp
	mp = max_mp
	hero.position = Vector2(100, FLOOR_Y - 43)
	for e in enemy_data:
		e["dead"] = false
		e["hp"] = e["maxhp"]
		e["cool"] = 1.6
		e["windup"] = 0.0
	started = true
	hero.visible = true
	title_panel.hide()
	_refresh_world()
	_update_hud()
	_notice("Hãy tìm Bà Mộc. Không cần chiến đấu ngay.")

func _set_role_stats() -> void:
	match role:
		0:
			max_hp = 170 + (level - 1) * 24
			max_mp = 80 + (level - 1) * 11
			attack_power = 22 + (level - 1) * 5
		1:
			max_hp = 110 + (level - 1) * 15
			max_mp = 150 + (level - 1) * 20
			attack_power = 18 + (level - 1) * 5
		2:
			max_hp = 130 + (level - 1) * 18
			max_mp = 130 + (level - 1) * 17
			attack_power = 20 + (level - 1) * 4

func _unhandled_key_input(event: InputEvent) -> void:
	if not started or not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_SPACE, KEY_W, KEY_UP:
			_perform_action("jump")
		KEY_J:
			_perform_action("attack")
		KEY_K:
			_perform_action("skill")
		KEY_L, KEY_SHIFT:
			_perform_action("dash")
		KEY_E:
			_perform_action("interact")
		KEY_I:
			_perform_action("inventory")
		KEY_M:
			_perform_action("map")
		KEY_Q:
			_perform_action("quest")
		KEY_H:
			_perform_action("potion")
		KEY_F5:
			_perform_action("save")
		KEY_F9:
			_perform_action("load")

func _physics_process(delta: float) -> void:
	if notice_left > 0.0:
		notice_left -= delta
		if notice_left <= 0.0:
			notice_text.text = ""
	if not started:
		return
	if attack_cd > 0.0:
		attack_cd -= delta
	if skill_cd > 0.0:
		skill_cd -= delta
	if dash_cd > 0.0:
		dash_cd -= delta
	if combo_left > 0.0:
		combo_left -= delta
		if combo_left <= 0.0:
			combo_index = 0
	if invincible_left > 0.0:
		invincible_left -= delta
	if guard_left > 0.0:
		guard_left -= delta
	if dash_left > 0.0:
		dash_left -= delta
	mp_recovery += delta
	if mp_recovery > 2.0:
		mp_recovery = 0.0
		mp = mini(max_mp, mp + 1)
	if detail_panel.visible or dialogue_panel.visible:
		hero.velocity.x = 0.0
		return
	var dir: int = int(touch_right or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - int(touch_left or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	if dir != 0:
		facing = dir
	hero_visual.flip_h = facing < 0
	hero.velocity.y = minf(hero.velocity.y + GRAVITY * delta, 1050.0)
	if jump_queued:
		if hero.is_on_floor():
			hero.velocity.y = JUMP_SPEED
		jump_queued = false
		_notice("Nhảy qua vật cản và lên bệ đá.")
	if dash_left > 0.0:
		hero.velocity.x = float(facing) * 790.0
	else:
		hero.velocity.x = float(dir) * SPEED
	hero.move_and_slide()
	hero.position.x = clampf(hero.position.x, 32.0, WIDTH - 40.0)
	if quest_stage < 3 and hero.position.x > 1350.0:
		hero.position.x = 1350.0
		_notice("Cần sửa thanh kiếm trước khi vào Rừng Tàn Quang.")
	if quest_stage < 5 and hero.position.x > 2750.0:
		hero.position.x = 2750.0
		_notice("Tế đàn chưa được thanh tẩy; cánh cổng vẫn khóa.")
	if quest_stage == 1:
		_try_pickup()
	if quest_stage >= 3:
		_update_enemies(delta)
	_update_hud()

func _perform_action(action: String) -> void:
	if action == "load":
		_load_game()
		return
	if not started:
		return
	if action == "inventory" or action == "quest" or action == "map":
		_open_detail(action)
		return
	if action == "save":
		_save_game()
		return
	if detail_panel.visible:
		_close_detail()
		return
	if dialogue_panel.visible:
		if action == "interact":
			_next_dialogue()
		return
	match action:
		"jump":
			jump_queued = true
		"attack":
			_normal_attack()
		"skill":
			_use_skill()
		"dash":
			_dash()
		"interact":
			_interact()
		"potion":
			_use_potion()

func _normal_attack() -> void:
	if attack_cd > 0.0:
		return
	attack_cd = 0.33 if role != 1 else 0.42
	combo_index = (combo_index % 3) + 1
	combo_left = 1.0
	var damage: int = attack_power + combo_index * 5
	var reach: float = 140.0 if role == 1 else 105.0
	var hits: int = _strike(damage, reach)
	_notice("Liên kích %d/3 • %d sát thương%s" % [combo_index, damage, " • trúng!" if hits > 0 else ""])

func _use_skill() -> void:
	if skill_cd > 0.0:
		_notice("Thánh thuật đang hồi: %.1f giây." % skill_cd)
		return
	if role == 0:
		if mp < 18:
			_notice("Không đủ thần lực (18 MP).")
			return
		mp -= 18
		skill_cd = 6.0
		guard_left = 3.0
		_strike(attack_power + 20, 155.0)
		_notice("THẾ THỦ: chống chịu 3 giây và phản kích cận chiến!")
	elif role == 1:
		if mp < 28:
			_notice("Không đủ thần lực (28 MP).")
			return
		mp -= 28
		skill_cd = 5.0
		var hit := _strike(attack_power + 55, 360.0)
		_notice("ẤN TINH: tia phép xuyên tới kẻ địch! Trúng %d." % hit)
	else:
		if mp < 22:
			_notice("Không đủ thần lực (22 MP).")
			return
		mp -= 22
		skill_cd = 7.0
		hp = mini(max_hp, hp + 42)
		_strike(attack_power + 28, 185.0)
		_notice("LỜI NGUYỆN: hồi 42 HP và thanh tẩy bóng tối.")

func _dash() -> void:
	if dash_cd > 0.0:
		return
	dash_cd = 2.7
	dash_left = 0.18
	invincible_left = 0.37
	_notice("Lướt né! Miễn thương trong thoáng chốc.")

func _strike(damage: int, reach: float) -> int:
	var hits: int = 0
	for e in enemy_data:
		if bool(e["dead"]) or not (e["node"] as Node2D).visible:
			continue
		var target := e["node"] as Node2D
		var diff: float = target.position.x - hero.position.x
		if float(facing) * diff >= -18.0 and float(facing) * diff <= reach and absf(target.position.y - hero.position.y) < 115.0:
			e["hp"] = int(e["hp"]) - damage
			hits += 1
			(e["sprite"] as Sprite2D).modulate = Color("#ffc2c2")
			(e["bar"] as ColorRect).size.x = 86.0 * maxf(0.0, float(e["hp"]) / float(e["maxhp"]))
			if int(e["hp"]) <= 0:
				_enemy_died(e)
	return hits

func _update_enemies(delta: float) -> void:
	for e in enemy_data:
		if bool(e["dead"]) or not (e["node"] as Node2D).visible:
			continue
		var foe := e["node"] as Node2D
		var sprite := e["sprite"] as Sprite2D
		var distance: float = hero.position.x - foe.position.x
		if absf(distance) > 410.0:
			e["windup"] = 0.0
			e["cool"] = 1.0
			sprite.modulate = Color.WHITE
			continue
		if absf(distance) > float(e["attack_range"]) - 22.0 and float(e["windup"]) <= 0.0:
			foe.position.x += signf(distance) * (46.0 if int(e["idx"]) == 3 else 68.0) * delta
			sprite.flip_h = distance < 0.0
		if float(e["windup"]) > 0.0:
			e["windup"] = float(e["windup"]) - delta
			sprite.modulate = Color("#ff7e76")
			if float(e["windup"]) <= 0.0:
				sprite.modulate = Color.WHITE
				if absf(hero.position.x - foe.position.x) < float(e["attack_range"]) + 25.0 and absf(hero.position.y - foe.position.y) < 100.0:
					_take_damage(int(e["damage"]) * (2 if int(e["idx"]) == 3 and int(e["hp"]) <= int(e["maxhp"]) / 2 else 1))
				e["cool"] = 2.4 if int(e["idx"]) == 3 else 1.55
		else:
			e["cool"] = float(e["cool"]) - delta
			if float(e["cool"]) <= 0.0 and absf(distance) < float(e["attack_range"]):
				e["windup"] = 1.0 if int(e["idx"]) == 3 else 0.62
				_notice("%s chuẩn bị tấn công — hãy NÉ!" % str(e["name"]))
			elif sprite.modulate != Color.WHITE:
				sprite.modulate = Color.WHITE

func _take_damage(amount: int) -> void:
	if invincible_left > 0.0:
		return
	var actual: int = amount
	if guard_left > 0.0:
		actual = maxi(1, int(float(amount) * 0.35))
	hp = maxi(0, hp - actual)
	invincible_left = 0.5
	_notice("Trúng đòn: -%d HP%s" % [actual, " (đã đỡ)" if guard_left > 0.0 else ""])
	if hp <= 0:
		gold = maxi(0, gold - 20)
		hp = maxi(1, int(max_hp / 2.0))
		mp = maxi(1, int(max_mp / 2.0))
		hero.position = Vector2(110.0, FLOOR_Y - 43.0)
		_notice("Bị đánh bại! Trở về làng, mất 20 vàng. Nhiệm vụ vẫn được giữ.")

func _enemy_died(e: Dictionary) -> void:
	e["dead"] = true
	(e["node"] as Node2D).hide()
	var index: int = int(e["idx"])
	gold += 38 if index != 3 else 220
	_gain_xp(45 if index != 3 else 180)
	if index == 3:
		boss_defeated = true
		if quest_stage == 5:
			quest_stage = 6
			_notice("Kẻ Giữ Vực tan biến! Trở về báo với Bà Mộc.")
	elif not defeated[index]:
		defeated[index] = true
		if quest_stage == 3 and defeated.count(true) == 3:
			quest_stage = 4
			_notice("Đã giải phóng khu rừng. Hãy đến tế đàn phía Đông.")
	_refresh_world()

func _gain_xp(amount: int) -> void:
	xp += amount
	var needed: int = level * 100
	while xp >= needed:
		xp -= needed
		level += 1
		var hp_ratio: float = float(hp) / maxf(1.0, float(max_hp))
		var mp_ratio: float = float(mp) / maxf(1.0, float(max_mp))
		_set_role_stats()
		hp = maxi(1, int(float(max_hp) * hp_ratio) + 20)
		mp = mini(max_mp, int(float(max_mp) * mp_ratio) + 20)
		_notice("LÊN CẤP %d! Máu, thần lực và sát thương tăng." % level)
		needed = level * 100

func _try_pickup() -> void:
	var spots: Array[Vector2] = [Vector2(830.0, 550.0), Vector2(1055.0, 412.0), Vector2(1260.0, 550.0)]
	for i in range(3):
		if collected[i]:
			continue
		if hero.position.distance_to(spots[i]) < 88.0:
			collected[i] = true
			fragments += 1
			gold += 10
			_notice("Nhặt mảnh thần tích %d/3 • +10 vàng" % fragments)
			if fragments == 3:
				quest_stage = 2
				_notice("Đã đủ ba mảnh! Trở lại Thợ rèn Vân.")
	_refresh_world()

func _interact() -> void:
	if absf(hero.position.x - 2615.0) < 130.0:
		if quest_stage == 4:
			altar_purified = true
			quest_stage = 5
			_gain_xp(80)
			_show_dialogue("Tiếng nói trong kiếm", [
				"Ngươi đã thắp lại lời thề mà những kẻ mạnh nhất cũng bỏ quên.",
				"Thánh quang từ tế đàn đẩy lùi sương đen. Cổng Đền Phong Ấn đã mở.",
				"Hãy bước tiếp. Kẻ Giữ Vực đang chờ ở phía bên kia."
			], "altar")
		else:
			_notice("Tế đàn vẫn còn phát ra hơi ấm lạ thường.")
		_refresh_world()
		return
	for npc in NPCS:
		if absf(hero.position.x - float(npc["x"])) < 96.0:
			match str(npc["kind"]):
				"elder":
					_talk_elder()
				"smith":
					_talk_smith()
				"shop":
					if gold >= 80:
						gold -= 80
						potions += 1
						_notice("Mua bình hồi máu: -80 vàng. Trong túi: %d." % potions)
					else:
						_notice("Thương nhân Nghi: cần 80 vàng để mua bình hồi máu.")
				"scout":
					_show_dialogue("Trinh sát Diệp", [
						"Trong rừng có ba quái Vực. Chúng sẽ báo trước khi tung đòn mạnh.",
						"Nếu thấy mắt chúng đỏ lên, hãy lướt né sang bên kia.",
						"Thợ rèn Vân phải sửa kiếm cho ngươi trước khi cánh cổng mở."
					], "")
			return
	_notice("Chưa có ai hoặc thứ gì ở đủ gần để tương tác.")

func _talk_elder() -> void:
	if quest_stage == 0:
		_show_dialogue("Bà Mộc", [
			"Làng Tro Sáng đã giữ đèn thánh suốt ba trăm năm. Nhưng đêm qua, ánh đèn yếu đi.",
			"Thanh kiếm gãy bên ngươi... Ta từng thấy biểu tượng đó trên một ngôi đền đã mất.",
			"Hãy tìm ba mảnh thần tích còn sót trong làng, rồi nhờ Vân sửa lại lưỡi kiếm.",
			"Chưa cần chiến đấu. Hãy học cách đi, nhảy, quan sát và giúp những người ở đây."
		], "accept")
	elif quest_stage == 6:
		_show_dialogue("Bà Mộc", [
			"Ngươi đã trở lại... và cả tế đàn cũng đã sáng lên! Vực Không Tên đang suy yếu.",
			"Không ai phong ngươi làm vua. Chính những hành động ấy đã khiến lời thề hồi sinh.",
			"Ta trao cho ngươi 300 vàng, một bình linh dược và danh hiệu Người Giữ Ước.",
			"Chương I khép lại. Chặng đường của đoàn hiệp sĩ chỉ vừa bắt đầu."
		], "chapter_end")
	else:
		_show_dialogue("Bà Mộc", [
			"Nhiệm vụ lúc này: %s" % QUESTS[quest_stage],
			"Đừng quên nói chuyện với người trong làng. Một hiệp sĩ không chỉ biết chiến đấu."
		], "")

func _talk_smith() -> void:
	if quest_stage == 2:
		_show_dialogue("Thợ rèn Vân", [
			"Ba mảnh thần tích này rung lên khi chạm vào thanh kiếm gãy.",
			"Ta có thể nối lưỡi kiếm. Nhưng sức mạnh của nó chỉ thức tỉnh bởi một lời thề được giữ.",
			"Thanh kiếm đã sẵn sàng! Cánh cổng dẫn vào Rừng Tàn Quang mở rồi."
		], "repair")
	else:
		_show_dialogue("Thợ rèn Vân", [
			"Muốn rèn thánh khí phải hiểu điều mình muốn bảo vệ.",
			"Kiếm chỉ là công cụ. Sự lựa chọn của người cầm mới quyết định điều còn lại."
		], "")

func _show_dialogue(speaker: String, lines: Array[String], result: String) -> void:
	dialogue_lines = lines
	dialogue_result = result
	dialogue_index = 0
	dialogue_name.text = speaker
	dialogue_text.text = lines[0]
	dialogue_panel.show()

func _next_dialogue() -> void:
	if not dialogue_panel.visible:
		return
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		dialogue_text.text = dialogue_lines[dialogue_index]
		return
	dialogue_panel.hide()
	match dialogue_result:
		"accept":
			if quest_stage == 0:
				quest_stage = 1
				_notice("Nhiệm vụ mới: tìm ba mảnh thần tích.")
		"repair":
			if quest_stage == 2:
				quest_stage = 3
				_gain_xp(30)
				_notice("Kiếm đã sửa! Rừng Tàn Quang mở cửa.")
		"chapter_end":
			if quest_stage == 6:
				quest_stage = 7
				gold += 300
				potions += 1
				_gain_xp(150)
				_save_game()
				_notice("CHƯƠNG I HOÀN THÀNH — Thánh Ước Đầu Tiên!")
	dialogue_result = ""
	_refresh_world()
	_update_hud()

func _use_potion() -> void:
	if potions <= 0:
		_notice("Không còn bình hồi máu. Mua ở Nghi với 80 vàng.")
		return
	if hp >= max_hp:
		_notice("Máu đã đầy, hãy giữ bình thuốc cho lúc cần.")
		return
	potions -= 1
	hp = mini(max_hp, hp + 70)
	_notice("Uống linh dược: +70 HP.")

func _refresh_world() -> void:
	for i in range(3):
		pickup_nodes[i].visible = quest_stage == 1 and not collected[i]
	for e in enemy_data:
		var idx: int = int(e["idx"])
		(e["node"] as Node2D).visible = not bool(e["dead"]) and (quest_stage >= 5 if idx == 3 else quest_stage >= 3)
	altar_sprite.modulate = Color("#f6f5aa") if altar_purified else Color("#9daab9")
	gate_village.visible = quest_stage < 3
	gate_temple.visible = quest_stage < 5
	if hero_visual != null:
		hero_visual.texture = load(ROLE_ART[role]) as Texture2D

func _update_hud() -> void:
	if not started:
		return
	hp_text.text = "%s  •  %s  |  HP %d/%d" % [hero_name, ROLE_NAMES[role], hp, max_hp]
	mp_text.text = "THẦN LỰC   %d/%d   |   Kỹ năng hồi: %.1fs" % [mp, max_mp, maxf(skill_cd, 0.0)]
	stats_text.text = "Cấp %d  •  XP %d/%d  •  %d vàng  •  %d linh dược" % [level, xp, level * 100, gold, potions]
	var zone: String = "Làng Tro Sáng"
	if hero.position.x >= 2800.0:
		zone = "Đền Phong Ấn"
	elif hero.position.x >= 1400.0:
		zone = "Rừng Tàn Quang"
	zone_text.text = "◈ %s  •  X:%d" % [zone, int(hero.position.x)]
	quest_text.text = "NHIỆM VỤ %d/7  •  %s" % [mini(quest_stage + 1, 7), QUESTS[quest_stage]]
	if quest_stage == 1:
		quest_text.text += "  (%d/3)" % fragments
	if quest_stage == 3:
		quest_text.text += "  (%d/3)" % defeated.count(true)

func _notice(message: String) -> void:
	if notice_text == null:
		return
	notice_text.text = message
	notice_left = 3.6

func _open_detail(which: String) -> void:
	if dialogue_panel.visible:
		return
	if detail_panel.visible and active_detail == which:
		_close_detail()
		return
	active_detail = which
	if which == "inventory":
		detail_text.text = "TÚI ĐỒ — %s\n\nMảnh thần tích: %d/3\nLinh dược: %d (nhấn H để hồi 70 HP)\nVàng: %d\n\nTrang bị: %s\nThánh Ước: %s\n\nThương nhân Nghi bán linh dược: 80 vàng. Đứng gần và nhấn E." % [
			hero_name, fragments, potions, gold,
			"Kiếm thánh đã sửa" if quest_stage >= 3 else "Kiếm gãy",
			"Đã thức tỉnh" if quest_stage >= 7 else "Đang hình thành"
		]
	elif which == "map":
		detail_text.text = "BẢN ĐỒ ASTERION\n\n[0 — 1400]  LÀNG TRO SÁNG  %s\n[1400 — 2800]  RỪNG TÀN QUANG  %s\n[2800 — 4200]  ĐỀN PHONG ẤN  %s\n\nVị trí: X=%d\nTế đàn: %s\n\nCổng rừng cần kiếm đã sửa. Đền cần tế đàn thanh tẩy." % [
			"◉" if hero.position.x < 1400 else "○",
			"◉" if hero.position.x >= 1400 and hero.position.x < 2800 else ("○" if quest_stage >= 3 else "KHÓA"),
			"◉" if hero.position.x >= 2800 else ("○" if quest_stage >= 5 else "KHÓA"),
			int(hero.position.x), "Đã phục hồi" if altar_purified else "Chưa thanh tẩy"
		]
	else:
		detail_text.text = "NHẬT KÝ THÁNH ƯỚC\n\nTiến trình: %d/7\n%s\n\nMảnh thần tích: %d/3\nQuái Vực đã diệt: %d/3\nBoss: %s\n\nTừng hành động đều phải tạo thay đổi trong thế giới." % [
			quest_stage, QUESTS[quest_stage], fragments, defeated.count(true),
			"Đã đánh bại" if boss_defeated else "Chưa đánh bại"
		]
	detail_panel.show()

func _close_detail() -> void:
	active_detail = ""
	detail_panel.hide()

func _save_game() -> void:
	if not started:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("hero", "name", hero_name)
	cfg.set_value("hero", "role", role)
	cfg.set_value("hero", "level", level)
	cfg.set_value("hero", "xp", xp)
	cfg.set_value("hero", "hp", hp)
	cfg.set_value("hero", "mp", mp)
	cfg.set_value("hero", "x", hero.position.x)
	cfg.set_value("hero", "y", hero.position.y)
	cfg.set_value("hero", "gold", gold)
	cfg.set_value("hero", "potions", potions)
	cfg.set_value("world", "quest_stage", quest_stage)
	cfg.set_value("world", "fragments", fragments)
	cfg.set_value("world", "collected", collected)
	cfg.set_value("world", "defeated", defeated)
	cfg.set_value("world", "boss_defeated", boss_defeated)
	cfg.set_value("world", "altar", altar_purified)
	var err: Error = cfg.save(SAVE_PATH)
	if err == OK:
		_notice("Đã lưu tiến trình vào bộ nhớ trò chơi.")
	else:
		_notice("Không thể lưu! Mã lỗi: %d" % err)

func _load_game() -> void:
	var cfg := ConfigFile.new()
	var err: Error = cfg.load(SAVE_PATH)
	if err != OK:
		if started:
			_notice("Chưa có điểm lưu hợp lệ.")
		return
	role = clampi(int(cfg.get_value("hero", "role", 0)), 0, 2)
	hero_name = str(cfg.get_value("hero", "name", "Người Giữ Ước"))
	level = maxi(1, int(cfg.get_value("hero", "level", 1)))
	xp = maxi(0, int(cfg.get_value("hero", "xp", 0)))
	_set_role_stats()
	hp = clampi(int(cfg.get_value("hero", "hp", max_hp)), 1, max_hp)
	mp = clampi(int(cfg.get_value("hero", "mp", max_mp)), 0, max_mp)
	gold = maxi(0, int(cfg.get_value("hero", "gold", 100)))
	potions = maxi(0, int(cfg.get_value("hero", "potions", 1)))
	quest_stage = clampi(int(cfg.get_value("world", "quest_stage", 0)), 0, 7)
	fragments = clampi(int(cfg.get_value("world", "fragments", 0)), 0, 3)
	var saved_collected: Array = cfg.get_value("world", "collected", [false, false, false])
	var saved_defeated: Array = cfg.get_value("world", "defeated", [false, false, false])
	for i in range(3):
		collected[i] = bool(saved_collected[i]) if i < saved_collected.size() else false
		defeated[i] = bool(saved_defeated[i]) if i < saved_defeated.size() else false
	altar_purified = bool(cfg.get_value("world", "altar", false))
	boss_defeated = bool(cfg.get_value("world", "boss_defeated", false))
	for e in enemy_data:
		var idx: int = int(e["idx"])
		e["dead"] = boss_defeated if idx == 3 else defeated[idx]
		e["hp"] = e["maxhp"]
		e["windup"] = 0.0
		e["cool"] = 1.5
	hero.position = Vector2(
		clampf(float(cfg.get_value("hero", "x", 100.0)), 50.0, WIDTH - 50.0),
		clampf(float(cfg.get_value("hero", "y", FLOOR_Y - 43.0)), 50.0, FLOOR_Y - 43.0)
	)
	started = true
	title_panel.hide()
	hero.visible = true
	_refresh_world()
	_update_hud()
	_notice("Đã tải tiến trình: %s — nhiệm vụ %d." % [hero_name, quest_stage])
