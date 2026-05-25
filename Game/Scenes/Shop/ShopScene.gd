extends Control

const ITEMS := [
	{"id": "heal", "name": "孟婆汤", "desc": "立即回复30点HP\n（无法超过上限）", "price": 40, "color": Color(0.10, 0.32, 0.18), "accent": Color(0.38, 0.92, 0.52)},
	{"id": "remove", "name": "业力净化", "desc": "从牌组中随机\n移除一张费用最低的牌", "price": 60, "color": Color(0.28, 0.10, 0.28), "accent": Color(0.82, 0.42, 0.92)},
	{"id": "energy", "name": "地府令牌", "desc": "本次战局\n永久最大能量+1", "price": 80, "color": Color(0.30, 0.22, 0.04), "accent": Color(0.95, 0.82, 0.28)},
	{"id": "scroll", "name": "幽冥秘卷", "desc": "高级卡牌盲盒\n三选一永久解锁", "price": 60, "color": Color(0.20, 0.08, 0.32), "accent": Color(0.74, 0.46, 0.96)},
]

var _purchased := {}
var _souls_lbl : Label
var _msg_lbl   : Label
var _item_panels: Array = []
var _toast_lbl : Label
var _toast_base_y: float = 280.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.05, 0.06)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# ════ 顶部内容区（占上方大部分空间） ════
	var top_vbox := VBoxContainer.new()
	top_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_vbox.add_theme_constant_override("separation", 12)
	add_child(top_vbox)

	# 标题居中
	var sign_center := CenterContainer.new()
	sign_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_vbox.add_child(sign_center)

	var sign_bg := ColorRect.new()
	sign_bg.color = Color(0.30, 0.20, 0.04)
	sign_bg.custom_minimum_size = Vector2(340, 56)
	sign_center.add_child(sign_bg)

	var sign_lbl := Label.new()
	sign_lbl.text = "黄  泉  客  栈"
	sign_lbl.custom_minimum_size = Vector2(340, 56)
	sign_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sign_lbl.add_theme_font_size_override("font_size", 28)
	sign_lbl.add_theme_color_override("font_color", Color(0.96, 0.82, 0.28))
	sign_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sign_bg.add_child(sign_lbl)

	# 魂魄显示
	var souls_lbl_center := CenterContainer.new()
	souls_lbl_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_vbox.add_child(souls_lbl_center)

	_souls_lbl = Label.new()
	_souls_lbl.custom_minimum_size = Vector2(200, 36)
	_souls_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_souls_lbl.add_theme_font_size_override("font_size", 18)
	_souls_lbl.add_theme_color_override("font_color", Color(0.92, 0.80, 0.28))
	_souls_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	souls_lbl_center.add_child(_souls_lbl)
	_refresh_souls()

	# 副标题
	var sub := Label.new()
	sub.text = "此处阴气甚重，过路亡魂可稍作补给"
	sub.custom_minimum_size = Vector2(0, 22)
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.55, 0.50, 0.40))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_vbox.add_child(sub)

	# 弹性空间
	var top_spacer := Control.new()
	top_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top_vbox.add_child(top_spacer)

	# ════ 商品卡牌区（水平排列，4列） ════
	# 使用MarginContainer精确控制底部边界
	var card_margin := MarginContainer.new()
	card_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_margin.add_theme_constant_override("margin_bottom", 100)  # 给底部按钮留100px
	card_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_vbox.add_child(card_margin)

	var card_hbox := HBoxContainer.new()
	card_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card_hbox.add_theme_constant_override("separation", 20)
	card_margin.add_child(card_hbox)

	var item_w := 280
	var item_h := 260
	for i in ITEMS.size():
		var wrapper := Control.new()
		wrapper.custom_minimum_size = Vector2(item_w, item_h)
		card_hbox.add_child(wrapper)
		_make_item(ITEMS[i], wrapper, item_w, item_h)

	# ════ 提示信息 ════
	var msg_center := CenterContainer.new()
	msg_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_vbox.add_child(msg_center)

	_msg_lbl = Label.new()
	_msg_lbl.custom_minimum_size = Vector2(0, 28)
	_msg_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_lbl.add_theme_font_size_override("font_size", 14)
	_msg_lbl.add_theme_color_override("font_color", Color(0.92, 0.72, 0.28))
	_msg_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	msg_center.add_child(_msg_lbl)

	# ════ 离开按钮（底部固定，绝对定位） ════
	var leave_btn := Button.new()
	leave_btn.text = "离  开  客  栈"
	leave_btn.anchor_left = 0.5
	leave_btn.anchor_right = 0.5
	leave_btn.anchor_bottom = 1.0
	leave_btn.anchor_top = 1.0
	leave_btn.offset_top = -80
	leave_btn.offset_left = -100
	leave_btn.offset_right = 100
	leave_btn.offset_bottom = -20
	leave_btn.custom_minimum_size = Vector2(200, 50)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.12, 0.08, 0.06)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.68, 0.42, 0.12)
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.18, 0.10, 0.08)
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color(0.96, 0.62, 0.22)
	hover_style.corner_radius_top_left = 6
	hover_style.corner_radius_top_right = 6
	hover_style.corner_radius_bottom_left = 6
	hover_style.corner_radius_bottom_right = 6

	leave_btn.add_theme_stylebox_override("normal", normal_style)
	leave_btn.add_theme_stylebox_override("hover", hover_style)
	leave_btn.add_theme_color_override("font_color", Color(0.96, 0.62, 0.22))
	leave_btn.add_theme_font_size_override("font_size", 16)
	leave_btn.pressed.connect(_leave)
	add_child(leave_btn)

	# ════ 魂魄不足提示 Toast ════
	_toast_lbl = Label.new()
	_toast_lbl.name = "WarningToast"
	_toast_lbl.text = "魂魄不足！"
	_toast_lbl.position = Vector2(0, _toast_base_y)
	_toast_lbl.size = Vector2(1280, 40)
	_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_lbl.add_theme_font_size_override("font_size", 20)
	_toast_lbl.add_theme_color_override("font_color", Color(0.96, 0.28, 0.28))
	_toast_lbl.modulate.a = 0.0
	_toast_lbl.visible = false
	_toast_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast_lbl)

