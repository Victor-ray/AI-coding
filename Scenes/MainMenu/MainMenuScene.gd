extends Control

# ══════════════════════════════════════════════════════
# 主菜单
# 开始游戏 / 继续游戏 / 设置
# ══════════════════════════════════════════════════════

# ── 余烬粒子背景（同 MapScene 同款，不同种子）────────
class EmberBG extends Control:
	var _embers: Array = []
	var _t: float = 0.0

	func _init() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 20260601
		for _i in 24:
			_embers.append({
				"pos":   Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 720)),
				"r":     rng.randf_range(1.0, 3.0),
				"phase": rng.randf_range(0.0, TAU),
				"spd":   rng.randf_range(0.3, 1.6),
				"drift": rng.randf_range(-0.07, 0.07),
				"rise":  rng.randf_range(0.08, 0.26),
				"hue":   rng.randf_range(0.0, 0.12),
			})

	func _process(delta: float) -> void:
		_t += delta
		for e in _embers:
			e.pos.y -= e.rise
			e.pos.x += e.drift * sin(_t * e.spd)
			if e.pos.y < -4:
				e.pos.y = 724.0
				e.pos.x = randf_range(0, 1280)
		queue_redraw()

	func _draw() -> void:
		for e in _embers:
			var a := sin(_t * e.spd + e.phase) * 0.26 + 0.32
			var c := Color(0.72 + e.hue, 0.18 + e.hue * 0.8, 0.02, a * 0.50)
			draw_circle(e.pos, e.r, c)
			draw_circle(e.pos, e.r * 2.2, Color(c.r, c.g * 0.5, 0.0, a * 0.11))

# ══════════════════════════════════════════════════════
var _settings_overlay: Control = null

# ══════════════════════════════════════════════════════
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_bg()
	_build_title()
	_build_buttons()
	_build_bottom()

# ══════════════════════════════════════════════════════
# 背景层
# ══════════════════════════════════════════════════════
func _build_bg() -> void:
	# 深紫黑底
	var bg := ColorRect.new()
	bg.color = Color(0.028, 0.016, 0.040)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 余烬粒子
	var ember := EmberBG.new()
	ember.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ember.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ember)

	# 左侧装饰竖线
	for i in 3:
		var stripe := ColorRect.new()
		stripe.color = Color(0.72, 0.28, 0.06, 0.04 + i * 0.02)
		stripe.size = Vector2(2 + i, 720)
		stripe.position = Vector2(160 + i * 3, 0)
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(stripe)

	# 右侧装饰竖线
	for i in 3:
		var stripe := ColorRect.new()
		stripe.color = Color(0.72, 0.28, 0.06, 0.04 + i * 0.02)
		stripe.size = Vector2(2 + i, 720)
		stripe.position = Vector2(1118 - i * 3, 0)
		stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(stripe)

	# 中央暗晕（聚焦感）
	var vignette := ColorRect.new()
	vignette.color = Color(0, 0, 0, 0)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

# ══════════════════════════════════════════════════════
# 标题区
# ══════════════════════════════════════════════════════
func _build_title() -> void:
	# 顶部装饰横线（双线）
	var ln1 := ColorRect.new()
	ln1.color = Color(0.68, 0.38, 0.08, 0.45)
	ln1.size = Vector2(1280, 3)
	ln1.position = Vector2(0, 118)
	ln1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ln1)
	var ln2 := ColorRect.new()
	ln2.color = Color(0.68, 0.38, 0.08, 0.18)
	ln2.size = Vector2(1280, 1)
	ln2.position = Vector2(0, 123)
	ln2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ln2)

	# "狱火" 大字，火焰橙
	var t1 := Label.new()
	t1.text = "狱  火"
	t1.position = Vector2(0, 138)
	t1.size = Vector2(1280, 88)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_size_override("font_size", 74)
	t1.add_theme_color_override("font_color", Color(0.98, 0.52, 0.16))
	t1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t1)

	# "爬升" 小一号，金色
	var t2 := Label.new()
	t2.text = "爬  升"
	t2.position = Vector2(0, 222)
	t2.size = Vector2(1280, 56)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.add_theme_font_size_override("font_size", 46)
	t2.add_theme_color_override("font_color", Color(0.92, 0.72, 0.26))
	t2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t2)

	# 英文副标题
	var sub := Label.new()
	sub.text = "—   INFERNO  ASCENT   —"
	sub.position = Vector2(0, 284)
	sub.size = Vector2(1280, 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.50, 0.34, 0.10, 0.80))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)

	# 分隔线
	var mid := ColorRect.new()
	mid.color = Color(0.55, 0.35, 0.08, 0.30)
	mid.size = Vector2(500, 1)
	mid.position = Vector2(390, 322)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mid)

	# 黑魂激活提示（右上角，静默显示）
	if Global.has_black_soul:
		var soul_lbl := Label.new()
		soul_lbl.text = "◈  黑魂已激活"
		soul_lbl.position = Vector2(1096, 14)
		soul_lbl.add_theme_font_size_override("font_size", 11)
		soul_lbl.add_theme_color_override("font_color", Color(0.42, 0.92, 0.80, 0.72))
		soul_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(soul_lbl)

