extends Control

const CARD_W := 160
const CARD_H := 240

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.04, 0.07)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 根据奖励类型选择标题和卡池
	var is_elite_reward: bool = Global.current_battle_gives_card
	var title_text: String = "选择一张牌加入牌组"
	var pool: Array = []
	var choices: Array = []

	if is_elite_reward:
		# 精英/Boss战斗：从高级卡池抽取3张
		title_text = "冥 将 的 遗 物"
		var deck: String = Global.selected_deck
		var unlocked: Array = Global.unlocked_cards.get(deck, [])
		pool = CardLibrary.draw_advanced_cards(deck, unlocked)
		pool.shuffle()
		for i in mini(3, pool.size()):
			choices.append(pool[i])
	else:
		# 普通奖励卡池
		pool = CardLibrary.get_reward_pool(Global.selected_deck)
		pool.shuffle()
		for i in mini(3, pool.size()):
			choices.append(pool[i])

	# 标题
	var title := Label.new()
	title.text = title_text
	title.position = Vector2(0, 30)
	title.size = Vector2(1280, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.95, 0.72, 0.22))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	# 布局3张牌
	var total_w := choices.size() * CARD_W + (choices.size() - 1) * 40.0
	var sx := (1280.0 - total_w) / 2.0
	var sy := (720.0 - CARD_H) / 2.0 + 20
	for i in choices.size():
		_make_card_panel(choices[i], Vector2(sx + i * (CARD_W + 40), sy))

	# 跳过按钮
	var skip := Button.new()
	skip.text = "跳过"
	skip.size = Vector2(120, 38)
	skip.position = Vector2(1280.0 / 2.0 - 60.0, sy + CARD_H + 30.0)
	skip.pressed.connect(_go_to_map)
	add_child(skip)

func _make_card_panel(card: CardData, pos: Vector2) -> void:
	var type_colors := [Color(0.28, 0.10, 0.10),
						Color(0.10, 0.16, 0.30),
						Color(0.10, 0.25, 0.15)]
	var type_accents := [Color(0.92, 0.38, 0.32),
						 Color(0.42, 0.65, 0.95),
						 Color(0.38, 0.88, 0.52)]

	var panel := Control.new()
	panel.position = pos
	panel.size = Vector2(CARD_W, CARD_H)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	# 背景
	var bg := ColorRect.new()
	bg.color = type_colors[clampi(card.type, 0, 2)]
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	# 边框
	var border := ReferenceRect.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.border_color = type_accents[clampi(card.type, 0, 2)]
	border.border_width = 1.5
	border.editor_only = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(border)

	# 费用
	var cost_lbl := Label.new()
	cost_lbl.text = "X" if card.is_x_cost else str(card.cost)
	cost_lbl.size = Vector2(28, 28)
	cost_lbl.position = Vector2(4, 4)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_font_size_override("font_size", 18)
	cost_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.15))
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(cost_lbl)

	# 卡名
	var name_lbl := Label.new()
	name_lbl.text = card.card_name
	name_lbl.size = Vector2(CARD_W, 32)
	name_lbl.position = Vector2(0, 50)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_lbl)

	# 分割线
	var div := ColorRect.new()
	div.color = Color(0.55, 0.45, 0.22, 0.6)
	div.size = Vector2(CARD_W - 16, 1)
	div.position = Vector2(8, 88)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(div)

	# 描述
	var desc_lbl := Label.new()
	desc_lbl.text = card.description
	desc_lbl.size = Vector2(CARD_W - 16, 120)
	desc_lbl.position = Vector2(8, 95)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.80, 0.72))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(desc_lbl)

	# 点击整张卡牌即选择
	panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				_pick_card(card)
	)

	# 悬停效果
	var orig_y := pos.y
	panel.mouse_entered.connect(func():
		border.border_width = 3.0
		panel.create_tween().tween_property(panel, "position:y", orig_y - 10, 0.12).set_ease(Tween.EASE_OUT)
	)
	panel.mouse_exited.connect(func():
		border.border_width = 1.5
		panel.create_tween().tween_property(panel, "position:y", orig_y, 0.12).set_ease(Tween.EASE_IN)
	)

func _pick_card(card: CardData) -> void:
	if Global.current_battle_gives_card:
		# 精英/Boss战斗：三位一体入库法则
		Global.add_cards_3_to_deck(card)
	else:
		# 普通奖励：加入一张
		Global.current_deck.append(card)
	_go_to_map()

func _go_to_map() -> void:
	Global.current_battle_gives_card = false
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var tw := create_tween()
	tw.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.25)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://Scenes/Map/MapScene.tscn"))
