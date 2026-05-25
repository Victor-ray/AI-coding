extends Control

# ══════════════════════════════════════════════════════
# 第十八层：无间地狱  —  地图
# 15 节点 / 多分支 / 六边形节点 / 动态余烬背景
# ══════════════════════════════════════════════════════
const LAYER_NAME := "第十八层：无间地狱"

# ── 节点配色 ──────────────────────────────────────────
const TYPE_BG := {
	"battle": Color(0.40, 0.06, 0.04),
	"elite":  Color(0.46, 0.18, 0.02),
	"shop":   Color(0.28, 0.20, 0.02),
	"rest":   Color(0.04, 0.20, 0.14),
	"boss":   Color(0.34, 0.02, 0.08),
}
const TYPE_ACCENT := {
	"battle": Color(0.95, 0.34, 0.28),
	"elite":  Color(1.00, 0.66, 0.18),
	"shop":   Color(0.98, 0.88, 0.26),
	"rest":   Color(0.32, 0.92, 0.56),
	"boss":   Color(1.00, 0.22, 0.34),
}
const TYPE_ICON := {
	"battle": "战", "elite": "精", "shop": "店", "rest": "息", "boss": "王",
}
const TYPE_NAME := {
	"battle": "普通战斗",
	"elite":  "精英战斗",
	"shop":   "黄泉客栈",
	"rest":   "望乡台",
	"boss":   "无间狱主",
}

const NODE_R      := 36.0    # 六边形外接圆半径
const PULSE_SPEED := 2.6     # 可用节点脉冲速度

# ══════════════════════════════════════════════════════
# 地图节点（15 个，8 层，多分支全部指向 Boss）
# ══════════════════════════════════════════════════════
#
#   L0      L1        L2        L3        L4        L5        L6      L7
#  [0] ─┬─[1]──┬─[3]elite──[6]shop──[8]elite─[11]battle──[13]rest──[14]boss
#        │     └─[4]battle─┤       └─[9]rest─┤
#        └─[2]shop──┬─[4]  └─[7]battle──┤    └─[12]battle─┘
#                   └─[5]rest──[7]       └─[10]shop─[12]
#
const NODES := [
	# ── L0 入口 ────────────────────────────────────────
	{"id": 0, "type": "battle", "pos": Vector2(82, 355),
	 "next": [1, 2],
	 "enemy": {"name": "刀锯鬼卒", "hp": 18, "atk": 8, "souls": 30}},

	# ── L1 第一分叉 ────────────────────────────────────
	{"id": 1, "type": "battle", "pos": Vector2(252, 188),
	 "next": [3, 4],
	 "enemy": {"name": "刀锯鬼卒", "hp": 22, "atk": 9, "souls": 35}},
	{"id": 2, "type": "shop",   "pos": Vector2(252, 528),
	 "next": [4, 5],
	 "enemy": {}},

	# ── L2 三叉 ────────────────────────────────────────
	{"id": 3, "type": "elite",  "pos": Vector2(422, 128),
	 "next": [6],
	 "enemy": {"name": "熔铁判官", "hp": 42, "atk": 12, "souls": 60}},
	{"id": 4, "type": "battle", "pos": Vector2(422, 328),
	 "next": [6, 7],
	 "enemy": {"name": "锁魂鬼差", "hp": 26, "atk": 10, "souls": 40}},
	{"id": 5, "type": "rest",   "pos": Vector2(422, 538),
	 "next": [7],
	 "enemy": {}},

	# ── L3 ─────────────────────────────────────────────
	{"id": 6, "type": "shop",   "pos": Vector2(592, 192),
	 "next": [8, 9],
	 "enemy": {}},
	{"id": 7, "type": "battle", "pos": Vector2(592, 460),
	 "next": [9, 10],
	 "enemy": {"name": "锁魂鬼差", "hp": 30, "atk": 11, "souls": 45}},

	# ── L4 三叉 ────────────────────────────────────────
	{"id": 8, "type": "elite",  "pos": Vector2(762, 128),
	 "next": [11],
	 "enemy": {"name": "阴司鬼将", "hp": 52, "atk": 14, "souls": 70}},
	{"id": 9, "type": "rest",   "pos": Vector2(762, 342),
	 "next": [11, 12],
	 "enemy": {}},
	{"id": 10, "type": "shop",  "pos": Vector2(762, 552),
	 "next": [12],
	 "enemy": {}},

	# ── L5 ─────────────────────────────────────────────
	{"id": 11, "type": "battle", "pos": Vector2(932, 195),
	 "next": [13],
	 "enemy": {"name": "幽冥武士", "hp": 36, "atk": 13, "souls": 55}},
	{"id": 12, "type": "battle", "pos": Vector2(932, 488),
	 "next": [13],
	 "enemy": {"name": "幽冥武士", "hp": 36, "atk": 13, "souls": 55}},

	# ── L6 Pre-Boss 必经休息 ───────────────────────────
	{"id": 13, "type": "rest",  "pos": Vector2(1078, 340),
	 "next": [14],
	 "enemy": {}},

	# ── L7 Boss ────────────────────────────────────────
	{"id": 14, "type": "boss",  "pos": Vector2(1198, 340),
	 "next": [],
	 "enemy": {"name": "黑无常", "hp": 104, "atk": 16, "souls": 0}},
]

