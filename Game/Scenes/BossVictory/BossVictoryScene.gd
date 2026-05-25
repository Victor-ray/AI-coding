extends Control

# ══════════════════════════════════════════════════════
# Boss 战胜利过场
#
# [对话 3 行] → [卡牌选择] → [告别台词] → [结尾旁白] → 主菜单
# ══════════════════════════════════════════════════════

const DIALOGUE := [
	{
		"speaker": "黑无常",
		"side":    "right",
		"text":    "就算你赢了我……\n前面还有牛头马面，十殿阎王。\n你真以为，你能走得掉？",
	},
	{
		"speaker": "你",
		"side":    "left",
		"text":    "牛头马面，十殿阎王……\n正好，一个一个来。\n\n我既然来了——就没打算回头。",
	},
]

const ENDING_TEXT := \
	"你踏出了无间地狱的大门。\n\n" + \
	"阳光，照在脸上——\n\n" + \
	"好久不见了。"

const SPK_COLORS := {
	"黑无常": Color(0.42, 0.92, 0.80),
	"你":     Color(0.96, 0.82, 0.40),
}

const TYPE_SPEED := 0.038
const FADE_FAST  := 0.32
const FADE_SLOW  := 0.55

enum Phase { FADE_IN, TYPING, WAIT, TRANSITIONING }
enum Mode  { DIALOGUE, FAREWELL, ENDING }

var _phase:           Phase  = Phase.FADE_IN
var _mode:            Mode   = Mode.DIALOGUE
var _dial_idx:        int    = 0
var _char_pos:        int    = 0
var _type_acc:        float  = 0.0
var _full_text:       String = ""
var _blink_tw:        Tween  = null
var _farewell_text:   String = ""   # 告别台词（选卡后赋值）

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

# UI
var _fade_rect:  ColorRect
var _dial_root:  Control
var _spk_bg:     ColorRect
var _spk_lbl:    Label
var _dial_lbl:   Label
var _dial_hint:  Label
var _end_root:   Control
var _end_lbl:    Label
var _end_hint:   Label

# ══════════════════════════════════════════════════════
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_load_dialogue(0)
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
	var bg_tex := load("res://picture/boss战之后剧情.png")
	if bg_tex:
		bg.texture = bg_tex
	add_child(bg)

	# 半透明遮罩（确保文字可读）
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

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
	add_child(_hero_portrait)

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
	add_child(_boss_portrait)

	# ── 对话层 ─────────────────────────────────────────
	_dial_root = Control.new()
	_dial_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dial_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dial_root)

	var ph := Label.new()
	ph.position = Vector2(0, 200)
	ph.size = Vector2(1280, 30)
	ph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ph.add_theme_font_size_override("font_size", 12)
	ph.add_theme_color_override("font_color", Color(0.22, 0.20, 0.20))
	ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial_root.add_child(ph)

	var box_bg := ColorRect.new()
	box_bg.color    = Color(0.04, 0.03, 0.07, 0.94)
	box_bg.position = Vector2(0, 460)
	box_bg.size     = Vector2(1280, 260)
	box_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial_root.add_child(box_bg)

	var top_line := ColorRect.new()
	top_line.color    = Color(0.38, 0.32, 0.48, 0.9)
	top_line.position = Vector2(0, 460)
	top_line.size     = Vector2(1280, 2)
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial_root.add_child(top_line)

	_spk_bg = ColorRect.new()
	_spk_bg.size     = Vector2(130, 34)
	_spk_bg.position = Vector2(60, 444)
	_spk_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial_root.add_child(_spk_bg)

	_spk_lbl = Label.new()
	_spk_lbl.size     = Vector2(130, 34)
	_spk_lbl.position = Vector2(60, 444)
	_spk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spk_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_spk_lbl.add_theme_font_size_override("font_size", 15)
	_spk_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial_root.add_child(_spk_lbl)

	_dial_lbl = Label.new()
	_dial_lbl.position = Vector2(70, 500)
	_dial_lbl.size     = Vector2(1140, 180)
	_dial_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dial_lbl.add_theme_font_size_override("font_size", 23)
	_dial_lbl.add_theme_color_override("font_color", Color(0.95, 0.92, 0.86))
	_dial_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial_root.add_child(_dial_lbl)

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

	# ── 结尾旁白层 ─────────────────────────────────────
	_end_root = Control.new()
	_end_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_root.visible = false
	add_child(_end_root)

	_end_lbl = Label.new()
	_end_lbl.position = Vector2(200, 248)
	_end_lbl.size     = Vector2(880, 260)
	_end_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_TOP
	_end_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_end_lbl.add_theme_font_size_override("font_size", 28)
	_end_lbl.add_theme_color_override("font_color", Color(0.95, 0.93, 0.88))
	_end_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_root.add_child(_end_lbl)

	_end_hint = Label.new()
	_end_hint.text     = "点 击 任 意 处 继 续"
	_end_hint.position = Vector2(0, 634)
	_end_hint.size     = Vector2(1280, 26)
	_end_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_end_hint.add_theme_font_size_override("font_size", 13)
	_end_hint.add_theme_color_override("font_color", Color(0.52, 0.48, 0.42))
	_end_hint.modulate.a = 0.0
	_end_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_root.add_child(_end_hint)

	# SKIP 按钮
	var skip_btn := Button.new()
	skip_btn.text     = "SKIP  >>"
	skip_btn.size     = Vector2(96, 30)
	skip_btn.position = Vector2(1164, 18)
	skip_btn.pressed.connect(_skip_all)
	add_child(skip_btn)

	# 顶层遮罩
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
	_kill_blink()
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, dur)
	tw.tween_callback(callback)

