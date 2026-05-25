extends Control

# 卡组由角色选择界面通过 Global.selected_deck 传入

# ══════════════════════════════════════════════════════
# 常量
# ══════════════════════════════════════════════════════
const CARD_W        := 118
const CARD_H        := 168
const CARD_SPACING  := 133
const HAND_Y        := 535.0
const SCREEN_W      := 1280.0
const PLAY_Y        := 490.0

# ══════════════════════════════════════════════════════
# 战斗状态
# ══════════════════════════════════════════════════════
enum State { PLAYER_TURN, ENEMY_TURN, WIN, LOSE }
var _state: State = State.PLAYER_TURN

# ── 玩家数据（从 Global 读取）─────────────────────────
var p_max_hp     := 80
var p_hp         := 80
var p_block      := 0
var p_energy     := 3
var p_max_energy := 3   # 3 + Global.bonus_energy

# ── 状态效果（玩家）───────────────────────────────────
var p_bone_spikes := 0   # 骨刺：每层受伤时反弹1点伤害，持续到战斗结束
var p_strength    := 0   # 攻击加成（献血强化积累）

# ── 敌人数据（从 Global 读取）─────────────────────────
var e_max_hp     := 52
var e_hp         := 52
var e_block      := 0
var e_intent_dmg := 8
var _e_name      := "刀锯鬼卒"

# ── 状态效果（敌人）───────────────────────────────────
var e_burn       := 0   # 燃烧：回合结束造成等量伤害，不自动减少
var e_vulnerable := 0   # 易伤：受到伤害×1.5，每回合-1

# ── 能力标志 ──────────────────────────────────────────
var pow_lava_enchant := false  # 熔岩护甲：受伤时对敌+1燃烧
var pow_bone_forest  := false  # 森罗骨阵：每回合开始获得[回合数]层骨刺
var pow_blood_flesh  := false  # 血肉苦弱：主动失血时对敌造成等量伤害
var pow_void_shadow  := false  # 虚空阴影：每回合开始对敌+1易伤
var pow_biangan      := false  # 彼岸花开：每张被弃怨灵缠身→下回合抽1牌

# ── 计数器 ────────────────────────────────────────────
var turn_number   := 0   # 当前回合数
var turn_cards    := 0   # 本回合已打出牌数
var biangan_done  := 0   # 上回合弃置的怨灵缠身数（用于彼岸花开）

# ── 特殊状态 ──────────────────────────────────────────
var deathwish_hp  := -1  # 向死而生待触发格挡（-1=无效）

# ══════════════════════════════════════════════════════
# 黑无常 Boss 系统
# ══════════════════════════════════════════════════════
var _boss_ai       : BossAIController = null
var _boss_draw     : Array = []   # Boss抽牌堆
var _boss_hand     : Array = []   # Boss手牌（3张）
var _boss_discard  : Array = []   # Boss弃牌堆
var _boss_atk_boost: bool  = false  # 阴司令：下次攻击+50%
var _boss_per_turn_block: int = 0   # 无常显形：每回合获得格挡
var _player_energy_debuff: bool = false  # 能量封印效果
var _boss_last_card: String = ""    # 上次出的牌ID（显示用）
var _waiting_for_click: bool = false  # 等待玩家点击继续

signal _click_done  # 玩家点击后触发

# ── 嘲讽系统 ──────────────────────────────────────────
var _taunt_system : BossTauntSystem = null
var _taunt_counter: int  = 0        # 本回合累计
var _taunt_next   : int  = 2        # 下次触发所需回合数
var _taunt_bubble : Control = null  # 当前气泡节点
var _player_last_card_name: String = ""  # 玩家上一张出的牌名

# ══════════════════════════════════════════════════════
# 牌库
# ══════════════════════════════════════════════════════
var _draw_pile : Array = []
var _hand      : Array = []
var _discard   : Array = []
var _hand_nodes: Array = []

# ══════════════════════════════════════════════════════
# UI 节点引用
# ══════════════════════════════════════════════════════
var _p_hp_bar      : ProgressBar
var _p_hp_lbl      : Label
var _p_block_lbl   : Label
var _p_name_lbl    : Label
var _e_name_lbl    : Label
var _e_hp_bar      : ProgressBar
var _e_hp_lbl      : Label
var _e_block_lbl   : Label
var _e_intent_lbl  : Label
var _energy_lbl    : Label
var _draw_lbl      : Label
var _discard_lbl   : Label
var _end_turn_btn  : Button
var _log_lbl       : Label
var _powers_lbl    : Label
var _hand_root     : Control
var _result_overlay: Control
var _player_emblem:  TextureRect
var _enemy_emblem:   TextureRect

# ══════════════════════════════════════════════════════
# 入口
# ══════════════════════════════════════════════════════
const _CHAR_NAMES := {
	"fire":  "炎魂",
	"bone":  "骨灵",
	"blood": "血魔",
	"ghost": "幽魄",
	"cycle": "轮回者",
}

func _ready() -> void:
	# 从 Global 载入敌人数据
	if Global.enemy_max_hp > 0:
		e_max_hp     = Global.enemy_max_hp
		e_hp         = Global.enemy_max_hp
		e_intent_dmg = Global.enemy_atk
		_e_name      = Global.enemy_name
	# 从 Global 载入玩家数据
	p_max_hp     = Global.player_max_hp
	p_hp         = Global.player_hp
	p_max_energy = 3 + Global.bonus_energy

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	if is_instance_valid(_p_name_lbl):
		_p_name_lbl.text = _CHAR_NAMES.get(Global.selected_deck, "亡魂")
	if is_instance_valid(_e_name_lbl):
		_e_name_lbl.text = _e_name
	# 初始化 Boss AI 系统
	if _is_boss_fight():
		_e_name = "黑无常"
		if is_instance_valid(_e_name_lbl):
			_e_name_lbl.text = "黑无常"
		_boss_ai = BossAIController.new()
		add_child(_boss_ai)
		_boss_ai.card_decided.connect(_on_boss_card_decided)
		_init_boss_deck()
		# 嘲讽系统
		_taunt_system = BossTauntSystem.new()
		add_child(_taunt_system)
		_taunt_system.taunt_ready.connect(_on_taunt_ready)
		_taunt_next = randi_range(2, 3)
	_init_deck()
	_start_player_turn()

# ══════════════════════════════════════════════════════
# 构建 UI
# ══════════════════════════════════════════════════════
func _build_ui() -> void:
	_add_bg()
	_add_faction_emblem()   # 左侧玩家大立绘
	_add_enemy_emblem()     # 右侧敌人大立绘
	_add_play_hint()
	_add_enemy_zone()
	_add_player_zone()
	_add_energy_zone()
	_add_pile_zone()
	_add_end_turn_btn()
	_add_log()
	_add_hand_root()
	_add_result_overlay()

func _add_bg() -> void:
	# Boss战背景图（铺满全屏）
	var bg := TextureRect.new()
	bg.expand = true
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.set_deferred("size", Vector2(1280, 720))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := load("res://picture/场景图/boss_scene.png")
	if tex:
		bg.texture = tex
	add_child(bg)

	# 半透明深色遮罩（让背景不那么刺眼）
	var overlay := ColorRect.new()
	overlay.color = Color(0.09, 0.07, 0.06, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

# ══════════════════════════════════════════════════════
# 左侧玩家大立绘（300x400）
# ══════════════════════════════════════════════════════
func _add_faction_emblem() -> void:
	var img_map := {
		"fire":  "res://picture/Heroes/主角/狱火流.png",
		"bone":  "res://picture/Heroes/主角/白骨流.png",
		"blood": "res://picture/Heroes/主角/血煞流.png",
		"ghost": "res://picture/Heroes/主角/幽魂流.png",
		"cycle": "res://picture/Heroes/主角/轮回流.png",
	}
	var deck: String = Global.selected_deck
	var img_path: String = img_map.get(deck, "")

	var container := Control.new()
	container.position = Vector2(0, 0)
	container.size = Vector2(320, 720)
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(container)

	# 立牌图片
	var emblem := TextureRect.new()
	emblem.expand = true
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	emblem.custom_minimum_size = Vector2(380, 500)
	emblem.size = Vector2(380, 500)
	emblem.position = Vector2(-30, 130)
	if not img_path.is_empty():
		var tex := load(img_path)
		if tex:
			emblem.texture = tex
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(emblem)
	_player_emblem = emblem

	# 左右边缘暗色渐变遮罩
	var left_gradient := ColorRect.new()
	left_gradient.color = Color(0.09, 0.07, 0.06, 0.0)
	left_gradient.size = Vector2(60, 720)
	left_gradient.position = Vector2(0, 0)
	left_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(left_gradient)

	var right_gradient := ColorRect.new()
	right_gradient.color = Color(0.09, 0.07, 0.06, 0.0)
	right_gradient.size = Vector2(80, 720)
	right_gradient.position = Vector2(240, 0)
	right_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(right_gradient)

	# 底部暗色渐变（透明）
	var bottom_fade := ColorRect.new()
	bottom_fade.color = Color(0.09, 0.07, 0.06, 0.0)
	bottom_fade.size = Vector2(320, 120)
	bottom_fade.position = Vector2(0, 600)
	bottom_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bottom_fade)