# ══════════════════════════════════════════════════════
# 菜单按钮区
# ══════════════════════════════════════════════════════
func _build_buttons() -> void:
	_make_btn("开  始  游  戏", 358, _on_new_game,
		Color(0.72, 0.22, 0.06), Color(0.98, 0.62, 0.26))

	var continue_enabled := Global.is_run_active
	_make_btn("继  续  游  戏", 444, _on_continue,
		Color(0.12, 0.18, 0.08) if continue_enabled else Color(0.06, 0.06, 0.07),
		Color(0.52, 0.80, 0.38) if continue_enabled else Color(0.35, 0.35, 0.32),
		not continue_enabled)

	_make_btn("设          置", 530, _on_settings,
		Color(0.08, 0.06, 0.14), Color(0.68, 0.52, 0.88))

func _make_btn(label: String, y: float, callback: Callable,
		bg_col: Color, accent: Color, disabled: bool = false) -> void:
	var W := 400.0
	var H := 64.0
	var btn := Button.new()
	btn.text    = label
	btn.size    = Vector2(W, H)
	btn.position = Vector2((1280 - W) / 2.0, y)
	btn.disabled = disabled

	# ── normal ──
	var sn := StyleBoxFlat.new()
	sn.bg_color    = bg_col * Color(1, 1, 1, 0.88)
	sn.border_color = accent * Color(1, 1, 1, 0.55)
	sn.set_border_width_all(1)
	for prop in ["corner_radius_top_left","corner_radius_top_right",
				 "corner_radius_bottom_left","corner_radius_bottom_right"]:
		sn.set(prop, 5)
	btn.add_theme_stylebox_override("normal", sn)

	# ── hover ──
	var sh := StyleBoxFlat.new()
	sh.bg_color    = bg_col.lightened(0.18)
	sh.border_color = accent
	sh.set_border_width_all(2)
	for prop in ["corner_radius_top_left","corner_radius_top_right",
				 "corner_radius_bottom_left","corner_radius_bottom_right"]:
		sh.set(prop, 5)
	btn.add_theme_stylebox_override("hover", sh)

	# ── pressed ──
	var sp := StyleBoxFlat.new()
	sp.bg_color    = bg_col.lightened(0.28)
	sp.border_color = accent.lightened(0.2)
	sp.set_border_width_all(2)
	for prop in ["corner_radius_top_left","corner_radius_top_right",
				 "corner_radius_bottom_left","corner_radius_bottom_right"]:
		sp.set(prop, 5)
	btn.add_theme_stylebox_override("pressed", sp)

	# ── focus（移除虚线框）──
	var sf := StyleBoxFlat.new()
	sf.bg_color    = bg_col * Color(1, 1, 1, 0.88)
	sf.border_color = accent * Color(1, 1, 1, 0.55)
	sf.set_border_width_all(1)
	for prop in ["corner_radius_top_left","corner_radius_top_right",
				 "corner_radius_bottom_left","corner_radius_bottom_right"]:
		sf.set(prop, 5)
	btn.add_theme_stylebox_override("focus", sf)

	# ── disabled ──
	var sd := StyleBoxFlat.new()
	sd.bg_color    = Color(0.05, 0.05, 0.06, 0.65)
	sd.border_color = Color(0.30, 0.28, 0.26, 0.38)
	sd.set_border_width_all(1)
	for prop in ["corner_radius_top_left","corner_radius_top_right",
				 "corner_radius_bottom_left","corner_radius_bottom_right"]:
		sd.set(prop, 5)
	btn.add_theme_stylebox_override("disabled", sd)

	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color",
		accent if not disabled else Color(0.38, 0.36, 0.34))
	btn.add_theme_color_override("font_color_hover", accent.lightened(0.25))
	btn.add_theme_color_override("font_color_pressed", accent.lightened(0.35))
	btn.add_theme_color_override("font_color_disabled", Color(0.35, 0.33, 0.30))

	if not disabled:
		btn.pressed.connect(callback)
	add_child(btn)

