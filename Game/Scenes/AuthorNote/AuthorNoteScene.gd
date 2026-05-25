extends Control

# ══════════════════════════════════════════════════════
# 作者的话 —— 首次进入游戏时显示，点击后进入主菜单
# ══════════════════════════════════════════════════════

const AUTHOR_TEXT := \
	"我是 mmk，这款游戏的设计师之一。\n\n" + \
	"这是我们一天打磨的作品，\n" + \
	"如有不足请多多担待。\n\n" + \
	"希望你能享受这款游戏。"

const TYPE_SPEED := 0.045
const FADE_DUR   := 0.55

enum Phase { FADE_IN, TYPING, WAIT, DONE }

var _phase:    Phase  = Phase.FADE_IN
var _char_pos: int    = 0
var _type_acc: float  = 0.0
var _blink_tw: Tween  = null

var _text_lbl:  Label
var _hint_lbl:  Label
var _fade_rect: ColorRect

# ══════════════════════════════════════════════════════
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_do_fade_in()

func _build_ui() -> void:
	# 深色背景
	var bg := ColorRect.new()
	bg.color = Color(0.030, 0.018, 0.042)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 顶部微光装饰线
	var ln1 := ColorRect.new()
	ln1.color = Color(0.58, 0.38, 0.14, 0.55)
	ln1.size = Vector2(360, 1)
	ln1.position = Vector2(460, 198)
	ln1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ln1)

	var ln2 := ColorRect.new()
	ln2.color = Color(0.58, 0.38, 0.14, 0.55)
	ln2.size = Vector2(360, 1)
	ln2.position = Vector2(460, 262)
	ln2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ln2)

	# 标题标签
	var from_lbl := Label.new()
	from_lbl.text = "—  来自开发者  —"
	from_lbl.position = Vector2(0, 208)
	from_lbl.size = Vector2(1280, 30)
	from_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	from_lbl.add_theme_font_size_override("font_size", 14)
	from_lbl.add_theme_color_override("font_color", Color(0.62, 0.50, 0.30))
	from_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(from_lbl)

	# 正文（打字机效果）
	_text_lbl = Label.new()
	_text_lbl.position = Vector2(240, 280)
	_text_lbl.size     = Vector2(800, 260)
	_text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_TOP
	_text_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
	_text_lbl.add_theme_font_size_override("font_size", 24)
	_text_lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.80))
	_text_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text_lbl)

	# 签名
	var sig := Label.new()
	sig.text = "—  mmk Studio"
	sig.position = Vector2(0, 552)
	sig.size = Vector2(1280, 26)
	sig.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sig.add_theme_font_size_override("font_size", 13)
	sig.add_theme_color_override("font_color", Color(0.50, 0.40, 0.22))
	sig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sig)

	# 继续提示（等打字完成后闪烁）
	_hint_lbl = Label.new()
	_hint_lbl.text     = "点 击 任 意 处 继 续"
	_hint_lbl.position = Vector2(0, 634)
	_hint_lbl.size     = Vector2(1280, 26)
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override("font_size", 13)
	_hint_lbl.add_theme_color_override("font_color", Color(0.52, 0.46, 0.38))
	_hint_lbl.modulate.a = 0.0
	_hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint_lbl)

	# 顶层黑色淡入遮罩
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 1)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)

# ══════════════════════════════════════════════════════
func _do_fade_in() -> void:
	_phase = Phase.FADE_IN
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 0.0, FADE_DUR)
	tw.tween_callback(func(): _phase = Phase.TYPING)

func _process(delta: float) -> void:
	if _phase != Phase.TYPING: return
	_type_acc += delta
	var full := AUTHOR_TEXT
	while _type_acc >= TYPE_SPEED and _char_pos < full.length():
		_type_acc -= TYPE_SPEED
		_char_pos += 1
		_text_lbl.text = full.substr(0, _char_pos)
	if _char_pos >= full.length():
		_phase = Phase.WAIT
		_blink_tw = create_tween().set_loops()
		_blink_tw.tween_property(_hint_lbl, "modulate:a", 0.12, 0.72)
		_blink_tw.tween_property(_hint_lbl, "modulate:a", 0.90, 0.72)

func _input(event: InputEvent) -> void:
	if _phase == Phase.FADE_IN or _phase == Phase.DONE: return
	if not (event is InputEventMouseButton): return
	var mb := event as InputEventMouseButton
	if not (mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT): return

	if _phase == Phase.TYPING:
		_char_pos = AUTHOR_TEXT.length()
		_text_lbl.text = AUTHOR_TEXT
		_phase = Phase.WAIT
		_blink_tw = create_tween().set_loops()
		_blink_tw.tween_property(_hint_lbl, "modulate:a", 0.12, 0.72)
		_blink_tw.tween_property(_hint_lbl, "modulate:a", 0.90, 0.72)
	elif _phase == Phase.WAIT:
		_phase = Phase.DONE
		if _blink_tw:
			_blink_tw.kill()
			_blink_tw = null
		Global.author_note_shown = true
		var tw := create_tween()
		tw.tween_property(_fade_rect, "color:a", 1.0, FADE_DUR)
		tw.tween_callback(func():
			get_tree().change_scene_to_file("res://Scenes/MainMenu/MainMenuScene.tscn"))