# ══════════════════════════════════════════════════════
# 右侧敌人大立绘（300x400）
# ══════════════════════════════════════════════════════
func _add_enemy_emblem() -> void:
	var node_type: String = Global.current_node_type
	var img_path: String = ""

	if node_type == "boss":
		img_path = "res://picture/Heroes/怪物/黑无常.png"
	elif node_type == "elite":
		img_path = "res://picture/Heroes/怪物/精英怪.png"
	else:
		img_path = "res://picture/Heroes/怪物/小怪1.png" if randi() % 2 == 0 else "res://picture/Heroes/怪物/小怪2.png"

	var container := Control.new()
	container.position = Vector2(960, 0)
	container.size = Vector2(320, 720)
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(container)

	# 立牌图片
	var emblem := TextureRect.new()
	emblem.expand = true
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	emblem.custom_minimum_size = Vector2(380, 500)
	emblem.size = Vector2(380, 500)
	emblem.position = Vector2(-30, 130)
	if not img_path.is_empty():
		var tex := load(img_path)
		if tex:
			emblem.texture = tex
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(emblem)
	_enemy_emblem = emblem

	# 左侧边缘暗色渐变遮罩
	var left_gradient := ColorRect.new()
	left_gradient.color = Color(0.09, 0.07, 0.06, 0.0)
	left_gradient.size = Vector2(60, 720)
	left_gradient.position = Vector2(0, 0)
	left_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(left_gradient)

	# 底部暗色渐变（透明）
	var bottom_fade := ColorRect.new()
	bottom_fade.color = Color(0.09, 0.07, 0.06, 0.0)
	bottom_fade.size = Vector2(320, 100)
	bottom_fade.position = Vector2(0, 620)
	bottom_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bottom_fade)

func _add_play_hint() -> void:
	var line := ColorRect.new()
	line.color = Color(0.4, 0.35, 0.2, 0.25)
	line.size = Vector2(SCREEN_W, 2)
	line.position = Vector2(0, PLAY_Y)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)
	var hint := Label.new()
	hint.text = "── 拖到此线以上出牌 ──"
	hint.size = Vector2(300, 24)
	hint.position = Vector2(490, PLAY_Y - 22)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.5, 0.45, 0.3))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)

func _add_enemy_zone() -> void:
	# 敌人信息区域放在右侧大立绘下方
	var z := Control.new()
	z.position = Vector2(960, 500)
	z.size = Vector2(320, 220)
	z.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(z)

	_e_name_lbl = Label.new()
	_e_name_lbl.size = Vector2(300, 30)
	_e_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_e_name_lbl.add_theme_font_size_override("font_size", 17)
	_e_name_lbl.add_theme_color_override("font_color", Color(0.95, 0.55, 0.28))
	_e_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	z.add_child(_e_name_lbl)

	_e_block_lbl = Label.new()
	_e_block_lbl.position = Vector2(0, 8)
	_e_block_lbl.add_theme_font_size_override("font_size", 13)
	_e_block_lbl.add_theme_color_override("font_color", Color(0.5, 0.72, 0.95))
	_e_block_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	z.add_child(_e_block_lbl)

	_e_hp_bar = ProgressBar.new()
	_e_hp_bar.max_value = e_max_hp
	_e_hp_bar.value = e_hp
	_e_hp_bar.size = Vector2(280, 22)
	_e_hp_bar.position = Vector2(0, 60)
	_e_hp_bar.show_percentage = false
	z.add_child(_e_hp_bar)

	_e_hp_lbl = Label.new()
	_e_hp_lbl.size = Vector2(280, 28)
	_e_hp_lbl.position = Vector2(0, 85)
	_e_hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_e_hp_lbl.add_theme_font_size_override("font_size", 13)
	z.add_child(_e_hp_lbl)

	_e_intent_lbl = Label.new()
	_e_intent_lbl.size = Vector2(300, 48)
	_e_intent_lbl.position = Vector2(0, 120)
	_e_intent_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_e_intent_lbl.add_theme_font_size_override("font_size", 12)
	_e_intent_lbl.add_theme_color_override("font_color", Color(0.92, 0.40, 0.38))
	_e_intent_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	z.add_child(_e_intent_lbl)

func _add_player_zone() -> void:
	# 玩家信息区域放在左侧大立绘下方
	var z := Control.new()
	z.position = Vector2(40, 500)
	z.size = Vector2(320, 220)
	z.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(z)

	_p_name_lbl = Label.new()
	_p_name_lbl.text = "亡魂"
	_p_name_lbl.size = Vector2(200, 30)
	_p_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p_name_lbl.add_theme_font_size_override("font_size", 15)
	_p_name_lbl.add_theme_color_override("font_color", Color(0.48, 0.80, 0.92))
	_p_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	z.add_child(_p_name_lbl)

	_p_hp_bar = ProgressBar.new()
	_p_hp_bar.max_value = p_max_hp
	_p_hp_bar.value = p_hp
	_p_hp_bar.size = Vector2(200, 22)
	_p_hp_bar.position = Vector2(0, 40)
	_p_hp_bar.show_percentage = false
	z.add_child(_p_hp_bar)

	_p_hp_lbl = Label.new()
	_p_hp_lbl.size = Vector2(200, 28)
	_p_hp_lbl.position = Vector2(0, 65)
	_p_hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p_hp_lbl.add_theme_font_size_override("font_size", 13)
	z.add_child(_p_hp_lbl)

	_p_block_lbl = Label.new()
	_p_block_lbl.position = Vector2(0, 100)
	_p_block_lbl.size = Vector2(240, 40)
	_p_block_lbl.add_theme_font_size_override("font_size", 12)
	_p_block_lbl.add_theme_color_override("font_color", Color(0.48, 0.72, 0.95))
	_p_block_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	z.add_child(_p_block_lbl)

	_p_block_lbl = Label.new()
	_p_block_lbl.position = Vector2(0, 70)
	_p_block_lbl.size = Vector2(240, 40)
	_p_block_lbl.add_theme_font_size_override("font_size", 12)
	_p_block_lbl.add_theme_color_override("font_color", Color(0.48, 0.72, 0.95))
	_p_block_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	z.add_child(_p_block_lbl)

func _add_energy_zone() -> void:
	var z := Control.new()
	z.position = Vector2(40, 620)
	z.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(z)
	var title := Label.new()
	title.text = "能量"
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	z.add_child(title)
	_energy_lbl = Label.new()
	_energy_lbl.position = Vector2(0, 16)
	_energy_lbl.add_theme_font_size_override("font_size", 30)
	_energy_lbl.add_theme_color_override("font_color", Color(0.95, 0.72, 0.12))
	_energy_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	z.add_child(_energy_lbl)