# ══════════════════════════════════════════════════════
# 内部类：余烬动态背景
# ══════════════════════════════════════════════════════
class EmberBG extends Control:
	var _embers: Array = []
	var _t: float = 0.0

	func _init() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 20260523
		for i in 28:
			_embers.append({
				"pos":   Vector2(rng.randf_range(0, 1280), rng.randf_range(80, 620)),
				"r":     rng.randf_range(1.2, 3.8),
				"phase": rng.randf_range(0.0, TAU),
				"spd":   rng.randf_range(0.4, 1.8),
				"drift": rng.randf_range(-0.08, 0.08),   # 横向漂移
				"rise":  rng.randf_range(0.10, 0.28),    # 上升速度
				"hue":   rng.randf_range(0.0, 0.12),     # 色调偏移（红→橙）
			})

	func _process(delta: float) -> void:
		_t += delta
		# 让余烬缓慢上升
		for e in _embers:
			e.pos.y -= e.rise
			e.pos.x += e.drift * sin(_t * e.spd)
			if e.pos.y < 70:
				e.pos.y = 620.0
				e.pos.x = randf_range(0, 1280)
		queue_redraw()

	func _draw() -> void:
		for e in _embers:
			var alpha := (sin(_t * e.spd + e.phase) * 0.28 + 0.35)
			var col   := Color(
				0.72 + e.hue,
				0.18 + e.hue * 0.8,
				0.02,
				alpha * 0.55
			)
			draw_circle(e.pos, e.r, col)
			# 微光晕
			draw_circle(e.pos, e.r * 2.2,
				Color(col.r, col.g * 0.6, 0.0, alpha * 0.12))

# ══════════════════════════════════════════════════════
# 内部类：发光路径层
# ══════════════════════════════════════════════════════
class GlowPath extends Control:
	var _lines: Array = []

	func add_line(a: Vector2, b: Vector2) -> void:
		_lines.append([a, b])
		queue_redraw()

	func _draw() -> void:
		for l in _lines:
			var a: Vector2 = l[0]
			var b: Vector2 = l[1]
			# 层 1：厚暗底
			draw_line(a, b, Color(0.10, 0.06, 0.14, 0.65), 8.0)
			# 层 2：中间暖光
			draw_line(a, b, Color(0.58, 0.38, 0.16, 0.48), 3.6)
			# 层 3：亮芯
			draw_line(a, b, Color(0.90, 0.70, 0.32, 0.32), 1.4)
			# 中点菱形装饰
			var mid: Vector2 = (a + b) * 0.5
			draw_circle(mid, 3.8, Color(0.78, 0.58, 0.24, 0.55))
			draw_circle(mid, 5.5, Color(0.78, 0.58, 0.24, 0.18))

