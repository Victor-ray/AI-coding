extends Control

var _hp_lbl : Label
var _msg_lbl: Label
var _rested  := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	# 背景
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.08, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# 装饰色块（营造氛围）
	for i in 6:
		var glimmer := ColorRect.new()
		glimmer.color = Color(0.08, 0.22, 0.18, 0.18)
		glimmer.size = Vector2(randf_range(60, 180), randf_range(60, 180))
		glimmer.position = Vector2(randf_range(0, 1200), randf_range(80, 600))
		glimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(glimmer)

	# 地点名
	var place := Label.new()
	place.text = "望  乡  台"
	place.position = Vector2(0, 20)
	place.size = Vector2(1280, 56)
	place.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place.add_theme_font_size_override("font_size", 38)
	place.add_theme_color_override("font_color", Color(0.48, 0.88, 0.68))
	place.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(place)

	# 描述文字
	var lore := Label.new()
	lore.text = "据传此处可俯瞰阳间，亡魂于此稍歇，往事如烟，业火暂熄。"
	lore.position = Vector2(0, 84)
	lore.size = Vector2(1280, 28)
	lore.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lore.add_theme_font_size_override("font_size", 13)
	lore.add_theme_color_override("font_color", Color(0.52, 0.60, 0.52))
	lore.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lore)

	# HP 显示
	_hp_lbl = Label.new()
	_hp_lbl.position = Vector2(0, 130)
	_hp_lbl.size = Vector2(1280, 28)
	_hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_lbl.add_theme_font_size_override("font_size", 16)
	_hp_lbl.add_theme_color_override("font_color", Color(0.42, 0.88, 0.50))
	_hp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_lbl)
	_refresh_hp()

	# 两个选项
	_make_option(
		"休养生息",
		"回复 %d 点HP（当前HP的30%%）" % int(Global.player_max_hp * 0.3),
		Color(0.08, 0.28, 0.18), Color(0.38, 0.92, 0.55),
		Vector2(280, 220), "rest"
	)
	_make_option(
		"苦心修炼",
		"永久最大HP\n+15",
		Color(0.18, 0.12, 0.28), Color(0.68, 0.45, 0.92),
		Vector2(740, 220), "train"
	)

	# 消息
	_msg_lbl = Label.new()
	_msg_lbl.position = Vector2(0, 580)
	_msg_lbl.size = Vector2(1280, 28)
	_msg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_lbl.add_theme_font_size_override("font_size", 14)
	_msg_lbl.add_theme_color_override("font_color", Color(0.92, 0.82, 0.38))
	_msg_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_msg_lbl)

	# 离开
	var leave := Button.new()
	leave.text = "继续前行"
	leave.size = Vector2(160, 44)
	leave.position = Vector2(560, 630)
	leave.pressed.connect(_leave)
	add_child(leave)

func _make_option(title: String, desc: String,
		bg_col: Color, accent: Color, pos: Vector2, action: String) -> void:
	var w := 240
	var h := 280
	var panel := Control.new()
	panel.position = pos
	panel.size = Vector2(w, h)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)

	var bg := ColorRect.new()
	bg.color = bg_col
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	var border := ReferenceRect.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.border_color = accent * Color(1,1,1,0.7)
	border.border_width = 1.5
	border.editor_only = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(border)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.size = Vector2(w, 36)
	title_lbl.position = Vector2(0, 20)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", accent)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = desc
	desc_lbl.size = Vector2(w - 16, 120)
	desc_lbl.position = Vector2(8, 68)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.80, 0.72))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(desc_lbl)

	var btn := Button.new()
	btn.text = "选择"
	btn.size = Vector2(w - 24, 34)
	btn.position = Vector2(12, h - 46)
	btn.pressed.connect(func(): _do_action(action, btn))
	panel.add_child(btn)

func _do_action(action: String, btn: Button) -> void:
	if _rested:
		_msg("已经选择过了，请继续前行"); return
	_rested = true
	btn.disabled = true
	match action:
		"rest":
			var heal := int(Global.player_max_hp * 0.3)
			heal = mini(heal, Global.player_max_hp - Global.player_hp)
			Global.player_hp += heal
			_msg("你在望乡台歇息，回复了 %d 点HP。" % heal)
		"train":
			Global.player_max_hp += 15
			Global.player_hp = mini(Global.player_hp + 15, Global.player_max_hp)
			_msg("苦心修炼，最大HP永久提升15点。")
	_refresh_hp()

func _refresh_hp() -> void:
	_hp_lbl.text = "当前HP：%d / %d" % [Global.player_hp, Global.player_max_hp]

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
	tw.tween_callback(func():
		get_tree().change_scene_to_file("res://Scenes/Map/MapScene.tscn"))