func _add_pile_zone() -> void:
	# 锦囊背景图
	var pouch_bg := TextureRect.new()
	pouch_bg.expand = true
	pouch_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	pouch_bg.position = Vector2(16, 55)
	pouch_bg.size = Vector2(130, 90)
	pouch_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := load("res://picture/场景图/pouch_ui.png")
	if tex:
		pouch_bg.texture = tex
	add_child(pouch_bg)

	# 牌堆信息框（储物袋右侧独立小方框）
	var info_box := Panel.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.04, 0.08, 0.90)
	ps.border_color = Color(0.50, 0.38, 0.22, 0.55)
	ps.set_border_width_all(1)
	for prop in ["corner_radius_top_left","corner_radius_top_right",
				 "corner_radius_bottom_left","corner_radius_bottom_right"]:
		ps.set(prop, 6)
	info_box.add_theme_stylebox_override("panel", ps)
	info_box.position = Vector2(155, 60)
	info_box.size = Vector2(110, 78)
	info_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info_box)

	_draw_lbl = Label.new()
	_draw_lbl.text = "牌堆：10"
	_draw_lbl.size = Vector2(96, 26)
	_draw_lbl.position = Vector2(7, 8)
	_draw_lbl.add_theme_font_size_override("font_size", 14)
	_draw_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.45))
	_draw_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_box.add_child(_draw_lbl)

	_discard_lbl = Label.new()
	_discard_lbl.text = "弃牌：0"
	_discard_lbl.size = Vector2(96, 26)
	_discard_lbl.position = Vector2(7, 44)
	_discard_lbl.add_theme_font_size_override("font_size", 14)
	_discard_lbl.add_theme_color_override("font_color", Color(0.45, 0.85, 1.0))
	_discard_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_box.add_child(_discard_lbl)

func _add_end_turn_btn() -> void:
	_end_turn_btn = Button.new()
	_end_turn_btn.text = "结束\n回合"
	_end_turn_btn.size = Vector2(110, 55)
	_end_turn_btn.position = Vector2(1145, 450)

	# 使用与游戏风格一致的深色边框样式
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.12, 0.05, 0.03)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color(0.68, 0.42, 0.12)
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6
	normal_style.content_margin_left = 8
	normal_style.content_margin_right = 8
	normal_style.content_margin_top = 6
	normal_style.content_margin_bottom = 6

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.18, 0.08, 0.05)
	hover_style.border_width_left = 2
	hover_style.border_width_top = 2
	hover_style.border_width_right = 2
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color(0.96, 0.62, 0.22)
	hover_style.corner_radius_top_left = 6
	hover_style.corner_radius_top_right = 6
	hover_style.corner_radius_bottom_left = 6
	hover_style.corner_radius_bottom_right = 6
	hover_style.content_margin_left = 8
	hover_style.content_margin_right = 8
	hover_style.content_margin_top = 6
	hover_style.content_margin_bottom = 6

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.08, 0.03, 0.02)
	pressed_style.border_width_left = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_bottom = 2
	pressed_style.border_color = Color(0.80, 0.50, 0.15)
	pressed_style.corner_radius_top_left = 6
	pressed_style.corner_radius_top_right = 6
	pressed_style.corner_radius_bottom_left = 6
	pressed_style.corner_radius_bottom_right = 6
	pressed_style.content_margin_left = 8
	pressed_style.content_margin_right = 8
	pressed_style.content_margin_top = 6
	pressed_style.content_margin_bottom = 6

	_end_turn_btn.add_theme_stylebox_override("normal", normal_style)
	_end_turn_btn.add_theme_stylebox_override("hover", hover_style)
	_end_turn_btn.add_theme_stylebox_override("pressed", pressed_style)

	# 按钮文字配色
	_end_turn_btn.add_theme_color_override("font_color", Color(0.92, 0.58, 0.18))
	_end_turn_btn.add_theme_font_size_override("font_size", 14)

	_end_turn_btn.pressed.connect(_on_end_turn)
	add_child(_end_turn_btn)

func _add_log() -> void:
	# 回合日志（屏幕正中间上方）
	_log_lbl = Label.new()
	_log_lbl.position = Vector2(240, 6)
	_log_lbl.size = Vector2(800, 28)
	_log_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_log_lbl.add_theme_font_size_override("font_size", 13)
	_log_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.72))
	_log_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_log_lbl.add_theme_constant_override("outline_size", 2)
	_log_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_log_lbl)

	# 能力栏（日志下方居中）
	_powers_lbl = Label.new()
	_powers_lbl.position = Vector2(290, 32)
	_powers_lbl.size = Vector2(700, 22)
	_powers_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_powers_lbl.add_theme_font_size_override("font_size", 11)
	_powers_lbl.add_theme_color_override("font_color", Color(0.65, 0.82, 0.55))
	_powers_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_powers_lbl.add_theme_constant_override("outline_size", 2)
	_powers_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_powers_lbl)

func _add_hand_root() -> void:
	_hand_root = Control.new()
	_hand_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hand_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hand_root)

func _add_result_overlay() -> void:
	_result_overlay = Control.new()
	_result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_overlay.visible = false
	add_child(_result_overlay)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.78)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_overlay.add_child(bg)

	var lbl := Label.new()
	lbl.name = "ResultLabel"
	lbl.size = Vector2(500, 100)
	lbl.position = Vector2(390, 250)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 62)
	_result_overlay.add_child(lbl)

	# 通关/Boss时显示"继续"，战败时显示"重新开始"
	var btn := Button.new()
	btn.name = "MainBtn"
	btn.text = "重新开始"
	btn.size = Vector2(160, 50)
	btn.position = Vector2(480, 390)
	btn.pressed.connect(_back_to_select)
	_result_overlay.add_child(btn)

	var back_btn := Button.new()
	back_btn.text = "换个角色"
	back_btn.size = Vector2(160, 50)
	back_btn.position = Vector2(652, 390)
	back_btn.pressed.connect(_back_to_select)
	_result_overlay.add_child(back_btn)

# ══════════════════════════════════════════════════════
# 战斗动画与特效
# ══════════════════════════════════════════════════════

# 攻击方前冲动画（direction>0向右冲，<0向左冲）
func _anim_attack_forward(emblem: TextureRect, direction: float) -> void:
	if not is_instance_valid(emblem): return
	var orig_x := emblem.position.x
	var tw := create_tween()
	tw.tween_property(emblem, "position:x", orig_x + direction, 0.09).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(emblem, "position:x", orig_x, 0.20).set_ease(Tween.EASE_IN)

# 受击晃动动画
func _anim_hit_shake(emblem: TextureRect) -> void:
	if not is_instance_valid(emblem): return
	var orig_x := emblem.position.x
	var tw := create_tween()
	tw.tween_property(emblem, "position:x", orig_x + 12, 0.03)
	tw.tween_property(emblem, "position:x", orig_x - 12, 0.04)
	tw.tween_property(emblem, "position:x", orig_x + 7,  0.04)
	tw.tween_property(emblem, "position:x", orig_x - 5,  0.03)
	tw.tween_property(emblem, "position:x", orig_x,      0.04)

# 全屏颜色闪光（燃烧/格挡/骨刺/失血/易伤等视觉反馈）
func _vfx_flash(col: Color) -> void:
	var flash := ColorRect.new()
	flash.color = col
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.35)
	tw.tween_callback(flash.queue_free)

# 爪痕特效（击打瞬间出现三道斜线）
func _vfx_claw_mark(target: TextureRect) -> void:
	if not is_instance_valid(target): return
	var center := target.global_position + target.size * 0.5
	var marks := Control.new()
	marks.global_position = center - Vector2(25, 40)
	marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(marks)
	var claw_col := Color(0.95, 0.18, 0.12, 0.9)
	for i in 3:
		var line := Line2D.new()
		var ox := (i - 1) * 18.0
		line.points = PackedVector2Array([
			Vector2(ox - 18, -35),
			Vector2(ox + 18, 35),
		])
		line.width = 3.5
		line.default_color = claw_col
		marks.add_child(line)
	# 弹入缩放 + 淡出
	marks.scale = Vector2(1.6, 1.6)
	var tw := create_tween()
	tw.tween_property(marks, "scale", Vector2(1.0, 1.0), 0.07).set_ease(Tween.EASE_OUT)
	tw.tween_property(marks, "modulate:a", 0.0, 0.35).set_delay(0.06)
	tw.tween_callback(marks.queue_free)

