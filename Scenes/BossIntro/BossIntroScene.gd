extends Control

# ══════════════════════════════════════════════════════
# Boss 战前剧情
#
# 阶段 A — 旁白幕布（黑底大字，后续可加背景图）
# 阶段 B — 对话（黑无常 vs 主角，后续可加立绘）
#
# 点击任意处：跳过打字 / 推进
# SKIP 按钮：跳过全部剧情，直接进入战斗
# ══════════════════════════════════════════════════════

# ── 旁白文字 ──────────────────────────────────────────
const NARRATION := \
	"你走到无间地狱的出口，\n" + \
	"看着眼前的白光，心生喜悦。\n\n" + \
	"这时，一道声音从身后传来——"

# ── 对话序列 ──────────────────────────────────────────
const DIALOGUE := [
	{
		"speaker": "黑无常",
		"side":    "right",
		"text":    "冥顽不灵的小孩儿。\n你没喝孟婆汤，还大闹阎罗殿……\n跟我回去，少受皮肉之苦。",
	},
	{
		"speaker": "你",
		"side":    "left",
		"text":    "我心愿未了。\n地府帮不了我伸冤——\n我要回去，谁也拦不住我。",
	},
	{
		"speaker": "黑无常",
		"side":    "right",
		"text":    "哼……\n那便用武力，让你清醒清醒。",
	},
]

# ── 角色名称配色 ──────────────────────────────────────
const SPK_COLORS := {
	"黑无常": Color(0.42, 0.92, 0.80),   # 幽冥青
	"你":     Color(0.96, 0.82, 0.40),   # 暖金
}

const TYPE_SPEED  := 0.038   # 秒/字符
const FADE_FAST   := 0.30    # 快淡出（旁白→对话）
const FADE_SLOW   := 0.50    # 慢淡入（开场/结束）

# ── 状态机 ────────────────────────────────────────────
enum Phase { FADE_IN, TYPING, WAIT, TRANSITIONING }

var _phase:      Phase  = Phase.FADE_IN
var _mode:       String = "narration"   # "narration" | "dialogue"
var _dial_idx:   int    = 0
var _char_pos:   int    = 0
var _type_acc:   float  = 0.0
var _full_text:  String = ""
var _blink_tw:   Tween  = null

# 立绘
var _hero_portrait: TextureRect
var _boss_portrait: TextureRect
const IMG_MAP := {
	"fire":  "res://picture/Heroes/主角/狱火流.png",
	"bone":  "res://picture/Heroes/主角/白骨流.png",
	"blood": "res://picture/Heroes/主角/血煞流.png",
	"ghost": "res://picture/Heroes/主角/幽魂流.png",
	"cycle": "res://picture/Heroes/主角/轮回流.png",
}

# ── UI 节点引用 ────────────────────────────────────────
var _fade_rect:  ColorRect   # 顶层遮罩
var _narr_root:  Control     # 旁白层
var _narr_lbl:   Label
var _narr_hint:  Label
var _dial_root:  Control     # 对话层
var _spk_bg:     ColorRect
var _spk_lbl:    Label
var _dial_lbl:   Label
var _dial_hint:  Label

# ══════════════════════════════════════════════════════
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	# 从旁白开始
	_narr_root.visible  = true
	_dial_root.visible  = false
	_mode               = "narration"
	_full_text          = NARRATION
	_char_pos           = 0
	_type_acc           = 0.0
	_narr_lbl.text      = ""
	_narr_hint.modulate.a = 0.0
	_do_fade_in(FADE_SLOW)

