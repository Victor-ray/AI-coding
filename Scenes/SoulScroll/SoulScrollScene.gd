extends Control

const CARD_W := 140
const CARD_H := 200
const CARD_GAP := 40

var _options: Array = []  # 3张待选卡牌

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_draw_3_cards()

func _draw_3_cards() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.04, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 标题
	var title := Label.new()
	title.text = "幽  冥  秘  卷"
	title.position = Vector2(0, 30)
	title.size = Vector2(1280, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.74, 0.46, 0.96))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	# 副标题
	var sub := Label.new()
	sub.text = "选择一张高级卡牌加入你的卡组"
	sub.position = Vector2(0, 88)
	sub.size = Vector2(1280, 28)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.55, 0.50, 0.40))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)

	# 抽取3张未解锁的高级卡
	var deck: String = Global.selected_deck
	var unlocked: Array = Global.unlocked_cards.get(deck, [])
	_options = CardLibrary.draw_advanced_cards(deck, unlocked)

	if _options.is_empty():
		_show_no_cards()
		return

	# 显示3张卡牌
	var total_w := _options.size() * CARD_W + (_options.size() - 1) * CARD_GAP
	var sx := (1280 - total_w) / 2.0
	var sy := 180.0

	for i in _options.size():
		var card: CardData = _options[i]
		var x := sx + i * (CARD_W + CARD_GAP)
		_make_card(card, Vector2(x, sy), i)

	# 底部说明
	var hint := Label.new()
	hint.text = "三选一，选中的卡牌将永久解锁"
	hint.position = Vector2(0, 420)
	hint.size = Vector2(1280, 28)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.50, 0.48, 0.42))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

func _make_card(card: CardData, pos: Vector2, idx: int) -> void:
	var panel := Control.new()
	panel.position = pos
	panel.size = Vector2(CARD_W, CARD_H)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	panel.set_meta("card_idx", idx)

	# 背景色（根据类型）
	var bg_color := Color(0.28, 0.10, 0.10)  # 攻击红
	match card.type:
		1: bg_color = Color(0.10, 0.16, 0.30)  # 技能蓝
		2: bg_color = Color(0.10, 0.25, 0.15)  # 能力绿

	var bg := ColorRect.new()
	bg.color = bg_color
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	# 边框
	var border := ReferenceRect.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.border_color = Color(0.65, 0.52, 0.28)
	border.border_width = 1.5
	border.editor_only = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(border)
	panel.set_meta("border", border)

	# 费用
	var cost_bg := ColorRect.new()
	cost_bg.color = Color(0.12, 0.12, 0.40)
	cost_bg.size = Vector2(24, 24)
	cost_bg.position = Vector2(4, 4)
	cost_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(cost_bg)

	var cost_lbl := Label.new()
	cost_lbl.text = "X" if card.is_x_cost else str(card.cost)
	cost_lbl.size = Vector2(24, 24)
	cost_lbl.position = Vector2(4, 4)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_font_size_override("font_size", 16)
	cost_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.15))
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(cost_lbl)

	# 卡名
	var name_lbl := Label.new()
	name_lbl.text = card.card_name
	name_lbl.size = Vector2(CARD_W, 28)
	name_lbl.position = Vector2(0, 32)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_lbl)

	# 分割线
	var div := ColorRect.new()
	div.color = Color(0.55, 0.45, 0.22, 0.7)
	div.size = Vector2(CARD_W - 16, 1)
	div.position = Vector2(8, 62)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(div)

	# 描述
	var desc_lbl := Label.new()
	desc_lbl.text = card.description
	desc_lbl.size = Vector2(CARD_W - 12, 130)
	desc_lbl.position = Vector2(6, 68)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.76))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(desc_lbl)

	# 点击整张卡牌即选择（无按钮）
	panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				_on_select(idx)
	)

	# 悬停效果
	var orig_pos := pos
	panel.mouse_entered.connect(func():
		panel.create_tween().tween_property(panel, "position",
			orig_pos + Vector2(0, -10), 0.12).set_ease(Tween.EASE_OUT)
		(panel.get_meta("border") as ReferenceRect).border_color = Color(0.96, 0.82, 0.28)
	)
	panel.mouse_exited.connect(func():
		panel.create_tween().tween_property(panel, "position",
			orig_pos, 0.12).set_ease(Tween.EASE_IN)
		(panel.get_meta("border") as ReferenceRect).border_color = Color(0.65, 0.52, 0.28)
	)

func _on_select(idx: int) -> void:
	if idx < 0 or idx >= _options.size():
		return

	var card: CardData = _options[idx]
	Global.unlock_card(card)

	# 延迟返回商店
	await get_tree().create_timer(0.6).timeout
	_fade_to_shop()

func _show_no_cards() -> void:
	var lbl := Label.new()
	lbl.text = "当前流派所有高级卡牌已全部解锁！"
	lbl.position = Vector2(0, 200)
	lbl.size = Vector2(1280, 50)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.74, 0.46, 0.96))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)

	var btn := Button.new()
	btn.text = "返回商店"
	btn.size = Vector2(160, 44)
	btn.position = Vector2(560, 300)
	btn.pressed.connect(_fade_to_shop)
	add_child(btn)

func _fade_to_shop() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var tw := create_tween()
	tw.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.25)
	tw.tween_callback(Callable(self, "_do_fade_to_shop"))

func _do_fade_to_shop() -> void:
	get_tree().change_scene_to_file("res://Scenes/Shop/ShopScene.tscn")