# ══════════════════════════════════════════════════════
# 牌库管理
# ══════════════════════════════════════════════════════
func _init_deck() -> void:
	_draw_pile.clear(); _hand.clear(); _discard.clear()
	for n in _hand_nodes:
		if is_instance_valid(n): n.queue_free()
	_hand_nodes.clear()
	# 每场战斗从 Global.current_deck 复制一份，不影响原牌组
	_draw_pile = Global.current_deck.duplicate()
	_draw_pile.shuffle()
	_update_piles()

func _draw_cards(n: int) -> void:
	for i in n:
		if _draw_pile.is_empty():
			if _discard.is_empty(): break
			_draw_pile = _discard.duplicate()
			_discard.clear()
			_draw_pile.shuffle()
			_log("洗牌！弃牌堆重新混入牌堆。")
		if _draw_pile.is_empty(): break
		_hand.append(_draw_pile.pop_back())
	_rebuild_hand()
	_update_piles()

func _discard_hand() -> void:
	# 计算本回合弃置的怨灵缠身数（用于下回合彼岸花开）
	biangan_done = 0
	for card in _hand:
		if card.effect_id == "yuan_ling_chan_shen":
			e_vulnerable += 2
			biangan_done += 1
	_discard.append_array(_hand)
	_hand.clear()
	for n in _hand_nodes:
		if is_instance_valid(n): n.queue_free()
	_hand_nodes.clear()
	_update_piles()

func _remove_card_from_hand(card: CardData, node: CardUI) -> void:
	var i := _hand.find(card)
	if i >= 0: _hand.remove_at(i)
	if not card.exhaust:
		_discard.append(card)
	var j := _hand_nodes.find(node)
	if j >= 0: _hand_nodes.remove_at(j)
	node.queue_free()
	_reposition_hand()
	_update_piles()

# ══════════════════════════════════════════════════════
# 手牌显示
# ══════════════════════════════════════════════════════
func _rebuild_hand() -> void:
	for n in _hand_nodes:
		if is_instance_valid(n): n.queue_free()
	_hand_nodes.clear()
	for card in _hand:
		var node := CardUI.new()
		node.setup(card)
		node.card_released.connect(_on_card_released)
		_hand_root.add_child(node)
		_hand_nodes.append(node)
	_reposition_hand()
	_refresh_playable()

func _reposition_hand() -> void:
	var cnt := _hand_nodes.size()
	if cnt == 0: return
	var total_w := (cnt - 1) * CARD_SPACING + CARD_W
	var sx := (SCREEN_W - total_w) / 2.0
	for i in cnt:
		var nd = _hand_nodes[i]
		if not is_instance_valid(nd): continue
		var p := Vector2(sx + i * CARD_SPACING, HAND_Y)
		nd.home_position = p
		if not nd.is_dragging():
			var t := (nd as Node).create_tween()
			t.tween_property(nd, "position", p, 0.15).set_ease(Tween.EASE_OUT)

func _refresh_playable() -> void:
	var ok := _state == State.PLAYER_TURN
	for nd in _hand_nodes:
		if not is_instance_valid(nd): continue
		var card: CardData = nd.card_data
		if card.unplayable:
			nd.set_playable(false)
		else:
			nd.set_playable(ok and _get_effective_cost(card) <= p_energy)

func _get_effective_cost(card: CardData) -> int:
	if card.is_x_cost:
		return 0  # X费：总是"可付" ，实际消耗全部能量
	return card.cost

# ══════════════════════════════════════════════════════
# 伤害辅助函数
# ══════════════════════════════════════════════════════
# 对敌人造成伤害，返回实际伤害量
# is_direct=true 时跳过格挡（如燃烧转化、骨刺反弹）
func _deal_damage_to_enemy(dmg: int, is_direct: bool = false) -> int:
	if dmg <= 0: return 0

	# 判官笔效果：增益一次攻击150%
	if Global.has_judge_pen and not Global.judge_pen_used and dmg > 0:
		dmg = int(dmg * 1.5)
		Global.judge_pen_used = true

	if not is_direct:
		if e_vulnerable > 0:
			dmg = int(dmg * 1.5)
		if p_strength > 0:
			dmg += p_strength
	var actual: int
	if is_direct:
		actual = dmg
		e_hp = maxi(0, e_hp - actual)
	else:
		actual = maxi(0, dmg - e_block)
		e_block = maxi(0, e_block - dmg)
		e_hp = maxi(0, e_hp - actual)
	# 黑魂：每次造成伤害回复 10% 生命
	if Global.has_black_soul and actual > 0:
		var soul_heal := int(actual * 0.10)
		if soul_heal > 0:
			p_hp = mini(p_max_hp, p_hp + soul_heal)
	# 攻击动画：玩家前冲 + 敌人晃动 + 爪痕
	if actual > 0:
		_anim_attack_forward(_player_emblem, 55.0)
		_anim_hit_shake(_enemy_emblem)
		_vfx_claw_mark(_enemy_emblem)
	return actual

# 玩家受到敌人攻击伤害（触发骨刺反弹、熔岩护甲）
func _deal_damage_to_player(dmg: int) -> int:
	var actual := maxi(0, dmg - p_block)
	p_block = maxi(0, p_block - dmg)
	p_hp = maxi(0, p_hp - actual)
	if actual > 0:
		# 攻击动画：敌人前冲 + 玩家晃动 + 暗红闪光 + 爪痕
		_anim_attack_forward(_enemy_emblem, -55.0)
		_anim_hit_shake(_player_emblem)
		_vfx_flash(Color(0.7, 0.05, 0.05, 0.25))
		_vfx_claw_mark(_player_emblem)
		if p_bone_spikes > 0:
			var spike := p_bone_spikes
			e_hp = maxi(0, e_hp - spike)
		if pow_lava_enchant:
			e_burn += 1
	return actual

# 玩家主动失去HP（卡牌效果，触发血肉苦弱）
# 返回附加信息字符串（用于并入 msgs）
func _player_lose_hp(amount: int) -> String:
	if amount <= 0: return ""
	p_hp = maxi(0, p_hp - amount)
	if pow_blood_flesh:
		var dmg := _deal_damage_to_enemy(amount, true)
		return "→血肉苦弱反弹 %d 伤" % dmg
	return ""

# ══════════════════════════════════════════════════════
# 战斗流程
# ══════════════════════════════════════════════════════
func _start_player_turn() -> void:
	turn_number += 1
	turn_cards = 0
	_state = State.PLAYER_TURN

	# 重置判官笔使用状态（新一回合）
	Global.judge_pen_used = false

	# ── Boss 嘲讽触发（每 2-3 回合一次）──────────────────
	if _is_boss_fight() and _taunt_system != null:
		_taunt_counter += 1
		if _taunt_counter >= _taunt_next:
			_taunt_counter = 0
			_taunt_next = randi_range(2, 3)
			_taunt_system.request_taunt(
				p_hp, p_max_hp, e_hp, e_max_hp, turn_number,
				_player_last_card_name if not _player_last_card_name.is_empty() else "未知",
				Global.selected_deck
			)

	var power_msgs: Array = []

	# 向死而生触发
	if deathwish_hp >= 0:
		p_block += deathwish_hp
		power_msgs.append("向死而生：+%d格挡" % deathwish_hp)
		deathwish_hp = -1

	# 森罗骨阵
	if pow_bone_forest:
		p_bone_spikes += turn_number
		power_msgs.append("森罗骨阵：+%d骨刺" % turn_number)

	# 虚空阴影
	if pow_void_shadow:
		e_vulnerable += 1
		power_msgs.append("虚空阴影：敌+1易伤")

	# 彼岸花开（使用上回合计数）
	if pow_biangan and biangan_done > 0:
		power_msgs.append("彼岸花开：额外抽%d张" % biangan_done)

	# 六道连弹自动回归牌堆
	var i := 0
	while i < _discard.size():
		if _discard[i].effect_id == "liu_dao_lian_dan":
			_draw_pile.append(_discard[i])
			_discard.remove_at(i)
		else:
			i += 1

	p_block = 0
	p_energy = p_max_energy
	# 能量封印（黑无常技能）
	if _player_energy_debuff:
		p_energy = maxi(1, p_energy - 1)
		_player_energy_debuff = false
		_log("能量封印：本回合最大能量-1")
	_draw_cards(5)

	# 彼岸花开额外抽牌（在摸5张之后）
	if pow_biangan and biangan_done > 0:
		_draw_cards(biangan_done)
	biangan_done = 0

	_end_turn_btn.disabled = false
	_refresh_ui()

	if power_msgs.size() > 0:
		_log("─── 第%d回合 ─── %s" % [turn_number, "  ".join(power_msgs)])
	else:
		_log("─── 第 %d 回合 ───" % turn_number)

