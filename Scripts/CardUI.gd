class_name CardUI
extends Control

signal card_released(card_ui: CardUI)

var card_data: CardData
var home_position := Vector2.ZERO
var _can_play := true
var _dragging := false
var _drag_offset := Vector2.ZERO

func _init() -> void:
	size = Vector2(118, 168)
	clip_contents = true          # ← 终极保险：任何子节点都不会画出卡牌边界
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(false)

func setup(data: CardData) -> void:
	card_data = data
	_build_visuals()

func _build_visuals() -> void:
	# 背景色：攻击=深红，技能=深蓝，能力=深绿
	var bg := ColorRect.new()
	match card_data.type:
		0: bg.color = Color(0.28, 0.10, 0.10)
		1: bg.color = Color(0.10, 0.16, 0.30)
		_: bg.color = Color(0.10, 0.25, 0.15)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 边框
	var border := ReferenceRect.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.border_color = Color(0.65, 0.52, 0.28)
	border.border_width = 1.5
	border.editor_only = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)

	# 费用（左上角）
	var cost_bg := ColorRect.new()
	cost_bg.color = Color(0.12, 0.12, 0.40)
	cost_bg.size = Vector2(26, 26)
	cost_bg.position = Vector2(3, 3)
	cost_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cost_bg)

	var cost_lbl := Label.new()
	cost_lbl.text = "X" if card_data.is_x_cost else str(card_data.cost)
	cost_lbl.size = Vector2(26, 26)
	cost_lbl.position = Vector2(3, 3)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_lbl.add_theme_font_size_override("font_size", 17)
	cost_lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.15))
	cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cost_lbl)

	# 卡名（长名字自动缩小字号，保证不溢出）
	var name_lbl := Label.new()
	name_lbl.text = card_data.card_name
	name_lbl.size = Vector2(118, 30)
	name_lbl.position = Vector2(0, 34)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var name_font_size := 14 if card_data.card_name.length() <= 5 else 12
	name_lbl.add_theme_font_size_override("font_size", name_font_size)
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_lbl)

	# 分割线
	var div := ColorRect.new()
	div.color = Color(0.55, 0.45, 0.22, 0.7)
	div.size = Vector2(104, 1)
	div.position = Vector2(7, 68)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(div)

	# 描述文字（用PanelContainer包裹实现精准溢出裁剪）
	var desc_panel := PanelContainer.new()
	desc_panel.position = Vector2(5, 72)
	desc_panel.size = Vector2(108, 92)
	desc_panel.clip_contents = true
	desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 去掉默认 StyleBox 的内边距，让文字用满整个区域
	var empty_style := StyleBoxEmpty.new()
	desc_panel.add_theme_stylebox_override("panel", empty_style)
	add_child(desc_panel)

	# 根据描述文字长度自动选择字号：短文字12号，长文字缩到11或10号
	var desc_font_size := 12
	if card_data.description.length() > 22:
		desc_font_size = 11
	if card_data.description.length() > 32:
		desc_font_size = 10

	var desc_lbl := Label.new()
	desc_lbl.text = card_data.description
	desc_lbl.size = Vector2(108, 92)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", desc_font_size)
	desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.82, 0.76))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_panel.add_child(desc_lbl)

# ── 公开方法 ───────────────────────────────────────────────────

func set_playable(can_play: bool) -> void:
	_can_play = can_play
	modulate = Color.WHITE if can_play else Color(0.42, 0.42, 0.42)

func is_dragging() -> bool:
	return _dragging

func return_to_home() -> void:
	_dragging = false
	set_process_input(false)
	z_index = 0
	var t := create_tween()
	t.tween_property(self, "position", home_position, 0.18).set_ease(Tween.EASE_OUT)

# ── 拖拽逻辑 ───────────────────────────────────────────────────

func _gui_input(event: InputEvent) -> void:
	if not _can_play:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_dragging = true
			_drag_offset = global_position - get_global_mouse_position()
			z_index = 100
			set_process_input(true)
			accept_event()

func _input(event: InputEvent) -> void:
	if not _dragging:
		set_process_input(false)
		return
	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position() + _drag_offset
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_dragging = false
			set_process_input(false)
			z_index = 0
			card_released.emit(self)

# ── 悬停动画 ───────────────────────────────────────────────────

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		if not _dragging and _can_play:
			create_tween().tween_property(self, "position",
				home_position + Vector2(0, -22), 0.12).set_ease(Tween.EASE_OUT)
	elif what == NOTIFICATION_MOUSE_EXIT:
		if not _dragging:
			create_tween().tween_property(self, "position",
				home_position, 0.12).set_ease(Tween.EASE_IN)