# ══════════════════════════════════════════════════════
# 内部类：六边形节点
# ══════════════════════════════════════════════════════
class HexNode extends Control:
	var bg_col: Color = Color.WHITE
	var accent: Color = Color.WHITE
	var tp: String    = "battle"

	# 状态
	var is_available: bool = false
	var is_visited:   bool = false
	var is_current:   bool = false

	var _pulse: float = 0.0

	# 六边形顶点（flat-top）
	static func hex_pts(center: Vector2, r: float) -> PackedVector2Array:
		var p := PackedVector2Array()
		for i in 6:
			var a := PI / 6.0 + i * (PI / 3.0)
			p.append(center + Vector2(cos(a), sin(a)) * r)
		return p

	func _process(delta: float) -> void:
		if is_available or is_current:
			_pulse += delta * PULSE_SPEED
			queue_redraw()

	func _draw() -> void:
		var c  := size / 2.0
		var r: float = min(size.x, size.y) * 0.46

		var bg := bg_col
		var ac := accent

		# 状态配色
		if is_visited:
			bg = bg_col.lerp(Color(0.06, 0.05, 0.08, 1.0), 0.68)
			ac = accent.lerp(Color(0.28, 0.26, 0.24, 1.0), 0.68)
		elif not is_available and not is_current:
			bg = bg_col.lerp(Color(0.04, 0.03, 0.05, 1.0), 0.85)
			ac = accent.lerp(Color(0.18, 0.16, 0.14, 1.0), 0.85)

		# ── 光晕 ──────────────────────────────────────
		if is_current:
			var g := 0.5 + 0.5 * sin(_pulse)
			draw_circle(c, r + 9.0 + g * 2.0,
				Color(0.98, 0.88, 0.32, 0.14 + g * 0.10))
			draw_circle(c, r + 4.0,
				Color(0.98, 0.88, 0.32, 0.22))
		elif is_available:
			var g := 0.5 + 0.5 * sin(_pulse)
			draw_circle(c, r + 6.0 + g * 3.0,
				ac * Color(1, 1, 1, 0.12 + g * 0.10))

		# ── 主六边形 ──────────────────────────────────
		var pts := hex_pts(c, r - 0.5)
		draw_colored_polygon(pts, bg)

		# ── 内部高光（顶部透明渐变感）─────────────────
		if is_available or is_current:
			var hi_pts := hex_pts(c - Vector2(0, r * 0.18), r * 0.52)
			draw_colored_polygon(hi_pts, ac * Color(1, 1, 1, 0.06))

		# ── 六边形边框 ────────────────────────────────
		var bw := 2.8 if (is_available or is_current) else 1.5
		var bc := ac if not (is_visited and not is_current) else ac.darkened(0.4)
		for i in 6:
			draw_line(pts[i], pts[(i + 1) % 6], bc, bw)

		# ── Boss 节点特殊：双层边框 ───────────────────
		if tp == "boss" and (is_available or is_current):
			var outer := hex_pts(c, r + 5.0)
			for i in 6:
				draw_line(outer[i], outer[(i + 1) % 6],
					ac * Color(1, 1, 1, 0.40), 1.2)

# ══════════════════════════════════════════════════════
# 场景变量
# ══════════════════════════════════════════════════════
var _ember_bg  : EmberBG
var _glow_path : GlowPath
var _hp_lbl    : Label
var _souls_lbl : Label
var _deck_lbl  : Label
var _node_hexes: Array = []   # HexNode 实例列表

# ══════════════════════════════════════════════════════
# 入口
# ══════════════════════════════════════════════════════
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_bg()
	_build_header()
	_build_paths()
	_build_nodes()
	_build_legend()
	_build_hud()
	_refresh_nodes()

# ══════════════════════════════════════════════════════
# 背景：暗色渐变 + 余烬粒子
# ══════════════════════════════════════════════════════
func _build_bg() -> void:
	# 纯黑底层
	var solid := ColorRect.new()
	solid.color = Color(0.038, 0.026, 0.050)
	solid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	solid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(solid)

	# 余烬动画层
	_ember_bg = EmberBG.new()
	_ember_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ember_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ember_bg)

	# 上边渐变（遮盖溢出余烬）
	var top_grad := ColorRect.new()
	top_grad.color = Color(0.038, 0.026, 0.050, 0.92)
	top_grad.size = Vector2(1280, 68)
	top_grad.position = Vector2(0, 0)
	top_grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_grad)

	# 底边渐变
	var bot_grad := ColorRect.new()
	bot_grad.color = Color(0.038, 0.026, 0.050, 0.92)
	bot_grad.size = Vector2(1280, 80)
	bot_grad.position = Vector2(0, 640)
	bot_grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bot_grad)

# ══════════════════════════════════════════════════════
# 顶部标题栏
# ══════════════════════════════════════════════════════
func _build_header() -> void:
	# 装饰横线
	var line_bg := ColorRect.new()
	line_bg.color = Color(0.28, 0.18, 0.06, 0.5)
	line_bg.size = Vector2(1280, 62)
	line_bg.position = Vector2(0, 0)
	line_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line_bg)

	var title := Label.new()
	title.text = LAYER_NAME
	title.position = Vector2(0, 12)
	title.size = Vector2(1280, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.96, 0.62, 0.20))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	# 分割线（双线）
	var sep1 := ColorRect.new()
	sep1.color = Color(0.55, 0.38, 0.10, 0.60)
	sep1.size = Vector2(1280, 2)
	sep1.position = Vector2(0, 60)
	sep1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep1)

	var sep2 := ColorRect.new()
	sep2.color = Color(0.30, 0.20, 0.06, 0.35)
	sep2.size = Vector2(1280, 1)
	sep2.position = Vector2(0, 64)
	sep2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep2)