func _on_end_turn() -> void:
	if _state != State.PLAYER_TURN: return
	_state = State.ENEMY_TURN
	_end_turn_btn.disabled = true
	_refresh_playable()
	_discard_hand()
	Global.behavior_tracker.on_turn_end()
	_log("敌人行动中...")
	await get_tree().create_timer(0.75).timeout
	if is_instance_valid(self):
		if _is_boss_fight(): _boss_turn()
		else: _enemy_turn()

func _enemy_turn() -> void:
	# 燃烧结算（回合末，在敌人攻击前）
	if e_burn > 0:
		e_hp = maxi(0, e_hp - e_burn)
		_log("🔥 燃烧：鬼卒受到 %d 点伤害（剩余 %d 层）" % [e_burn, e_burn])
		_vfx_flash(Color(1.0, 0.35, 0.05, 0.3))
		_anim_hit_shake(_enemy_emblem)
		_refresh_ui()
		if e_hp <= 0:
			await get_tree().create_timer(0.4).timeout
			if is_instance_valid(self): _end_battle(true)
			return
		await get_tree().create_timer(0.4).timeout
		if not is_instance_valid(self): return

	# 易伤自然衰减
	if e_vulnerable > 0: e_vulnerable -= 1

	# 敌人攻击
	var dmg := e_intent_dmg
	var actual := _deal_damage_to_player(dmg)

	var log_parts: Array = []
	if actual == 0:
		log_parts.append("敌人攻击 %d！格挡完全抵消！" % dmg)
	else:
		log_parts.append("敌人攻击 %d！受到 %d 点伤害。" % [dmg, actual])
	if actual > 0 and p_bone_spikes > 0:
		log_parts.append("骨刺反弹 %d 伤！" % p_bone_spikes)
	if actual > 0 and pow_lava_enchant:
		log_parts.append("熔岩护甲触发（燃烧→%d）" % e_burn)

	_log("  ".join(log_parts))
	_refresh_ui()

	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(self): return

	if e_hp <= 0: _end_battle(true); return
	if p_hp <= 0: _end_battle(false); return
	_start_player_turn()

# ══════════════════════════════════════════════════════
# 黑无常 Boss 回合系统
# ══════════════════════════════════════════════════════
func _input(event: InputEvent) -> void:
	if _waiting_for_click and event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_waiting_for_click = false
			_click_done.emit()

func _is_boss_fight() -> bool:
	return Global.current_node_type == "boss"

# 大卡牌展示覆层 —— 停留直到玩家点击
func _show_boss_card_overlay(card: Dictionary) -> void:
	var type_colors := {
		"attack": Color(0.32, 0.06, 0.06),
		"skill":  Color(0.08, 0.14, 0.30),
		"block":  Color(0.08, 0.22, 0.14),
		"power":  Color(0.22, 0.08, 0.30),
	}
	var type_accents := {
		"attack": Color(0.95, 0.35, 0.30),
		"skill":  Color(0.45, 0.68, 0.96),
		"block":  Color(0.38, 0.92, 0.55),
		"power":  Color(0.74, 0.46, 0.96),
	}
	var ctype: String = card.get("type", "attack")
	var accent: Color = type_accents.get(ctype, Color(0.92, 0.55, 0.28))

	# 半透明黑色遮罩（可点击）
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# 渐入遮罩
	var tw := create_tween()
	tw.tween_property(overlay, "color", Color(0, 0, 0, 0.72), 0.18)

	# 中央卡牌面板
	var panel := Control.new()
	panel.size = Vector2(380, 320)
	panel.position = Vector2(450, 200)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(panel)

	var bg := ColorRect.new()
	bg.color = type_colors.get(ctype, Color(0.15, 0.10, 0.05))
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	var border := ReferenceRect.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.border_color = accent
	border.border_width = 2.5
	border.editor_only = false
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(border)

	# 顶部类型标签
	var type_lbl := Label.new()
	var type_names := {"attack":"攻击","skill":"技能","block":"防御","power":"能力"}
	type_lbl.text = "黑无常出牌  ·  %s" % type_names.get(ctype, ctype)
	type_lbl.size = Vector2(380, 32)
	type_lbl.position = Vector2(0, 12)
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.add_theme_font_size_override("font_size", 13)
	type_lbl.add_theme_color_override("font_color", accent * Color(1,1,1,0.85))
	type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(type_lbl)

	# 卡名（大字）
	var name_lbl := Label.new()
	name_lbl.text = "【%s】" % card.get("name", "?")
	name_lbl.size = Vector2(380, 60)
	name_lbl.position = Vector2(0, 48)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 36)
	name_lbl.add_theme_color_override("font_color", accent)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_lbl)

	# 分割线
	var div := ColorRect.new()
	div.color = accent * Color(1,1,1,0.4)
	div.size = Vector2(320, 1)
	div.position = Vector2(30, 118)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(div)

	# 效果描述
	var desc_lbl := Label.new()
	desc_lbl.text = card.get("desc", "")
	desc_lbl.size = Vector2(330, 140)
	desc_lbl.position = Vector2(25, 130)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 18)
	desc_lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.80))
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(desc_lbl)

	# 底部提示（闪烁）
	var hint_lbl := Label.new()
	hint_lbl.text = "点击任意处继续..."
	hint_lbl.size = Vector2(1280, 28)
	hint_lbl.position = Vector2(-450, 640)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.add_theme_font_size_override("font_size", 13)
	hint_lbl.add_theme_color_override("font_color", Color(0.65, 0.60, 0.50))
	hint_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(hint_lbl)

	# 闪烁动画
	var blink := create_tween().set_loops()
	blink.tween_property(hint_lbl, "modulate:a", 0.3, 0.6)
	blink.tween_property(hint_lbl, "modulate:a", 1.0, 0.6)

	# 等待玩家点击
	_waiting_for_click = true
	await _click_done

	# 淡出移除
	blink.kill()
	var tw2 := create_tween()
	tw2.tween_property(overlay, "modulate:a", 0.0, 0.15)
	await tw2.finished
	overlay.queue_free()

func _init_boss_deck() -> void:
	_boss_draw = BossCardLibrary.get_deck()
	_boss_draw.shuffle()
	_boss_hand.clear()
	_boss_discard.clear()
	_boss_draw_cards(3)

func _boss_draw_cards(n: int) -> void:
	for _i in n:
		if _boss_draw.is_empty():
			_boss_draw = _boss_discard.duplicate()
			_boss_draw.shuffle()
			_boss_discard.clear()
		if not _boss_draw.is_empty():
			_boss_hand.append(_boss_draw.pop_back())