func _make_item(item: Dictionary, parent: Control, w: int, h: int) -> void:
	var panel := Control.new()
	panel.size = Vector2(w, h)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(panel)
	panel.set_meta("item_id", item.id)
	panel.set_meta("item_price", item.price)
	panel.set_meta("purchased", false)
	_item_panels.append(panel)

	var bg := ColorRect.new()
	bg.color = item.color
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	var border := ReferenceRect.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.border_color = (item.accent as Color) * Color(1, 1, 1, 0.6)
	border.border_width = 1.5
	border.editor_only = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(border)
	panel.set_meta("border", border)

	var icon_map := {"heal": "汤", "remove": "净", "energy": "令", "scroll": "卷"}
	var icon := Label.new()
	icon.text = icon_map.get(item.id, "?")
	icon.size = Vector2(w, 90)
	icon.position = Vector2(0, 10)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 56)
	icon.add_theme_color_override("font_color", (item.accent as Color).lerp(Color.WHITE, 0.2))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = item.name
	name_lbl.size = Vector2(w, 30)
	name_lbl.position = Vector2(0, 108)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", item.accent)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = item.desc
	desc_lbl.size = Vector2(w - 16, 80)
	desc_lbl.position = Vector2(8, 144)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.80, 0.78, 0.70))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(desc_lbl)

	var price_lbl := Label.new()
	price_lbl.name = "price_lbl"
	price_lbl.text = "%d 魂魄" % item.price
	price_lbl.size = Vector2(w, 24)
	price_lbl.position = Vector2(0, 226)
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_lbl.add_theme_font_size_override("font_size", 15)
	price_lbl.add_theme_color_override("font_color", Color(0.92, 0.80, 0.28))
	price_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(price_lbl)

	panel.gui_input.connect(_on_item_clicked.bind(panel))

	panel.mouse_entered.connect(_on_item_hover.bind(item, panel))
	panel.mouse_exited.connect(_on_item_unhover.bind(item, panel))