# ══════════════════════════════════════════════════════
# 构建 UI
# ══════════════════════════════════════════════════════
func _build_ui() -> void:
	# 背景图
	var bg := TextureRect.new()
	bg.expand = true
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.set_deferred("size", Vector2(1280, 720))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_tex := load("res://picture/boss剧情前.png")
	if bg_tex:
		bg.texture = bg_tex
	add_child(bg)

	# ── 旁白层 ─────────────────────────────────────────
	_narr_root = Control.new()
	_narr_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_narr_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_narr_root)

	# 旁白文字（居中略偏上）
	_narr_lbl = Label.new()
	_narr_lbl.position = Vector2(200, 232)
	_narr_lbl.size     = Vector2(880, 260)
	_narr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_narr_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_TOP
	_narr_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	_narr_lbl.add_theme_font_size_override("font_size", 26)
	_narr_lbl.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
	_narr_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_narr_root.add_child(_narr_lbl)

	# 旁白继续提示
	_narr_hint = Label.new()
	_narr_hint.text     = "点 击 任 意 处 继 续"
	_narr_hint.position = Vector2(0, 634)
	_narr_hint.size     = Vector2(1280, 26)
	_narr_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_narr_hint.add_theme_font_size_override("font_size", 13)
	_narr_hint.add_theme_color_override("font_color", Color(0.52, 0.48, 0.42))
	_narr_hint.modulate.a = 0.0
	_narr_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_narr_root.add_child(_narr_hint)

	# ── 对话层 ─────────────────────────────────────────
	_dial_root = Control.new()
	_dial_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dial_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dial_root)

	# ── 左侧——主角立绘 ──────────────────────────────
	_hero_portrait = TextureRect.new()
	_hero_portrait.size = Vector2(360, 480)
	_hero_portrait.position = Vector2(10, 40)
	_hero_portrait.expand = true
	_hero_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var hero_path: String = IMG_MAP.get(Global.selected_deck, IMG_MAP["ghost"])
	var hero_tex := load(hero_path)
	if hero_tex:
		_hero_portrait.texture = hero_tex
	_hero_portrait.modulate = Color(0.4, 0.4, 0.4, 1)
	_hero_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial_root.add_child(_hero_portrait)

	# ── 右侧——黑无常立绘 ────────────────────────────
	_boss_portrait = TextureRect.new()
	_boss_portrait.size = Vector2(360, 480)
	_boss_portrait.position = Vector2(910, 40)
	_boss_portrait.expand = true
	_boss_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var boss_tex := load("res://picture/Heroes/怪物/黑无常.png")
	if boss_tex:
		_boss_portrait.texture = boss_tex
	_boss_portrait.modulate = Color(0.4, 0.4, 0.4, 1)
	_boss_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial_root.add_child(_boss_portrait)

	# ── 对话框背景 ───────────────────────────────────
	var box_bg := ColorRect.new()
	box_bg.color    = Color(0.04, 0.03, 0.07, 0.94)
	box_bg.position = Vector2(0, 460)
	box_bg.size     = Vector2(1280, 260)
	box_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial_root.add_child(box_bg)

	# 对话框顶部分割线
	var top_line := ColorRect.new()
	top_line.color    = Color(0.38, 0.32, 0.48, 0.9)
	top_line.position = Vector2(0, 460)
	top_line.size     = Vector2(1280, 2)
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial_root.add_child(top_line)

	# 角色名底色
	_spk_bg = ColorRect.new()
	_spk_bg.size     = Vector2(130, 34)
	_spk_bg.position = Vector2(60, 444)   # 紧贴对话框顶边上方
	_spk_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial_root.add_child(_spk_bg)

	# 角色名标签
	_spk_lbl = Label.new()
	_spk_lbl.size     = Vector2(130, 34)
	_spk_lbl.position = Vector2(60, 444)
	_spk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spk_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_spk_lbl.add_theme_font_size_override("font_size", 15)
	_spk_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial_root.add_child(_spk_lbl)

	# 对话正文
	_dial_lbl = Label.new()
	_dial_lbl.position = Vector2(70, 500)
	_dial_lbl.size     = Vector2(1140, 180)
	_dial_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dial_lbl.add_theme_font_size_override("font_size", 23)
	_dial_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.86))
	_dial_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial_root.add_child(_dial_lbl)

	# 对话推进提示（右下角小三角）
	_dial_hint = Label.new()
	_dial_hint.text     = "▼"
	_dial_hint.position = Vector2(1200, 688)
	_dial_hint.size     = Vector2(50, 24)
	_dial_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dial_hint.add_theme_font_size_override("font_size", 14)
	_dial_hint.add_theme_color_override("font_color", Color(0.65, 0.60, 0.52))
	_dial_hint.modulate.a = 0.0
	_dial_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial_root.add_child(_dial_hint)

	# ── SKIP 按钮 ──────────────────────────────────────
	var skip_btn := Button.new()
	skip_btn.text     = "SKIP  >>"
	skip_btn.size     = Vector2(96, 30)
	skip_btn.position = Vector2(1164, 18)
	skip_btn.pressed.connect(_skip_all)
	add_child(skip_btn)

	# ── 顶层黑色遮罩 ───────────────────────────────────
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 1)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)

# ══════════════════════════════════════════════════════
# 淡入 / 淡出
# ══════════════════════════════════════════════════════
func _do_fade_in(dur: float) -> void:
	_phase = Phase.FADE_IN
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 0.0, dur)
	tw.tween_callback(func(): _phase = Phase.TYPING)

func _do_fade_out(dur: float, callback: Callable) -> void:
	_phase = Phase.TRANSITIONING
	if _blink_tw:
		_blink_tw.kill()
		_blink_tw = null
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, dur)
	tw.tween_callback(callback)

# ══════════════════════════════════════════════════════
# 立绘焦点切换
# ══════════════════════════════════════════════════════
func _update_portrait_focus(speaker: String) -> void:
	if not _hero_portrait or not _boss_portrait:
		return
	var is_hero_speaking := (speaker == "你")
	if is_hero_speaking:
		_tween_portrait(_hero_portrait, Color(1, 1, 1, 1))
		_tween_portrait(_boss_portrait, Color(0.4, 0.4, 0.4, 1))
	else:
		_tween_portrait(_hero_portrait, Color(0.4, 0.4, 0.4, 1))
		_tween_portrait(_boss_portrait, Color(1, 1, 1, 1))