# ══════════════════════════════════════════════════════
# 底部信息栏
# ══════════════════════════════════════════════════════
func _build_bottom() -> void:
	var sep := ColorRect.new()
	sep.color = Color(0.45, 0.28, 0.06, 0.28)
	sep.size = Vector2(1280, 1)
	sep.position = Vector2(0, 636)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)

	var credits := Label.new()
	credits.text = "© 2026  mmk Studio  ·  v0.1 Alpha"
	credits.position = Vector2(0, 644)
	credits.size = Vector2(1280, 22)
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits.add_theme_font_size_override("font_size", 11)
	credits.add_theme_color_override("font_color", Color(0.35, 0.28, 0.16, 0.65))
	credits.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(credits)

	# 当前 AI 模式标注（左下角）
	var mode_lbl := Label.new()
	mode_lbl.text = "AI：" + ("DeepSeek 在线" if Global.use_ai_mode else "神经网络离线")
	mode_lbl.position = Vector2(20, 680)
	mode_lbl.add_theme_font_size_override("font_size", 11)
	mode_lbl.add_theme_color_override("font_color", Color(0.48, 0.42, 0.56, 0.65))
	mode_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mode_lbl)

# ══════════════════════════════════════════════════════
# 按钮回调
# ══════════════════════════════════════════════════════
func _on_new_game() -> void:
	_fade_to("res://Scenes/Story/StoryScene.tscn")

func _on_continue() -> void:
	if Global.is_run_active:
		_fade_to("res://Scenes/Map/MapScene.tscn")

func _on_settings() -> void:
	if _settings_overlay != null and is_instance_valid(_settings_overlay):
		return
	_settings_overlay = _build_settings()
	add_child(_settings_overlay)