func _boss_turn() -> void:
	# 无常显形被动
	if _boss_per_turn_block > 0:
		e_block += _boss_per_turn_block
		_log("无常显形：黑无常获得%d格挡" % _boss_per_turn_block)

	# 燃烧结算
	if e_burn > 0:
		e_hp = maxi(0, e_hp - e_burn)
		_log("🔥 燃烧：黑无常受到 %d 点伤害（剩余 %d 层）" % [e_burn, e_burn])
		_vfx_flash(Color(1.0, 0.35, 0.05, 0.3))
		_anim_hit_shake(_enemy_emblem)
		_refresh_ui()
		if e_hp <= 0:
			await get_tree().create_timer(0.4).timeout
			if is_instance_valid(self): _end_battle(true)
			return
		await get_tree().create_timer(0.4).timeout
		if not is_instance_valid(self): return

	if e_vulnerable > 0: e_vulnerable -= 1

	# 补充手牌
	while _boss_hand.size() < 3:
		_boss_draw_cards(1)

	if _boss_hand.is_empty():
		_start_player_turn(); return

	# 更新意图显示
	_e_intent_lbl.text = "意图：思考中..."
	_refresh_ui()

	# 请求 AI 决策
	var gs := {
		"player_hp": p_hp, "player_max_hp": p_max_hp,
		"boss_hp": e_hp, "boss_max_hp": e_max_hp,
		"turn": turn_number, "player_block": p_block,
	}
	_boss_ai.decide(gs, _boss_hand)
	# 等待 card_decided 信号（由 _on_boss_card_decided 处理）

func _on_boss_card_decided(card_id: String) -> void:
	if not is_instance_valid(self): return
	if _boss_hand.is_empty(): _start_player_turn(); return

	# 若AI返回不在手牌中的牌，随机选一张
	var chosen := card_id
	if chosen not in _boss_hand:
		chosen = _boss_hand[randi() % _boss_hand.size()]

	_boss_hand.erase(chosen)
	_boss_discard.append(chosen)
	_boss_last_card = chosen

	await _apply_boss_card(chosen)
	if not is_instance_valid(self): return

	await get_tree().create_timer(0.4).timeout
	if not is_instance_valid(self): return

	if e_hp <= 0: _end_battle(true); return
	if p_hp <= 0: _end_battle(false); return
	_start_player_turn()

func _apply_boss_card(card_id: String) -> void:
	var card: Dictionary = BossCardLibrary.CARDS.get(card_id, {})
	if card.is_empty(): return

	var cname: String = card.get("name", "?")

	_e_intent_lbl.text = "出牌：【%s】" % cname
	_refresh_ui()
	await _show_boss_card_overlay(card)
	if not is_instance_valid(self): return

	var log_parts: Array = ["黑无常使用【%s】！" % cname]

	match card_id:
		"soul_chain":
			var dmg: int = card.get("dmg", 8)
			if e_burn > 0: dmg += card.get("bonus_dmg", 4)
			var actual := _deal_damage_to_player(dmg)
			log_parts.append("造成%d伤害" % actual)

		"dark_fan":
			e_block += card.get("block", 10)
			log_parts.append("获得%d格挡" % card.get("block", 10))

		"judgment":
			var actual := _deal_damage_to_player(card.get("dmg", 16))
			log_parts.append("造成%d伤害" % actual)

		"underworld_cmd":
			e_block += card.get("block", 8)
			_boss_atk_boost = true
			log_parts.append("获得%d格挡，下次攻击+50%%" % card.get("block", 8))

		"wind_fire":
			var stacks := e_burn
			e_burn = 0
			var dmg: int = stacks * card.get("dmg_per_burn", 4)
			if dmg > 0:
				var actual := _deal_damage_to_player(dmg)
				log_parts.append("散去%d层燃烧，造成%d伤害" % [stacks, actual])
			else:
				log_parts.append("清除自身燃烧")

		"cold_shield":
			var blk: int = card.get("block", 8)
			if e_burn > 3: blk += card.get("bonus_block", 8)
			e_block += blk
			log_parts.append("获得%d格挡" % blk)

		"bone_pierce":
			# ignore_bone=true：直接扣HP，不触发骨刺反弹
			var dmg: int = card.get("dmg", 14)
			if _boss_atk_boost: dmg = int(dmg * 1.5); _boss_atk_boost = false
			var actual := maxi(0, dmg - p_block)
			p_block = maxi(0, p_block - dmg)
			p_hp = maxi(0, p_hp - actual)
			Global.behavior_tracker.record_damage_dealt(0)  # 不算玩家追踪
			log_parts.append("穿骨一击%d伤（无视骨刺）" % actual)

		"soften":
			var removed := mini(p_bone_spikes, card.get("remove_bone", 4))
			p_bone_spikes -= removed
			var actual := _deal_damage_to_player(card.get("dmg", 6))
			log_parts.append("移除%d层骨刺，造成%d伤害" % [removed, actual])

		"life_cut":
			var missing := p_max_hp - p_hp
			var dmg: int = maxi(1, missing / card.get("divisor", 3))
			if _boss_atk_boost: dmg = int(dmg * 1.5); _boss_atk_boost = false
			var actual := _deal_damage_to_player(dmg)
			log_parts.append("生机斩断%d伤（基于失血）" % actual)

		"blood_acc":
			var val: int = card.get("value", 5)
			p_hp = maxi(0, p_hp - val)
			log_parts.append("直接失去%dHP（穿透格挡）" % val)

		"exorcism":
			e_block += card.get("block", 10)
			e_vulnerable = 0
			log_parts.append("获得%d格挡，清除易伤" % card.get("block", 10))

		"yang_energy":
			var dmg: int = card.get("dmg", 12)
			if _boss_atk_boost: dmg = int(dmg * 1.5); _boss_atk_boost = false
			# 本次攻击不受玩家易伤加成（临时清0再还原）
			var saved_vuln := e_vulnerable
			e_vulnerable = 0
			var actual := _deal_damage_to_player(dmg)
			e_vulnerable = saved_vuln
			log_parts.append("阳气冲煞%d伤（无视易伤加成）" % actual)

		"energy_seal":
			var actual := _deal_damage_to_player(card.get("dmg", 6))
			_player_energy_debuff = true
			log_parts.append("造成%d伤，下回合能量封印" % actual)

		"chain_break":
			var dmg: int = card.get("dmg", 10)
			if _boss_atk_boost: dmg = int(dmg * 1.5); _boss_atk_boost = false
			var actual := _deal_damage_to_player(dmg)
			log_parts.append("造成%d伤" % actual)
			# 丢弃玩家随机一张手牌
			if not _hand.is_empty():
				var ri := randi() % _hand.size()
				var discarded: CardData = _hand[ri]
				_hand.remove_at(ri)
				if ri < _hand_nodes.size():
					var dn = _hand_nodes[ri]
					_hand_nodes.remove_at(ri)
					if is_instance_valid(dn): dn.queue_free()
				_discard.append(discarded)
				log_parts.append("断链术：【%s】被弃置！" % discarded.card_name)
				_reposition_hand()

		"manifestation":
			_boss_per_turn_block = card.get("value", 4)
			log_parts.append("无常显形：每回合自动获得%d格挡" % _boss_per_turn_block)

		"full_power":
			var dmg: int = card.get("dmg", 22)
			if _boss_atk_boost: dmg = int(dmg * 1.5); _boss_atk_boost = false
			var actual := _deal_damage_to_player(dmg)
			# 清除玩家增益
			p_bone_spikes = 0
			p_strength = 0
			pow_lava_enchant = false
			pow_bone_forest = false
			pow_blood_flesh = false
			pow_void_shadow = false
			pow_biangan = false
			log_parts.append("黑白无常%d伤，清除全部增益！" % actual)

	_log("  ".join(log_parts))
	_refresh_ui()

func _on_card_released(card_ui: CardUI) -> void:
	if _state != State.PLAYER_TURN:
		card_ui.return_to_home(); return
	var card: CardData = card_ui.card_data
	if card.unplayable:
		card_ui.return_to_home(); return
	var center_y := card_ui.global_position.y + CARD_H / 2.0
	var cost := _get_effective_cost(card)
	if center_y < PLAY_Y and cost <= p_energy:
		# 先从手牌移除，防止 _draw_cards→_rebuild_hand 产生幽灵节点
		var hi := _hand.find(card)
		if hi >= 0: _hand.remove_at(hi)
		var ni := _hand_nodes.find(card_ui)
		if ni >= 0: _hand_nodes.remove_at(ni)
		card_ui.queue_free()
		_reposition_hand()
		# 再解算效果
		_play_card(card)
		if not card.exhaust:
			_discard.append(card)
		_update_piles()
		_refresh_ui()
		if e_hp <= 0: _end_battle(true)
		elif p_hp <= 0: _end_battle(false)
	else:
		card_ui.return_to_home()

