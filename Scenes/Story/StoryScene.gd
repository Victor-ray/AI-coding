extends Control

# ══════════════════════════════════════════════════════
# 开场剧情幕布
# 点击跳过打字 / 点击进入下一段 / 最后一段后跳转角色选择
# ══════════════════════════════════════════════════════

# ── 剧情段落 ──────────────────────────────────────────
const PANELS := [
	{
		"loc":  "阳世  ·  子时",
		"body": "一声惨叫，划破长夜。\n\n当你再次睁开眼睛，\n已身处黄泉道上。",
	},
	{
		"loc":  "",
		"body": "那晚，你被人陷害，\n以「杀人凶手」之名，含冤离世。\n\n真正的凶手，逍遥法外。",
	},
	{
		"loc":  "",
		"body": "脑海中，只浮现一张脸——\n\n年幼的妹妹，\n独自一人，无依无靠……",
	},
	{
		"loc":  "",
		"body": "黑暗中，一道低沉的声音响起——\n\n「  冤魂……\n   我看你，心有不甘。  」",
		"voice": true,   # 神秘人配色
	},
	{
		"loc":  "",
		"body": "「  十八层无间地狱横亘于此。\n   若你能一路突破，\n   我可助你重返人界。  」\n\n「  但你需要一份力量——\n   选择吧。  」",
		"voice": true,
	},
	{
		"loc":  "",
		"body": "你握紧双拳。\n\n为了妹妹，\n就算是地狱，也要闯过去。",
		"last": true,
	},
]

# ── 打字速度与淡入淡出 ────────────────────────────────
const TYPE_SPEED  := 0.042   # 秒/字符
const FADE_SECS   := 0.55

enum Phase { FADE_IN, TYPING, WAIT, FADE_OUT }

var _phase:     Phase  = Phase.FADE_IN
var _idx:       int    = 0
var _char_pos:  int    = 0
var _type_acc:  float  = 0.0
var _full_text: String = ""

# ── UI 节点 ────────────────────────────────────────────
var _fade_rect : ColorRect   # 黑色遮罩，用于整体淡入淡出
var _loc_lbl   : Label
var _body_lbl  : Label
var _hint_lbl  : Label
var _div_rect  : ColorRect   # 小分割线（仅 loc 非空时显示）
var _blink_tw  : Tween = null

# ══════════════════════════════════════════════════════
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_load_panel(0)
	_do_fade_in()

# ══════════════════════════════════════════════════════
# 构建 UI
# ══════════════════════════════════════════════════════
func _build_ui() -> void:
	# 纯黑背景
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 地点/时间（小字，居中上方）
	_loc_lbl = Label.new()
	_loc_lbl.position = Vector2(0, 188)
	_loc_lbl.size = Vector2(1280, 28)
	_loc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loc_lbl.add_theme_font_size_override("font_size", 13)
	_loc_lbl.add_theme_color_override("font_color", Color(0.48, 0.44, 0.38))
	_loc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_loc_lbl)

	# 地点下方分割线
	_div_rect = ColorRect.new()
	_div_rect.color = Color(0.35, 0.32, 0.26, 0.55)
	_div_rect.size = Vector2(180, 1)
	_div_rect.position = Vector2(550, 220)
	_div_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_div_rect)

	# 主体文字（居中，垂直偏上）
	_body_lbl = Label.new()
	_body_lbl.position = Vector2(220, 248)
	_body_lbl.size = Vector2(840, 340)
	_body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_lbl.add_theme_font_size_override("font_size", 26)
	_body_lbl.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
	_body_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body_lbl)

	# 底部提示（闪烁）
	_hint_lbl = Label.new()
	_hint_lbl.position = Vector2(0, 630)
	_hint_lbl.size = Vector2(1280, 26)
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override("font_size", 13)
	_hint_lbl.add_theme_color_override("font_color", Color(0.52, 0.48, 0.42))
	_hint_lbl.modulate.a = 0.0
	_hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint_lbl)

	# 淡入淡出遮罩（最上层）
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 1)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)

	# SKIP 按钮
	var skip_btn := Button.new()
	skip_btn.text     = "SKIP  >>"
	skip_btn.size     = Vector2(96, 30)
	skip_btn.position = Vector2(1164, 18)
	skip_btn.pressed.connect(_skip_all)
	add_child(skip_btn)

