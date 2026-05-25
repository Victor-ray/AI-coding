extends Control

# ══════════════════════════════════════════════════════
# 角色数据
# ══════════════════════════════════════════════════════
const CHARS := [
	{
		"name":    "炎魂",
		"title":   "业火判官",
		"deck":    "fire",
		"tag":     "火焰系",
		"lore":    "以灼烧击溃仇敌\n燃烧层数越深\n毁灭越大",
		"bg":      Color(0.42, 0.09, 0.03),
		"portrait":Color(0.62, 0.16, 0.05),
		"accent":  Color(0.96, 0.54, 0.18),
	},
	{
		"name":    "骨灵",
		"title":   "白骨将军",
		"deck":    "bone",
		"tag":     "骨刺系",
		"lore":    "骨刺越积越多\n反弹令敌人\n不敢轻易出手",
		"bg":      Color(0.20, 0.20, 0.18),
		"portrait":Color(0.35, 0.35, 0.32),
		"accent":  Color(0.88, 0.88, 0.82),
	},
	{
		"name":    "血魔",
		"title":   "血肉修罗",
		"deck":    "blood",
		"tag":     "血肉系",
		"lore":    "以自身鲜血为代价\n越接近死亡\n越发强大",
		"bg":      Color(0.38, 0.04, 0.05),
		"portrait":Color(0.58, 0.07, 0.09),
		"accent":  Color(0.94, 0.28, 0.32),
	},
	{
		"name":    "幽魄",
		"title":   "虚空使者",
		"deck":    "ghost",
		"tag":     "幽灵系",
		"lore":    "怨灵缠绕，易伤加身\n彼岸花开之时\n即是终结",
		"bg":      Color(0.16, 0.07, 0.32),
		"portrait":Color(0.26, 0.11, 0.50),
		"accent":  Color(0.74, 0.46, 0.96),
	},
	{
		"name":    "轮回者",
		"title":   "六道行者",
		"deck":    "cycle",
		"tag":     "循环系",
		"lore":    "六道连弹循环不息\n能量满溢之时\n一击爆发",
		"bg":      Color(0.04, 0.22, 0.32),
		"portrait":Color(0.06, 0.36, 0.50),
		"accent":  Color(0.32, 0.86, 0.94),
	},
]

const CARD_W   := 172
const CARD_H   := 328
const CARD_GAP := 24

# ══════════════════════════════════════════════════════
# 入口
# ══════════════════════════════════════════════════════
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.04, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 顶部装饰线
	var deco := ColorRect.new()
	deco.color = Color(0.55, 0.38, 0.12, 0.6)
	deco.size = Vector2(1280, 2)
	deco.position = Vector2(0, 106)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(deco)

	# 主标题
	var title := Label.new()
	title.text = "狱  火  爬  升"
	title.position = Vector2(0, 14)
	title.size = Vector2(1280, 56)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.96, 0.62, 0.22))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	# 副标题
	var sub := Label.new()
	sub.text = "选择你的亡魂，踏上从第十八层攀升的旅途"
	sub.position = Vector2(0, 68)
	sub.size = Vector2(1280, 28)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", Color(0.58, 0.52, 0.42))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)

	# 角色卡牌
	var total_w := CHARS.size() * CARD_W + (CHARS.size() - 1) * CARD_GAP
	var sx := (1280 - total_w) / 2.0
	var sy := (720 - CARD_H) / 2.0 + 26   # 稍微偏下给标题留空间
	for i in CHARS.size():
		var cx := sx + i * (CARD_W + CARD_GAP)
		_make_char_card(CHARS[i], Vector2(cx, sy))