# ══════════════════════════════════════════════════════
# 设置面板
# ══════════════════════════════════════════════════════
func _build_settings() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 半透明遮罩
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.68)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	# 面板本体
	var pw := 540.0; var ph := 420.0
	var panel := Panel.new()
	var pst := StyleBoxFlat.new()
	pst.bg_color     = Color(0.055, 0.036, 0.088, 0.98)
	pst.border_color = Color(0.55, 0.36, 0.10, 0.80)
	pst.set_border_width_all(2)
	for prop in ["corner_radius_top_left","corner_radius_top_right",
				 "corner_radius_bottom_left","corner_radius_bottom_right"]:
		pst.set(prop, 8)
	panel.add_theme_stylebox_override("panel", pst)
	panel.size     = Vector2(pw, ph)
	panel.position = Vector2((1280 - pw) / 2.0, (720 - ph) / 2.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)

	# ── 标题 ──────────────────────────────────────────
	var title := Label.new()
	title.text = "⚙  设  置"
	title.size = Vector2(pw, 52)
	title.position = Vector2(0, 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.90, 0.72, 0.28))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title)

	var div1 := ColorRect.new()
	div1.color = Color(0.55, 0.35, 0.10, 0.40)
	div1.size = Vector2(480, 1)
	div1.position = Vector2(30, 68)
	div1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(div1)

	# ── API Key ───────────────────────────────────────
	_settings_row_label(panel, "DeepSeek API Key", 88)
	var key := Global.deepseek_api_key
	var key_disp := Label.new()
	if key.is_empty():
		key_disp.text = "（未设置，当前为离线模式）"
		key_disp.add_theme_color_override("font_color", Color(0.78, 0.42, 0.38))
	elif key.length() > 12:
		key_disp.text = key.substr(0, 6) + "  ···  " + key.right(4)
		key_disp.add_theme_color_override("font_color", Color(0.42, 0.88, 0.55))
	else:
		key_disp.text = key
		key_disp.add_theme_color_override("font_color", Color(0.42, 0.88, 0.55))
	key_disp.position = Vector2(40, 112)
	key_disp.size = Vector2(400, 24)
	key_disp.add_theme_font_size_override("font_size", 13)
	key_disp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(key_disp)

	var api_btn := _settings_small_btn("修 改 API Key", Vector2(40, 142))
	api_btn.pressed.connect(func():
		root.queue_free()
		_settings_overlay = null
		Global.from_settings = true
		_fade_to("res://Scenes/ApiKey/ApiKeyScene.tscn")
	)
	panel.add_child(api_btn)

	var div2 := ColorRect.new()
	div2.color = Color(0.40, 0.28, 0.08, 0.25)
	div2.size = Vector2(480, 1)
	div2.position = Vector2(30, 194)
	div2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(div2)

	# ── AI 模式 ────────────────────────────────────────
	_settings_row_label(panel, "AI 决策模式", 208)
	var ai_val := Label.new()
	ai_val.text = "DeepSeek 在线深度分析" if Global.use_ai_mode else "本地神经网络决策"
	ai_val.position = Vector2(40, 232)
	ai_val.size = Vector2(380, 24)
	ai_val.add_theme_font_size_override("font_size", 13)
	ai_val.add_theme_color_override("font_color",
		Color(0.48, 0.92, 0.58) if Global.use_ai_mode else Color(0.62, 0.58, 0.50))
	ai_val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(ai_val)

	var ai_btn := _settings_small_btn("切 换", Vector2(40, 262))
	ai_btn.pressed.connect(func():
		Global.use_ai_mode = not Global.use_ai_mode
		ai_val.text = "DeepSeek 在线深度分析" if Global.use_ai_mode else "本地神经网络决策"
		ai_val.add_theme_color_override("font_color",
			Color(0.48, 0.92, 0.58) if Global.use_ai_mode else Color(0.62, 0.58, 0.50))
	)
	panel.add_child(ai_btn)

	var div3 := ColorRect.new()
	div3.color = Color(0.40, 0.28, 0.08, 0.25)
	div3.size = Vector2(480, 1)
	div3.position = Vector2(30, 312)
	div3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(div3)

	# ── 黑魂状态 ───────────────────────────────────────
	_settings_row_label(panel, "黑魂", 322)
	var soul_val := Label.new()
	soul_val.text = "◈  已激活（攻击回血 10%）" if Global.has_black_soul else "未获得（击杀黑无常后可获得）"
	soul_val.position = Vector2(40, 346)
	soul_val.add_theme_font_size_override("font_size", 13)
	soul_val.add_theme_color_override("font_color",
		Color(0.42, 0.92, 0.80) if Global.has_black_soul else Color(0.45, 0.42, 0.38))
	soul_val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(soul_val)

	# ── 关闭按钮 ───────────────────────────────────────
	var close_btn := Button.new()
	close_btn.text = "关  闭"
	close_btn.size = Vector2(160, 44)
	close_btn.position = Vector2((pw - 160) / 2.0, ph - 62)
	close_btn.pressed.connect(func():
		root.queue_free()
		_settings_overlay = null
	)
	panel.add_child(close_btn)

	# 淡入
	root.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 1.0, 0.25)
	return root

func _settings_row_label(parent: Control, text: String, y: float) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(40, y)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.72, 0.62, 0.46))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)

func _settings_small_btn(text: String, pos: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.size = Vector2(160, 34)
	btn.position = pos
	return btn

# ══════════════════════════════════════════════════════
# 场景切换
# ══════════════════════════════════════════════════════
func _fade_to(path: String) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var tw := create_tween()
	tw.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.35)
	tw.tween_callback(func(): get_tree().change_scene_to_file(path))
