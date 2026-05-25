extends Control

# ══════════════════════════════════════════════════════
# 登录界面 —— 账号密码风格，密码即API Key
# ══════════════════════════════════════════════════════

const _BUILTIN_ACCOUNT  := "limy"
const _BUILTIN_PASSWORD := "limy666"
const _BUILTIN_API_KEY  := "sk-4bb65ce841f746a1b605a2aef4152baf"

var _account_input:  LineEdit
var _password_input: LineEdit
var _error_lbl:      Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if Global.author_note_shown and not Global.from_settings:
		get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenuScene.tscn")
		return
	Global.from_settings = false
	_build_ui()

func _build_ui() -> void:
	# ── 背景 ──────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Color(0.025, 0.02, 0.055)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 装饰光斑
	for i in 14:
		var dot := ColorRect.new()
		dot.color = Color(0.38, 0.15, 0.65, randf_range(0.02, 0.08))
		var s := randf_range(120, 340)
		dot.size = Vector2(s, s)
		dot.position = Vector2(randf_range(-120, 1400), randf_range(-120, 840))
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dot)

	# ── 中央登录卡片 ──────────────────────────────────
	var card := Panel.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.055, 0.045, 0.095, 0.96)
	cs.border_color = Color(0.42, 0.28, 0.65, 0.55)
	cs.set_border_width_all(2)
	for prop in ["corner_radius_top_left","corner_radius_top_right",
				 "corner_radius_bottom_left","corner_radius_bottom_right"]:
		cs.set(prop, 14)
	card.add_theme_stylebox_override("panel", cs)
	card.size = Vector2(440, 520)
	card.position = Vector2(420, 100)
	add_child(card)

	# ── 卡片内容 ──────────────────────────────────────
	# 主标题
	var title := Label.new()
	title.text = "狱 火 爬 升"
	title.size = Vector2(440, 60)
	title.position = Vector2(0, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.82, 0.55, 1.0))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title)

	# 副标题
	var sub := Label.new()
	sub.text = "AI 博弈  ·  冥府逃生"
	sub.size = Vector2(440, 26)
	sub.position = Vector2(0, 96)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.52, 0.42, 0.65))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sub)

	# 分割线
	var div := ColorRect.new()
	div.color = Color(0.42, 0.28, 0.65, 0.30)
	div.size = Vector2(360, 1)
	div.position = Vector2(40, 138)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(div)

	# ── 账号 ──────────────────────────────────────────
	var acc_lbl := Label.new()
	acc_lbl.text = "账    号"
	acc_lbl.position = Vector2(60, 165)
	acc_lbl.add_theme_font_size_override("font_size", 14)
	acc_lbl.add_theme_color_override("font_color", Color(0.72, 0.68, 0.82))
	acc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(acc_lbl)

	_account_input = LineEdit.new()
	_account_input.placeholder_text = "请输入账号"
	_account_input.size = Vector2(320, 40)
	_account_input.position = Vector2(60, 192)
	_account_input.add_theme_stylebox_override("normal", _make_input_style())
	_account_input.add_theme_stylebox_override("focus", _make_input_focus_style())
	_account_input.add_theme_color_override("font_color", Color(0.92, 0.90, 0.96))
	_account_input.add_theme_color_override("font_placeholder_color", Color(0.38, 0.35, 0.48))
	_account_input.add_theme_font_size_override("font_size", 14)
	card.add_child(_account_input)

	# ── 密码 ──────────────────────────────────────────
	var pwd_lbl := Label.new()
	pwd_lbl.text = "密    码"
	pwd_lbl.position = Vector2(60, 252)
	pwd_lbl.add_theme_font_size_override("font_size", 14)
	pwd_lbl.add_theme_color_override("font_color", Color(0.72, 0.68, 0.82))
	pwd_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(pwd_lbl)

	_password_input = LineEdit.new()
	_password_input.placeholder_text = "请输入密码"
	_password_input.size = Vector2(320, 40)
	_password_input.position = Vector2(60, 279)
	_password_input.secret = true
	_password_input.add_theme_stylebox_override("normal", _make_input_style())
	_password_input.add_theme_stylebox_override("focus", _make_input_focus_style())
	_password_input.add_theme_color_override("font_color", Color(0.92, 0.90, 0.96))
	_password_input.add_theme_color_override("font_placeholder_color", Color(0.38, 0.35, 0.48))
	_password_input.add_theme_font_size_override("font_size", 14)
	card.add_child(_password_input)

	# ── 登录按钮 ──────────────────────────────────────
	var btn_login := Button.new()
	btn_login.text = "登        录"
	btn_login.size = Vector2(320, 48)
	btn_login.position = Vector2(60, 350)
	btn_login.add_theme_stylebox_override("normal",  _make_btn_style(Color(0.35, 0.18, 0.62)))
	btn_login.add_theme_stylebox_override("hover",   _make_btn_style(Color(0.45, 0.25, 0.75)))
	btn_login.add_theme_stylebox_override("pressed", _make_btn_style(Color(0.28, 0.12, 0.50)))
	btn_login.add_theme_color_override("font_color", Color(0.96, 0.94, 1.0))
	btn_login.add_theme_font_size_override("font_size", 16)
	btn_login.pressed.connect(_on_login)
	card.add_child(btn_login)

	# ── 错误提示 ─────────────────────────────────────
	_error_lbl = Label.new()
	_error_lbl.text = ""
	_error_lbl.size = Vector2(320, 22)
	_error_lbl.position = Vector2(60, 402)
	_error_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_error_lbl.add_theme_font_size_override("font_size", 12)
	_error_lbl.add_theme_color_override("font_color", Color(0.95, 0.30, 0.25))
	_error_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(_error_lbl)

	# ── 离线模式按钮 ──────────────────────────────────
	var btn_offline := Button.new()
	btn_offline.text = "离线模式，直接进入"
	btn_offline.size = Vector2(320, 40)
	btn_offline.position = Vector2(60, 428)
	btn_offline.add_theme_stylebox_override("normal",  _make_btn_style(Color(0.10, 0.08, 0.18)))
	btn_offline.add_theme_stylebox_override("hover",   _make_btn_style(Color(0.16, 0.12, 0.25)))
	btn_offline.add_theme_stylebox_override("pressed", _make_btn_style(Color(0.07, 0.05, 0.12)))
	btn_offline.add_theme_color_override("font_color", Color(0.62, 0.58, 0.72))
	btn_offline.add_theme_font_size_override("font_size", 13)
	btn_offline.pressed.connect(_on_offline_mode)
	card.add_child(btn_offline)

	# ── 底部提示 ──────────────────────────────────────
	var hint := Label.new()
	hint.text = "离线模式同样具备AI学习能力"
	hint.size = Vector2(320, 22)
	hint.position = Vector2(60, 478)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.40, 0.36, 0.50))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(hint)

	var hint2 := Label.new()
	hint2.text = "神经网络 × 大语言模型  双重博弈系统"
	hint2.size = Vector2(1280, 24)
	hint2.position = Vector2(0, 660)
	hint2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint2.add_theme_font_size_override("font_size", 12)
	hint2.add_theme_color_override("font_color", Color(0.32, 0.28, 0.42))
	hint2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint2)