func _tween_portrait(ptr: TextureRect, target_modulate: Color) -> void:
	var tw := create_tween()
	tw.tween_property(ptr, "modulate", target_modulate, 0.25).set_ease(Tween.EASE_OUT)

# ══════════════════════════════════════════════════════
# 旁白结束 → 切换到对话
# ══════════════════════════════════════════════════════
func _narration_done() -> void:
	_do_fade_out(FADE_FAST, func():
		_narr_root.visible = false
		_dial_root.visible = true
		_mode       = "dialogue"
		_dial_idx   = 0
		_load_dialogue(0)
		_do_fade_in(FADE_FAST)
	)

# ══════════════════════════════════════════════════════
# 加载一条对话
# ══════════════════════════════════════════════════════
func _load_dialogue(i: int) -> void:
	var d: Dictionary = DIALOGUE[i]
	var speaker: String = d.get("speaker", "")
	var side:    String = d.get("side", "left")

	_full_text   = d.get("text", "")
	_char_pos    = 0
	_type_acc    = 0.0
	_dial_lbl.text = ""
	_dial_hint.modulate.a = 0.0

	# 角色名颜色
	var sc: Color = SPK_COLORS.get(speaker, Color(0.85, 0.85, 0.85))
	_spk_lbl.text = speaker
	_spk_lbl.add_theme_color_override("font_color", sc)
	_spk_bg.color = sc * Color(1, 1, 1, 0.18)

	# 左/右：名称徽章和文字的水平定位
	if side == "right":
		_spk_bg.position.x   = 1090
		_spk_lbl.position.x  = 1090
		_dial_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	else:
		_spk_bg.position.x   = 60
		_spk_lbl.position.x  = 60
		_dial_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	if _blink_tw:
		_blink_tw.kill()
		_blink_tw = null

	_update_portrait_focus(speaker)

# ══════════════════════════════════════════════════════
# 打字完成后的提示闪烁
# ══════════════════════════════════════════════════════
func _show_narr_hint() -> void:
	_phase = Phase.WAIT
	_blink_tw = create_tween().set_loops()
	_blink_tw.tween_property(_narr_hint, "modulate:a", 0.12, 0.72)
	_blink_tw.tween_property(_narr_hint, "modulate:a", 0.88, 0.72)

func _show_dial_hint() -> void:
	_phase = Phase.WAIT
	_blink_tw = create_tween().set_loops()
	_blink_tw.tween_property(_dial_hint, "modulate:a", 0.10, 0.55)
	_blink_tw.tween_property(_dial_hint, "modulate:a", 0.95, 0.55)

# ══════════════════════════════════════════════════════
# _process 驱动打字机
# ══════════════════════════════════════════════════════
func _process(delta: float) -> void:
	if _phase != Phase.TYPING: return
	_type_acc += delta
	while _type_acc >= TYPE_SPEED and _char_pos < _full_text.length():
		_type_acc -= TYPE_SPEED
		_char_pos += 1
		if _mode == "narration":
			_narr_lbl.text = _full_text.substr(0, _char_pos)
		else:
			_dial_lbl.text = _full_text.substr(0, _char_pos)
	if _char_pos >= _full_text.length():
		if _mode == "narration":
			_show_narr_hint()
		else:
			_show_dial_hint()

# ══════════════════════════════════════════════════════
# 点击推进
# ══════════════════════════════════════════════════════
func _input(event: InputEvent) -> void:
	if _phase == Phase.FADE_IN or _phase == Phase.TRANSITIONING: return
	if not (event is InputEventMouseButton): return
	var mb := event as InputEventMouseButton
	if not (mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT): return

	match _phase:
		Phase.TYPING:
			# 跳过打字，立即显示全文
			_char_pos = _full_text.length()
			if _mode == "narration":
				_narr_lbl.text = _full_text
				_show_narr_hint()
			else:
				_dial_lbl.text = _full_text
				_show_dial_hint()

		Phase.WAIT:
			if _mode == "narration":
				_narration_done()
			else:
				_dial_idx += 1
				if _dial_idx >= DIALOGUE.size():
					_go_to_battle()
				else:
					if _blink_tw:
						_blink_tw.kill()
						_blink_tw = null
					_load_dialogue(_dial_idx)
					_phase = Phase.TYPING

# ══════════════════════════════════════════════════════
# SKIP：跳过全部剧情
# ══════════════════════════════════════════════════════
func _skip_all() -> void:
	if _phase == Phase.TRANSITIONING: return
	_go_to_battle()

# ══════════════════════════════════════════════════════
# 进入战斗
# ══════════════════════════════════════════════════════
func _go_to_battle() -> void:
	_do_fade_out(FADE_SLOW, func():
		get_tree().change_scene_to_file("res://Scenes/Battle/BattleScene.tscn")
	)