func _kill_blink() -> void:
	if _blink_tw:
		_blink_tw.kill()
		_blink_tw = null

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
# 加载对话行
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
	_kill_blink()

	var sc: Color = SPK_COLORS.get(speaker, Color(0.85, 0.85, 0.85))
	_spk_lbl.text = speaker
	_spk_lbl.add_theme_color_override("font_color", sc)
	_spk_bg.color = sc * Color(1, 1, 1, 0.18)

	if side == "right":
		_spk_bg.position.x  = 1090
		_spk_lbl.position.x = 1090
		_dial_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	else:
		_spk_bg.position.x  = 60
		_spk_lbl.position.x = 60
		_dial_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	_update_portrait_focus(speaker)

# ══════════════════════════════════════════════════════
# 结尾旁白
# ══════════════════════════════════════════════════════
func _switch_to_ending() -> void:
	_do_fade_out(FADE_FAST, func():
		_dial_root.visible  = false
		_end_root.visible   = true
		_hero_portrait.visible = false
		_boss_portrait.visible = false
		_mode      = Mode.ENDING
		_full_text = ENDING_TEXT
		_char_pos  = 0
		_type_acc  = 0.0
		_end_lbl.text = ""
		_end_hint.modulate.a = 0.0
		_do_fade_in(FADE_FAST)
	)

# ══════════════════════════════════════════════════════
# 打字机
# ══════════════════════════════════════════════════════
func _process(delta: float) -> void:
	if _phase != Phase.TYPING: return
	_type_acc += delta
	while _type_acc >= TYPE_SPEED and _char_pos < _full_text.length():
		_type_acc -= TYPE_SPEED
		_char_pos += 1
		match _mode:
			Mode.DIALOGUE, Mode.FAREWELL:
				_dial_lbl.text = _full_text.substr(0, _char_pos)
			Mode.ENDING:
				_end_lbl.text = _full_text.substr(0, _char_pos)
	if _char_pos >= _full_text.length():
		_show_hint()

func _show_hint() -> void:
	_phase = Phase.WAIT
	if _mode == Mode.ENDING:
		_blink_tw = create_tween().set_loops()
		_blink_tw.tween_property(_end_hint, "modulate:a", 0.12, 0.75)
		_blink_tw.tween_property(_end_hint, "modulate:a", 0.90, 0.75)
	else:
		_blink_tw = create_tween().set_loops()
		_blink_tw.tween_property(_dial_hint, "modulate:a", 0.10, 0.55)
		_blink_tw.tween_property(_dial_hint, "modulate:a", 0.95, 0.55)

# ══════════════════════════════════════════════════════
# 点击处理
# ══════════════════════════════════════════════════════
func _input(event: InputEvent) -> void:
	if _phase == Phase.FADE_IN or _phase == Phase.TRANSITIONING: return
	if not (event is InputEventMouseButton): return
	var mb := event as InputEventMouseButton
	if not (mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT): return

	match _phase:
		Phase.TYPING:
			_char_pos = _full_text.length()
			match _mode:
				Mode.DIALOGUE, Mode.FAREWELL:
					_dial_lbl.text = _full_text
				Mode.ENDING:
					_end_lbl.text = _full_text
			_show_hint()

		Phase.WAIT:
			match _mode:
				Mode.DIALOGUE:
					_dial_idx += 1
					if _dial_idx >= DIALOGUE.size():
						_show_card_choice()   # 3 行对话结束 → 卡牌选择
					else:
						_kill_blink()
						_load_dialogue(_dial_idx)
						_phase = Phase.TYPING
				Mode.FAREWELL:
					_switch_to_ending()       # 告别台词结束 → 旁白
				Mode.ENDING:
					_go_to_main_menu()        # 旁白结束 → 主菜单