# ── 输入框样式 ────────────────────────────────────────
func _make_input_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.035, 0.025, 0.07)
	s.border_color = Color(0.32, 0.25, 0.48, 0.5)
	s.set_border_width_all(1)
	for prop in ["corner_radius_top_left","corner_radius_top_right",
				 "corner_radius_bottom_left","corner_radius_bottom_right"]:
		s.set(prop, 8)
	s.content_margin_left  = 14
	s.content_margin_right = 14
	s.content_margin_top   = 8
	s.content_margin_bottom = 8
	return s

func _make_input_focus_style() -> StyleBoxFlat:
	var s := _make_input_style()
	s.border_color = Color(0.55, 0.38, 0.85, 0.8)
	s.set_border_width_all(2)
	return s

# ── 按钮样式 ─────────────────────────────────────────
func _make_btn_style(bg: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(0)
	for prop in ["corner_radius_top_left","corner_radius_top_right",
				 "corner_radius_bottom_left","corner_radius_bottom_right"]:
		s.set(prop, 8)
	s.content_margin_top    = 8
	s.content_margin_bottom = 8
	return s

# ── 事件处理 ─────────────────────────────────────────
func _on_login() -> void:
	var acc := _account_input.text.strip_edges()
	var pwd := _password_input.text.strip_edges()
	if acc.is_empty() or pwd.is_empty():
		_show_error("请输入账号和密码")
		return
	if acc != _BUILTIN_ACCOUNT or pwd != _BUILTIN_PASSWORD:
		_show_error("账号或密码错误")
		return
	# 验证通过，自动注入内置 API Key
	Global.deepseek_api_key = _BUILTIN_API_KEY
	Global.use_ai_mode = true
	_error_lbl.text = ""
	_go()

func _show_error(msg: String) -> void:
	_error_lbl.text = msg
	# 晃动动画
	var orig_x := _error_lbl.position.x
	var tw := create_tween()
	tw.tween_property(_error_lbl, "position:x", orig_x + 8, 0.04)
	tw.tween_property(_error_lbl, "position:x", orig_x - 8, 0.04)
	tw.tween_property(_error_lbl, "position:x", orig_x + 4, 0.04)
	tw.tween_property(_error_lbl, "position:x", orig_x, 0.04)

func _on_offline_mode() -> void:
	Global.deepseek_api_key = ""
	Global.use_ai_mode = false
	_go()

func _go() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var tw := create_tween()
	tw.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.3)
	tw.tween_callback(func():
		if Global.author_note_shown:
			get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenuScene.tscn")
		else:
			get_tree().change_scene_to_file("res://Scenes/AuthorNote/AuthorNoteScene.tscn"))