# ══════════════════════════════════════════════════════
# 发光路径
# ══════════════════════════════════════════════════════
func _build_paths() -> void:
	_glow_path = GlowPath.new()
	_glow_path.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glow_path.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glow_path)

	for nd: Dictionary in NODES:
		for nxt_id: int in nd.next:
			_glow_path.add_line(nd.pos, NODES[nxt_id].pos)

# ══════════════════════════════════════════════════════
# 六边形节点
# ══════════════════════════════════════════════════════
func _build_nodes() -> void:
	_node_hexes.clear()
	for nd: Dictionary in NODES:
		_node_hexes.append(_make_hex(nd))

func _make_hex(nd: Dictionary) -> HexNode:
	var tp:  String  = nd.type
	var pos: Vector2 = nd.pos
	var sz  := NODE_R * 2.3   # 包含光晕的控件尺寸

	var hex := HexNode.new()
	hex.bg_col = TYPE_BG[tp]
	hex.accent = TYPE_ACCENT[tp]
	hex.tp     = tp
	hex.size   = Vector2(sz, sz)
	hex.position = pos - Vector2(sz * 0.5, sz * 0.5)
	hex.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(hex)

	# 图标文字
	var icon := Label.new()
	icon.text = TYPE_ICON[tp]
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 22)
	icon.add_theme_color_override("font_color", TYPE_ACCENT[tp])
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hex.add_child(icon)

	# 名字标签（节点正下方）
	var name_lbl := Label.new()
	name_lbl.position = Vector2(-22, sz + 1)
	name_lbl.size     = Vector2(sz + 44, 18)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.50))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var enemy: Dictionary = nd.get("enemy", {})
	if enemy.size() > 0:
		name_lbl.text = enemy.get("name", "")
	else:
		name_lbl.text = TYPE_NAME.get(tp, "")
	hex.add_child(name_lbl)

	# 点击
	var node_id: int = nd.id
	hex.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
				_on_node_clicked(node_id)
	)

	return hex

# ══════════════════════════════════════════════════════
# 图例（底部）
# ══════════════════════════════════════════════════════
func _build_legend() -> void:
	var legend_bg := ColorRect.new()
	legend_bg.color = Color(0.06, 0.04, 0.08, 0.85)
	legend_bg.size = Vector2(1280, 58)
	legend_bg.position = Vector2(0, 662)
	legend_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(legend_bg)

	var leg_sep := ColorRect.new()
	leg_sep.color = Color(0.35, 0.22, 0.06, 0.50)
	leg_sep.size = Vector2(1280, 1)
	leg_sep.position = Vector2(0, 662)
	leg_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(leg_sep)

	var types  := ["battle", "elite", "shop", "rest", "boss"]
	var labels := ["普通战斗", "精英", "黄泉客栈", "望乡台", "无间狱主"]
	var total_w := types.size() * 160
	var sx := (1280 - total_w) / 2.0

	for i in types.size():
		var tp: String = types[i]
		var ac: Color  = TYPE_ACCENT[tp]
		var ox: float  = sx + i * 160

		# 小六边形图示
		var dot_ctrl := Control.new()
		dot_ctrl.size = Vector2(18, 18)
		dot_ctrl.position = Vector2(ox, 671)
		dot_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dc := dot_ctrl  # closure capture
		dot_ctrl.draw.connect(func():
			var pts := HexNode.hex_pts(Vector2(9, 9), 8.0)
			dc.draw_colored_polygon(pts, TYPE_BG[tp])
			for j in 6:
				dc.draw_line(pts[j], pts[(j+1)%6], ac, 1.5)
		)
		add_child(dot_ctrl)
		dot_ctrl.queue_redraw()

		var lbl := Label.new()
		lbl.text = labels[i]
		lbl.position = Vector2(ox + 22, 670)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.48))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl)