func _make_char_card(data: Dictionary, pos: Vector2) -> void:
	var panel := Control.new()
	panel.position = pos
	panel.size = Vector2(CARD_W, CARD_H)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	# ── 背景 ──────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = data.bg
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	# ── 边框 ──────────────────────────────────────────
	var border := ReferenceRect.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.border_color = (data.accent as Color) * Color(1, 1, 1, 0.5)
	border.border_width = 1.5
	border.editor_only = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(border)

	# ── 肖像区 ────────────────────────────────────────
	var portrait := TextureRect.new()
	portrait.expand = true
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size = Vector2(CARD_W, 148)
	portrait.position = Vector2(0, 0)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 根据流派加载对应图片
	var img_map := {
		"fire":  "res://picture/Heroes/主角/狱火流.png",
		"bone":  "res://picture/Heroes/主角/白骨流.png",
		"blood": "res://picture/Heroes/主角/血煞流.png",
		"ghost": "res://picture/Heroes/主角/幽魂流.png",
		"cycle": "res://picture/Heroes/主角/轮回流.png",
	}
	var img_path: String = img_map.get(data.deck, "")
	if not img_path.is_empty():
		var tex := load(img_path)
		if tex:
			portrait.texture = tex

	panel.add_child(portrait)

	# 肖像底部高光线
	var glow := ColorRect.new()
	glow.color = (data.accent as Color) * Color(1, 1, 1, 0.35)
	glow.size = Vector2(CARD_W, 2)
	glow.position = Vector2(0, 148)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(glow)

	# ── 角色名 ────────────────────────────────────────
	var name_lbl := Label.new()
	name_lbl.text = data.name
	name_lbl.position = Vector2(0, 155)
	name_lbl.size = Vector2(CARD_W, 32)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", data.accent)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_lbl)

	# ── 称号 ──────────────────────────────────────────
	var title_lbl := Label.new()
	title_lbl.text = data.title
	title_lbl.position = Vector2(0, 186)
	title_lbl.size = Vector2(CARD_W, 22)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.add_theme_color_override("font_color", Color(0.68, 0.62, 0.50))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title_lbl)

	# ── 分割线 ────────────────────────────────────────
	var div := ColorRect.new()
	div.color = (data.accent as Color) * Color(1, 1, 1, 0.22)
	div.size = Vector2(CARD_W - 24, 1)
	div.position = Vector2(12, 213)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(div)

	# ── 背景故事 ──────────────────────────────────────
	var lore_lbl := Label.new()
	lore_lbl.text = data.lore
	lore_lbl.position = Vector2(6, 218)
	lore_lbl.size = Vector2(CARD_W - 12, 62)
	lore_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lore_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lore_lbl.add_theme_font_size_override("font_size", 11)
	lore_lbl.add_theme_color_override("font_color", Color(0.80, 0.78, 0.70))
	lore_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lore_lbl)

	# ── 卡组标签 ──────────────────────────────────────
	var tag_w := 64
	var tag_bg := ColorRect.new()
	tag_bg.color = (data.accent as Color) * Color(1, 1, 1, 0.18)
	tag_bg.size = Vector2(tag_w, 20)
	tag_bg.position = Vector2((CARD_W - tag_w) / 2.0, 284)
	tag_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(tag_bg)

	var tag_lbl := Label.new()
	tag_lbl.text = data.tag
	tag_lbl.size = Vector2(tag_w, 20)
	tag_lbl.position = Vector2((CARD_W - tag_w) / 2.0, 284)
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag_lbl.add_theme_font_size_override("font_size", 11)
	tag_lbl.add_theme_color_override("font_color", data.accent)
	tag_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(tag_lbl)

	# ── 点击整张卡牌即选择 ────────────────────────────
	var deck_id: String = data.deck
	panel.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				_select(deck_id)
	)

	# ── 悬停效果 ──────────────────────────────────────
	var orig_y := pos.y
	panel.mouse_entered.connect(func():
		panel.create_tween().tween_property(panel, "position:y",
			orig_y - 14, 0.13).set_ease(Tween.EASE_OUT)
		border.border_color = data.accent
	)
	panel.mouse_exited.connect(func():
		panel.create_tween().tween_property(panel, "position:y",
			orig_y, 0.13).set_ease(Tween.EASE_IN)
		border.border_color = (data.accent as Color) * Color(1, 1, 1, 0.5)
	)

# ══════════════════════════════════════════════════════
# 选择角色 → 初始化游戏 → 跳转地图
# ══════════════════════════════════════════════════════
func _select(deck: String) -> void:
	Global.init_run(deck)

	# 淡出动画再切场景
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP   # 防止重复点击
	add_child(overlay)

	var tw := create_tween()
	tw.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.30)
	tw.tween_callback(func():
		get_tree().change_scene_to_file("res://Scenes/Map/MapScene.tscn"))