func _play_card(card: CardData) -> void:
	# 行为追踪
	Global.behavior_tracker.record_card_played(card, turn_number)
	_player_last_card_name = card.card_name
	# 消耗能量
	if card.is_x_cost:
		var x_val := p_energy
		p_energy = 0
		turn_cards += 1
		_resolve_card_effects(card, x_val)
	else:
		p_energy -= card.cost
		turn_cards += 1
		_resolve_card_effects(card, 0)

func _resolve_card_effects(card: CardData, x_val: int) -> void:
	var msgs: Array = []

	# 基础伤害
	if card.damage > 0:
		var actual := _deal_damage_to_enemy(card.damage)
		msgs.append("造成 %d 点伤害" % actual)
		if card.lifesteal:
			var heal := mini(actual, p_max_hp - p_hp)
			p_hp += heal
			if heal > 0: msgs.append("吸血 %d HP" % heal)

	# 基础格挡
	if card.block > 0:
		p_block += card.block
		msgs.append("获得 %d 点格挡" % card.block)
		_vfx_flash(Color(0.3, 0.6, 1.0, 0.18))

	# 对敌燃烧
	if card.burn > 0:
		e_burn += card.burn
		msgs.append("施加 %d 层燃烧" % card.burn)
		_vfx_flash(Color(1.0, 0.4, 0.1, 0.25))

	# 玩家骨刺
	if card.bone_spikes > 0:
		p_bone_spikes += card.bone_spikes
		msgs.append("获得 %d 层骨刺" % card.bone_spikes)
		_vfx_flash(Color(0.9, 0.9, 0.85, 0.2))

	# 摸牌
	if card.draw_cards > 0:
		_draw_cards(card.draw_cards)
		msgs.append("抽 %d 张牌" % card.draw_cards)

	# 获得能量
	if card.gain_energy > 0:
		p_energy += card.gain_energy
		msgs.append("获得 %d 点能量" % card.gain_energy)

	# 回血/失血
	if card.heal_self > 0:
		var heal := mini(card.heal_self, p_max_hp - p_hp)
		p_hp += heal
		msgs.append("回复 %d HP" % heal)
	elif card.heal_self < 0:
		var loss := -card.heal_self
		var extra := _player_lose_hp(loss)
		msgs.append("失去 %d HP%s" % [loss, extra])
		_vfx_flash(Color(0.7, 0.05, 0.05, 0.3))

	# 特殊效果
	_resolve_special(card, x_val, msgs)

	_log("[%s]  %s" % [card.card_name, "  /  ".join(msgs) if msgs.size() > 0 else "无效果"])

# ── 特殊效果分发 ──────────────────────────────────────
func _resolve_special(card: CardData, x_val: int, msgs: Array) -> void:
	match card.effect_id:
		# ── 火焰 ────────────────────────────────────
		"ming_he":
			var ash := CardLibrary.c_hui_jin()
			_hand.append(ash)
			var nd := CardUI.new()
			nd.setup(ash)
			nd.card_released.connect(_on_card_released)
			_hand_root.add_child(nd)
			_hand_nodes.append(nd)
			_reposition_hand()
			msgs.append("生成灰烬")
		"fei_e":
			if e_burn > 0:
				var bonus := _deal_damage_to_enemy(3)
				msgs.append("燃烧追加 %d 伤" % bonus)
		"jiao_tu":
			if e_burn > 0:
				var stacks := e_burn
				var actual := _deal_damage_to_enemy(stacks * 2, true)
				msgs.append("消耗 %d 层燃烧→ %d 伤" % [stacks, actual])
				e_burn = 0
			else:
				msgs.append("无燃烧可消耗")
		"pow_lava_enchant":
			pow_lava_enchant = true
			msgs.append("熔岩护甲已激活")
		"lie_huo_chong_sheng":
			p_block = 0
			msgs.append("格挡清零")
		"lian_yu":
			if e_burn > 0:
				var bonus := _deal_damage_to_enemy(10)
				msgs.append("燃烧追加 %d 伤" % bonus)
		"hui_jin":
			pass  # 废牌，无效果

		# ── 骨刺 ────────────────────────────────────
		"sui_gu":
			if p_bone_spikes > 0:
				var bonus := _deal_damage_to_enemy(p_bone_spikes)
				msgs.append("骨刺追加 %d 伤" % bonus)
		"gu_ci_fan_tan":
			if p_bone_spikes > 0:
				var dmg := p_bone_spikes
				var actual := _deal_damage_to_enemy(dmg, true)
				msgs.append("%d 层骨刺→ %d 直接伤害" % [dmg, actual])
				p_bone_spikes = 0
			else:
				msgs.append("无骨刺可转化")
		"pow_bone_forest":
			pow_bone_forest = true
			msgs.append("森罗骨阵已激活")

		# ── 血肉 ────────────────────────────────────
		"yi_xue_ji_xue":
			# heal_self=-5 已在基础逻辑触发过，这里只处理伤害
			var actual := _deal_damage_to_enemy(15, true)
			msgs.append("祭血→ %d 直接伤害" % actual)
		"pow_blood_flesh":
			pow_blood_flesh = true
			msgs.append("血肉苦弱已激活")
		"xian_xue_fei_jian":
			var missing := p_max_hp - p_hp
			var bonus := mini(missing, 12)
			if bonus > 0:
				var actual := _deal_damage_to_enemy(bonus)
				msgs.append("失血追加 %d 伤" % actual)
		"xian_xue_qiang_hua":
			# heal_self=-8 已在基础逻辑触发过
			p_strength += 4
			msgs.append("攻击力 +4（共 +%d）" % p_strength)
		"xiang_si_er_sheng":
			p_hp = 1
			deathwish_hp = 30
			msgs.append("HP→1，下回合获得30格挡")
		"bo_pi_zhi_shu":
			var stripped := e_block
			e_block = 0
			if stripped > 0:
				msgs.append("清除敌人 %d 点格挡" % stripped)

		# ── 幽灵 ────────────────────────────────────
		"suo_hun_suo":
			e_vulnerable += 3
			msgs.append("施加3层易伤")
			_vfx_flash(Color(0.5, 0.15, 0.7, 0.25))
		"yin_hun_bu_san":
			if e_vulnerable > 0:
				var bonus := _deal_damage_to_enemy(6)
				msgs.append("易伤追加 %d 伤" % bonus)
		"pow_void_shadow":
			pow_void_shadow = true
			msgs.append("虚空阴影已激活")
		"you_ling_jiu_chan":
			# draw_cards=1 已在基础逻辑处理，这里加入怨灵缠身
			var yuan := CardLibrary.c_yuan_ling_chan_shen()
			_hand.append(yuan)
			var nd := CardUI.new()
			nd.setup(yuan)
			nd.card_released.connect(_on_card_released)
			_hand_root.add_child(nd)
			_hand_nodes.append(nd)
			_reposition_hand()
			msgs.append("加入怨灵缠身")
		"pow_biangan":
			pow_biangan = true
			msgs.append("彼岸花开已激活")

		# ── 循环 ────────────────────────────────────
		"lian_huan_chong_ji":
			if turn_cards >= 3:
				var bonus := _deal_damage_to_enemy(3)
				msgs.append("连环追加 %d 伤" % bonus)
		"liu_dao_lian_dan":
			var total := 0
			for _i in 6:
				total += _deal_damage_to_enemy(2)
			msgs.append("六连射共 %d 伤" % total)
		"ji_feng_lian_zhan":
			_draw_cards(1)
			var zero_atk_count := 0
			for c in _hand:
				if c.type == 0 and c.cost == 0 and not c.is_x_cost:
					zero_atk_count += 1
			if zero_atk_count > 0:
				var burst := _deal_damage_to_enemy(zero_atk_count * 3)
				msgs.append("抽1牌，%d 张0费攻击→ %d 伤" % [zero_atk_count, burst])
			else:
				msgs.append("抽1牌")
		"shun_xi_wan_bian":
			# draw_cards=1 已在基础逻辑处理
			# 若刚摸到的最新一张牌费用为0，再摸1张（限一次）
			if not _hand.is_empty():
				var last_drawn: CardData = _hand.back()
				if last_drawn.cost == 0:
					_draw_cards(1)
					msgs.append("链式触发抽1牌")
		"neng_liang_yin_bao":
			if x_val > 0:
				var actual := _deal_damage_to_enemy(x_val * 8)
				msgs.append("消耗 %d 能量→ %d 伤" % [x_val, actual])
			else:
				msgs.append("能量为0，无效果")
		"gong_ming_lian_ji":
			var dmg := turn_cards * 4
			var actual := _deal_damage_to_enemy(dmg)
			msgs.append("%d 张×4 = %d 伤" % [turn_cards, actual])