# ══════════════════════════════════════════════════════
func _skip_all() -> void:
	if _phase == Phase.TRANSITIONING: return
	_go_to_main_menu()

# ══════════════════════════════════════════════════════
# 卡牌道具选择
# ══════════════════════════════════════════════════════
func _show_card_choice() -> void:
	_kill_blink()
	_phase = Phase.TRANSITIONING

	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# 背景遮罩
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)

	# 标题
	var title := Label.new()
	title.text = "—  你如何处置倒下的黑无常？  —"
	title.position = Vector2(0, 112)
	title.size = Vector2(1280, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.82, 0.74, 0.52))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(title)

	# ── 两张道具卡 ─────────────────────────────────────
	# 击杀 → 黑魂（左）
	var card_kill := _make_item_card(
		"击杀黑无常",
		"黑  魂",
		"◈",
		"永久获得吸血能力\n每次攻击回复\n伤害量 10% 的生命",
		Color(0.42, 0.06, 0.06),          # 卡背色（暗红）
		Color(0.42, 0.92, 0.80),           # 文字色（幽冥青）
		Color(0.78, 0.18, 0.22),           # 边框色
		Vector2(300, 160)
	)
	card_kill.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton:
			var mb2 := ev as InputEventMouseButton
			if mb2.pressed and mb2.button_index == MOUSE_BUTTON_LEFT:
				_on_item_chosen(overlay, true)
	)
	overlay.add_child(card_kill)

	# 放过 → 判官笔（右）
	var card_spare := _make_item_card(
		"放过黑无常",
		"判 官 笔",
		"✒",
		"使用后增益一次攻击\n伤害提升至 150%\n（出战时自动激活）",
		Color(0.06, 0.10, 0.28),           # 卡背色（深蓝）
		Color(0.96, 0.82, 0.40),           # 文字色（暖金）
		Color(0.34, 0.52, 0.88),           # 边框色
		Vector2(680, 160)
	)
	card_spare.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton:
			var mb2 := ev as InputEventMouseButton
			if mb2.pressed and mb2.button_index == MOUSE_BUTTON_LEFT:
				_on_item_chosen(overlay, false)
	)
	overlay.add_child(card_spare)

	# 悬停提示
	var sub := Label.new()
	sub.text = "点击卡牌选择"
	sub.position = Vector2(0, 570)
	sub.size = Vector2(1280, 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.50, 0.46, 0.38, 0.70))
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(sub)

	# 淡入
	overlay.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 1.0, 0.38)