func _on_item_clicked(ev: InputEvent, panel: Control) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			if panel and panel.has_meta("item_id"):
				var item_id: String = panel.get_meta("item_id")
				var item_price: int = panel.get_meta("item_price")
				_buy(item_id, item_price, panel)

func _on_item_hover(item: Dictionary, panel: Control) -> void:
	var tween := panel.create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "position:y", -12.0, 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate", item.accent.lightened(0.25), 0.15).set_ease(Tween.EASE_OUT)
	var border_ref: ReferenceRect = panel.get_meta("border")
	if border_ref:
		border_ref.border_color = item.accent
		border_ref.border_width = 2.5

func _on_item_unhover(item: Dictionary, panel: Control) -> void:
	var tween := panel.create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "position:y", 0.0, 0.15).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate", Color.WHITE, 0.15).set_ease(Tween.EASE_IN)
	var border_ref: ReferenceRect = panel.get_meta("border")
	if border_ref:
		border_ref.border_color = (item.accent as Color) * Color(1, 1, 1, 0.6)
		border_ref.border_width = 1.5

func _buy(item_id: String, price: int, panel: Control) -> void:
	if panel.get_meta("purchased"):
		_msg("此物品已购买")
		return
	if Global.player_souls < price:
		_show_toast()
		_msg("魂魄不足！")
		return
	if item_id == "scroll" and Global.shop_scroll_purchased:
		_msg("幽冥秘卷本局已购买过")
		return

	Global.player_souls -= price
	panel.set_meta("purchased", true)

	match item_id:
		"heal":
			var healed := mini(30, Global.player_max_hp - Global.player_hp)
			Global.player_hp += healed
			_msg("孟婆汤：回复了 %d 点HP" % healed)
		"remove":
			_remove_cheapest_card()
		"energy":
			Global.bonus_energy += 1
			_msg("地府令牌：最大能量永久+1（当前+%d）" % Global.bonus_energy)
		"scroll":
			Global.shop_scroll_purchased = true
			_open_scroll()
			return

	_refresh_souls()
	var price_lbl: Label = panel.get_node("price_lbl")
	price_lbl.text = "已售出"
	price_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	panel.modulate = Color(0.55, 0.55, 0.55)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _show_toast() -> void:
	_toast_lbl.position.y = _toast_base_y
	_toast_lbl.modulate.a = 0.0
	_toast_lbl.visible = true
	var tw := create_tween()
	tw.set_parallel(false)
	tw.tween_property(_toast_lbl, "modulate:a", 1.0, 0.2)
	tw.tween_property(_toast_lbl, "position:y", _toast_base_y - 40.0, 1.0).set_ease(Tween.EASE_OUT)
	tw.tween_property(_toast_lbl, "modulate:a", 0.0, 0.3).set_delay(1.0)
	tw.tween_callback(func():
		_toast_lbl.visible = false
		_toast_lbl.position.y = _toast_base_y
	)

func _remove_cheapest_card() -> void:
	if Global.current_deck.is_empty():
		_msg("牌组为空，无法净化")
		return
	var min_cost := 999
	var target_idx := -1
	for i in Global.current_deck.size():
		var c: CardData = Global.current_deck[i]
		if c.cost < min_cost and not c.is_x_cost:
			min_cost = c.cost
			target_idx = i
	if target_idx < 0:
		target_idx = 0
	var removed: CardData = Global.current_deck[target_idx]
	Global.current_deck.remove_at(target_idx)
	_msg("业力净化：移除了【%s】" % removed.card_name)

func _open_scroll() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var tw := create_tween()
	tw.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.25)
	tw.tween_callback(_on_scroll_continue)

func _on_scroll_continue() -> void:
	get_tree().change_scene_to_file("res://Scenes/SoulScroll/SoulScrollScene.tscn")

func _refresh_souls() -> void:
	_souls_lbl.text = "魂魄：%d" % Global.player_souls

func _msg(text: String) -> void:
	_msg_lbl.text = text

func _leave() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var tw := create_tween()
	tw.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.25)
	tw.tween_callback(_on_leave_continue)

func _on_leave_continue() -> void:
	get_tree().change_scene_to_file("res://Scenes/Map/MapScene.tscn")