# ══════════════════════════════════════════════════════
# HUD（左上角 HP / 魂魄 / 牌组）
# ══════════════════════════════════════════════════════
func _build_hud() -> void:
	var hud_bg := ColorRect.new()
	hud_bg.color = Color(0.06, 0.04, 0.08, 0.82)
	hud_bg.size = Vector2(180, 58)
	hud_bg.position = Vector2(8, 4)
	hud_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_bg)

	var hud_border := ReferenceRect.new()
	hud_border.border_color = Color(0.35, 0.25, 0.08, 0.6)
	hud_border.border_width = 1.0
	hud_border.editor_only = false
	hud_border.size = Vector2(180, 58)
	hud_border.position = Vector2(8, 4)
	hud_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_border)

	_hp_lbl = Label.new()
	_hp_lbl.position = Vector2(16, 10)
	_hp_lbl.add_theme_font_size_override("font_size", 14)
	_hp_lbl.add_theme_color_override("font_color", Color(0.38, 0.92, 0.50))
	_hp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hp_lbl)

	_souls_lbl = Label.new()
	_souls_lbl.position = Vector2(16, 28)
	_souls_lbl.add_theme_font_size_override("font_size", 14)
	_souls_lbl.add_theme_color_override("font_color", Color(0.96, 0.82, 0.28))
	_souls_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_souls_lbl)

	_deck_lbl = Label.new()
	_deck_lbl.position = Vector2(16, 46)
	_deck_lbl.add_theme_font_size_override("font_size", 11)
	_deck_lbl.add_theme_color_override("font_color", Color(0.55, 0.50, 0.62))
	_deck_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_deck_lbl)

# ══════════════════════════════════════════════════════
# 节点状态刷新
# ══════════════════════════════════════════════════════
func _refresh_nodes() -> void:
	_hp_lbl.text    = "❤  %d / %d" % [Global.player_hp, Global.player_max_hp]
	_souls_lbl.text = "◈  魂魄 %d" % Global.player_souls

	var deck_names := {"fire":"火焰系","bone":"白骨系","blood":"血煞系",
						"ghost":"幽魂系","cycle":"轮回系"}
	_deck_lbl.text = "牌组：" + deck_names.get(Global.selected_deck, "未知")

	for i in NODES.size():
		var hex: HexNode   = _node_hexes[i]
		var nd:  Dictionary = NODES[i]
		var avail:   bool  = _is_available(nd.id)
		var visited: bool  = nd.id in Global.visited_nodes
		var current: bool  = nd.id == Global.current_node_id

		hex.is_available = avail and not visited
		hex.is_visited   = visited
		hex.is_current   = current

		if visited:
			hex.modulate = Color(1, 1, 1, 0.65)
			hex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif avail:
			hex.modulate = Color.WHITE
			hex.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			hex.modulate = Color(1, 1, 1, 1)
			hex.mouse_filter = Control.MOUSE_FILTER_IGNORE

		hex.queue_redraw()

func _is_available(node_id: int) -> bool:
	if Global.current_node_id == -1:
		return node_id == 0
	if Global.current_node_id < 0 or Global.current_node_id >= NODES.size():
		return false
	var cur: Dictionary = NODES[Global.current_node_id]
	return (node_id in cur.next) and not (node_id in Global.visited_nodes)

# ══════════════════════════════════════════════════════
# 点击处理
# ══════════════════════════════════════════════════════
func _on_node_clicked(node_id: int) -> void:
	if not _is_available(node_id): return

	var nd: Dictionary = NODES[node_id]
	Global.current_node_id = node_id
	Global.visited_nodes.append(node_id)

	match nd.type:
		"battle", "elite":
			var e: Dictionary = nd.enemy
			Global.enemy_name         = e.get("name", "未知")
			Global.enemy_max_hp       = e.get("hp",   50)
			Global.enemy_atk          = e.get("atk",  8)
			Global.enemy_souls_reward = e.get("souls", 0)
			Global.current_node_type  = nd.type
			_fade_to("res://Scenes/Battle/BattleScene.tscn")
		"boss":
			var e: Dictionary = nd.enemy
			Global.enemy_name         = e.get("name", "黑无常")
			Global.enemy_max_hp       = e.get("hp",   104)
			Global.enemy_atk          = e.get("atk",  16)
			Global.enemy_souls_reward = e.get("souls", 0)
			Global.current_node_type  = nd.type
			_fade_to("res://Scenes/BossIntro/BossIntroScene.tscn")
		"shop":
			_fade_to("res://Scenes/Shop/ShopScene.tscn")
		"rest":
			_fade_to("res://Scenes/Rest/RestScene.tscn")

func _fade_to(path: String) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var tw := create_tween()
	tw.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.28)
	tw.tween_callback(func(): get_tree().change_scene_to_file(path))