# ── 道具卡制作 ────────────────────────────────────────
func _make_item_card(action: String, item_name: String, icon: String,
		desc: String, bg_col: Color, accent: Color, border_col: Color,
		pos: Vector2) -> Control:

	const CW := 260.0
	const CH := 360.0

	var card := Control.new()
	card.size     = Vector2(CW, CH)
	card.position = pos
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	# 卡背板
	var panel := Panel.new()
	var pst := StyleBoxFlat.new()
	pst.bg_color     = bg_col
	pst.border_color = border_col * Color(1, 1, 1, 0.70)
	pst.set_border_width_all(3)
	for prop in ["corner_radius_top_left","corner_radius_top_right",
				 "corner_radius_bottom_left","corner_radius_bottom_right"]:
		pst.set(prop, 8)
	panel.add_theme_stylebox_override("panel", pst)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(panel)

	# 顶部类型条
	var type_bar := ColorRect.new()
	type_bar.color    = border_col * Color(1, 1, 1, 0.22)
	type_bar.size     = Vector2(CW, 38)
	type_bar.position = Vector2(0, 0)
	type_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(type_bar)

	var type_lbl := Label.new()
	type_lbl.text = "★  道  具  ★"
	type_lbl.size = Vector2(CW, 38)
	type_lbl.position = Vector2(0, 0)
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 13)
	type_lbl.add_theme_color_override("font_color", accent * Color(1, 1, 1, 0.80))
	type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(type_lbl)

	# 图标
	var icon_lbl := Label.new()
	icon_lbl.text = icon
	icon_lbl.size = Vector2(CW, 54)
	icon_lbl.position = Vector2(0, 50)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 40)
	icon_lbl.add_theme_color_override("font_color", accent)
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon_lbl)

	# 道具名
	var name_lbl := Label.new()
	name_lbl.text = item_name
	name_lbl.size = Vector2(CW, 48)
	name_lbl.position = Vector2(0, 108)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.add_theme_color_override("font_color", accent)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	# 分割线
	var div := ColorRect.new()
	div.color    = border_col * Color(1, 1, 1, 0.45)
	div.size     = Vector2(CW - 40, 1)
	div.position = Vector2(20, 162)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(div)

	# 效果描述
	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.size = Vector2(CW - 24, 140)
	desc_lbl.position = Vector2(12, 170)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.88, 0.85, 0.78))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(desc_lbl)

	# 底部行动条
	var act_bar := ColorRect.new()
	act_bar.color    = border_col * Color(1, 1, 1, 0.28)
	act_bar.size     = Vector2(CW, 42)
	act_bar.position = Vector2(0, CH - 42)
	act_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(act_bar)

	var act_lbl := Label.new()
	act_lbl.text = action
	act_lbl.size = Vector2(CW, 42)
	act_lbl.position = Vector2(0, CH - 42)
	act_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	act_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	act_lbl.add_theme_font_size_override("font_size", 15)
	act_lbl.add_theme_color_override("font_color", accent)
	act_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(act_lbl)

	# 鼠标悬停：卡牌上浮
	card.mouse_entered.connect(func():
		var ht := card.create_tween()
		ht.tween_property(card, "position:y", pos.y - 14.0, 0.18).set_ease(Tween.EASE_OUT)
		# 边框增亮
		pst.border_color = border_col
		panel.add_theme_stylebox_override("panel", pst)
	)
	card.mouse_exited.connect(func():
		var ht := card.create_tween()
		ht.tween_property(card, "position:y", pos.y, 0.18).set_ease(Tween.EASE_OUT)
		pst.border_color = border_col * Color(1, 1, 1, 0.70)
		panel.add_theme_stylebox_override("panel", pst)
	)

	return card

# ══════════════════════════════════════════════════════
# 选卡后处理
# ══════════════════════════════════════════════════════
func _on_item_chosen(overlay: Control, kill: bool) -> void:
	# 淡出选择界面
	var tw := create_tween()
	tw.tween_property(overlay, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func():
		overlay.queue_free()

		# 显示对话层
		_dial_root.visible = true
		_end_root.visible  = false

		if kill:
			# ── 击杀路线：黑无常逃遁 ──────────────────────
			Global.has_black_soul = true
			_farewell_text = '黑无常逃遁，留下一句——\n\n"好自为之。"'
			# 黑无常右侧说话
			_spk_lbl.text = "黑无常"
			_spk_bg.position.x  = 1090
			_spk_lbl.position.x = 1090
			_spk_lbl.add_theme_color_override("font_color", Color(0.42, 0.92, 0.80))
			_spk_bg.color = Color(0.42, 0.92, 0.80, 0.18)
			_dial_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_update_portrait_focus("黑无常")
		else:
			# ── 放过路线：判官笔 ────────────────────────────
			Global.has_judge_pen = true
			_farewell_text = "哼……\n下次见面，就没这么好说话了。\n\n好自为之。"
			# 黑无常右侧说话
			_spk_lbl.text = "黑无常"
			_spk_bg.position.x  = 1090
			_spk_lbl.position.x = 1090
			_spk_lbl.add_theme_color_override("font_color", Color(0.42, 0.92, 0.80))
			_spk_bg.color = Color(0.42, 0.92, 0.80, 0.18)
			_dial_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			_update_portrait_focus("黑无常")

		# 打字机输出告别台词，之后点击进旁白
		_mode      = Mode.FAREWELL
		_full_text = _farewell_text
		_char_pos  = 0
		_type_acc  = 0.0
		_dial_lbl.text = ""
		_dial_hint.modulate.a = 0.0
		_phase = Phase.TYPING
	)

# ══════════════════════════════════════════════════════
# 收尾
# ══════════════════════════════════════════════════════
func _go_to_main_menu() -> void:
	Global.is_run_active   = false
	Global.current_node_id = -1
	Global.visited_nodes   = []
	_do_fade_out(FADE_SLOW, func():
		get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenuScene.tscn")
	)