# ══════════════════════════════════════════════════════
# 加载一段剧情
# ══════════════════════════════════════════════════════
func _load_panel(i: int) -> void:
	var p: Dictionary = PANELS[i]
	var loc: String = p.get("loc", "")

	_loc_lbl.text        = loc
	_div_rect.visible    = not loc.is_empty()
	_body_lbl.text       = ""
	_full_text           = p.get("body", "")
	_char_pos            = 0
	_type_acc            = 0.0
	_hint_lbl.modulate.a = 0.0
	_hint_lbl.text       = "选择你的力量  →" if p.get("last", false) \
	                       else "点 击 任 意 处 继 续"

	# 神秘人配色（紫白色）
	var body_color: Color = Color(0.85, 0.78, 0.98) if p.get("voice", false) \
	                      else Color(0.95, 0.93, 0.88)
	_body_lbl.add_theme_color_override("font_color", body_color)

	if _blink_tw:
		_blink_tw.kill()
		_blink_tw = null

# ══════════════════════════════════════════════════════
# 淡入 / 淡出
# ══════════════════════════════════════════════════════
func _do_fade_in() -> void:
	_phase = Phase.FADE_IN
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 0.0, FADE_SECS)
	tw.tween_callback(func(): _phase = Phase.TYPING)

func _do_fade_out() -> void:
	_phase = Phase.FADE_OUT
	if _blink_tw:
		_blink_tw.kill()
		_blink_tw = null
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, FADE_SECS * 0.65)
	tw.tween_callback(func():
		_idx += 1
		if _idx >= PANELS.size():
			get_tree().change_scene_to_file(
				"res://Scenes/Select/CharacterSelectScene.tscn")
		else:
			_load_panel(_idx)
			_do_fade_in()
	)

# ══════════════════════════════════════════════════════
# 打字完成后显示提示
# ══════════════════════════════════════════════════════
func _show_hint() -> void:
	_phase = Phase.WAIT
	_blink_tw = create_tween().set_loops()
	_blink_tw.tween_property(_hint_lbl, "modulate:a", 0.15, 0.75)
	_blink_tw.tween_property(_hint_lbl, "modulate:a", 0.90, 0.75)

# ══════════════════════════════════════════════════════
# 打字逻辑（_process 驱动）
# ══════════════════════════════════════════════════════
func _process(delta: float) -> void:
	if _phase != Phase.TYPING: return
	_type_acc += delta
	while _type_acc >= TYPE_SPEED and _char_pos < _full_text.length():
		_type_acc -= TYPE_SPEED
		_char_pos += 1
		_body_lbl.text = _full_text.substr(0, _char_pos)
	if _char_pos >= _full_text.length():
		_show_hint()

# ══════════════════════════════════════════════════════
# 点击输入
# ══════════════════════════════════════════════════════
func _input(event: InputEvent) -> void:
	if _phase == Phase.FADE_IN or _phase == Phase.FADE_OUT: return
	if not (event is InputEventMouseButton): return
	var mb := event as InputEventMouseButton
	if not (mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT): return

	match _phase:
		Phase.TYPING:
			# 跳过打字，立即显示全文
			_char_pos = _full_text.length()
			_body_lbl.text = _full_text
			_show_hint()
		Phase.WAIT:
			_do_fade_out()

# ══════════════════════════════════════════════════════
# SKIP：跳过全部剧情
# ══════════════════════════════════════════════════════
func _skip_all() -> void:
	if _phase == Phase.FADE_OUT or _phase == Phase.FADE_IN: return
	_idx = PANELS.size()
	_do_fade_out()