func _end_battle(won: bool) -> void:
	_state = State.WIN if won else State.LOSE
	_end_turn_btn.disabled = true
	_refresh_playable()
	# 保存玩家行为数据
	Global.behavior_tracker.on_game_end()

	if won:
		# 写回 Global
		Global.save_battle_result(p_hp, Global.enemy_souls_reward)
		_log("%s 已被击败！获得 %d 魂魄。" % [_e_name, Global.enemy_souls_reward])
		await get_tree().create_timer(0.8).timeout
		if not is_instance_valid(self): return
		if Global.current_node_type == "boss":
			# Boss 通关 → 显示通关界面
			_show_floor_clear()
		elif Global.current_node_type == "elite":
			# 精英战斗 → 触发冥将的遗物三选一（给3张）
			Global.current_battle_gives_card = true
			get_tree().change_scene_to_file("res://Scenes/Reward/CardRewardScene.tscn")
		else:
			# 普通战斗 → 只给魂魄，直接回地图
			_log("普通怪物只掉落魂魄...")
			get_tree().change_scene_to_file("res://Scenes/Map/MapScene.tscn")
	else:
		_log("你的魂魄消散于无间地狱之中...")
		var lbl := _result_overlay.get_node("ResultLabel") as Label
		lbl.text = "战败..."
		lbl.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		_result_overlay.visible = true

# ══════════════════════════════════════════════════════
# 嘲讽气泡
# ══════════════════════════════════════════════════════
func _on_taunt_ready(text: String) -> void:
	if not is_instance_valid(self): return
	# 移除旧气泡
	if is_instance_valid(_taunt_bubble):
		_taunt_bubble.queue_free()
	_taunt_bubble = _make_taunt_bubble(text)
	add_child(_taunt_bubble)
	# 4 秒后淡出消失
	get_tree().create_timer(4.2).timeout.connect(func():
		if is_instance_valid(_taunt_bubble):
			var tw := (_taunt_bubble as Node).create_tween()
			tw.tween_property(_taunt_bubble, "modulate:a", 0.0, 0.45)
			tw.tween_callback(_taunt_bubble.queue_free)
	, CONNECT_ONE_SHOT)

func _make_taunt_bubble(text: String) -> Control:
	# 气泡面板（圆角样式）
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.10, 0.92)
	style.border_color = Color(0.42, 0.92, 0.80)
	style.set_border_width_all(2)
	style.corner_radius_top_left    = 10
	style.corner_radius_top_right   = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 4   # 右下尖角，指向 Boss
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(720, 52)
	panel.size = Vector2(490, 96)
	panel.modulate.a = 0.0

	# 角色名小标签
	var name_lbl := Label.new()
	name_lbl.text = "黑无常"
	name_lbl.position = Vector2(14, 6)
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color(0.42, 0.92, 0.80))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_lbl)

	# 正文
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(14, 26)
	lbl.size = Vector2(462, 62)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.93, 0.90, 0.84))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl)

	# 淡入
	var tw := panel.create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.30)
	return panel

# ══════════════════════════════════════════════════════
# Boss 战胜利 → 过场剧情
# ══════════════════════════════════════════════════════
func _show_floor_clear() -> void:
	# 清除嘲讽气泡
	if is_instance_valid(_taunt_bubble):
		_taunt_bubble.queue_free()
	# 淡出进入胜利过场
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 0.5)
	tw.tween_callback(func():
		get_tree().change_scene_to_file(
			"res://Scenes/BossVictory/BossVictoryScene.tscn")
	)

func _back_to_select() -> void:
	get_tree().change_scene_to_file("res://Scenes/Select/CharacterSelectScene.tscn")

func _restart_battle() -> void:
	_result_overlay.visible = false
	# 重置所有状态
	p_hp = p_max_hp; p_block = 0
	p_bone_spikes = 0; p_strength = 0
	e_hp = e_max_hp; e_block = 0
	e_burn = 0; e_vulnerable = 0
	pow_lava_enchant = false; pow_bone_forest = false
	pow_blood_flesh = false; pow_void_shadow = false; pow_biangan = false
	turn_number = 0; turn_cards = 0; biangan_done = 0
	deathwish_hp = -1
	_init_deck()
	_start_player_turn()

# ══════════════════════════════════════════════════════
# UI 刷新
# ══════════════════════════════════════════════════════
func _refresh_ui() -> void:
	_p_hp_bar.value = p_hp
	_p_hp_lbl.text = "%d / %d" % [p_hp, p_max_hp]

	# 玩家状态行
	var p_status: Array[String] = []
	if p_block > 0:       p_status.append("盾 %d" % p_block)
	if p_bone_spikes > 0: p_status.append("骨刺×%d" % p_bone_spikes)
	if p_strength > 0:    p_status.append("力量+%d" % p_strength)
	_p_block_lbl.text = "  ".join(p_status)

	_e_hp_bar.value = e_hp
	_e_hp_lbl.text = "%d / %d" % [e_hp, e_max_hp]
	if e_block > 0:
		_e_block_lbl.text = "盾 %d" % e_block
	else:
		_e_block_lbl.text = ""

	# 敌人意图+状态行
	if _is_boss_fight():
		if _boss_last_card.is_empty():
			_e_intent_lbl.text = "黑无常正在观察你..."
		else:
			var lc: Dictionary = BossCardLibrary.CARDS.get(_boss_last_card, {})
			_e_intent_lbl.text = "上次出牌：【%s】" % lc.get("name", "?")
		if e_burn > 0: _e_intent_lbl.text += "\n🔥燃烧×%d" % e_burn
	else:
		var intent_parts: Array[String] = ["意图: 攻击 %d" % e_intent_dmg]
		if e_burn > 0:       intent_parts.append("🔥燃烧×%d" % e_burn)
		if e_vulnerable > 0: intent_parts.append("易伤×%d" % e_vulnerable)
		_e_intent_lbl.text = "\n".join(intent_parts)

	_energy_lbl.text = "%d / %d" % [p_energy, p_max_energy]

	# 能力栏
	var pow_list: Array[String] = []
	if pow_lava_enchant: pow_list.append("熔岩护甲")
	if pow_bone_forest:  pow_list.append("森罗骨阵")
	if pow_blood_flesh:  pow_list.append("血肉苦弱")
	if pow_void_shadow:  pow_list.append("虚空阴影")
	if pow_biangan:      pow_list.append("彼岸花开")
	if deathwish_hp >= 0: pow_list.append("向死而生(待触发)")
	_powers_lbl.text = "能力：" + "  ".join(pow_list) if pow_list.size() > 0 else ""

	_refresh_playable()

func _update_piles() -> void:
	if is_instance_valid(_draw_lbl):
		_draw_lbl.text = "牌堆：%d" % _draw_pile.size()
	if is_instance_valid(_discard_lbl):
		_discard_lbl.text = "弃牌：%d" % _discard.size()

func _log(msg: String) -> void:
	if is_instance_valid(_log_lbl): _log_lbl.text = msg

func _log_append(msg: String) -> void:
	if is_instance_valid(_log_lbl): _log_lbl.text += msg
