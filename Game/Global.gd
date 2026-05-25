extends Node

# ══════════════════════════════════════════════════════
# AI 系统
# ══════════════════════════════════════════════════════
var deepseek_api_key: String = ""
var use_ai_mode:      bool   = false
var behavior_tracker: PlayerBehaviorTracker = PlayerBehaviorTracker.new()

# ══════════════════════════════════════════════════════
# 角色/卡组
# ══════════════════════════════════════════════════════
var selected_deck: String = "fire"

# ══════════════════════════════════════════════════════
# 跑局持久状态
# ══════════════════════════════════════════════════════
var has_black_soul:    bool  = false  # Boss 战击杀黑无常后永久获得
var has_judge_pen:     bool  = false  # 放过黑无常后获得，使用后增益一次攻击150%
var judge_pen_used:    bool  = false  # 判官笔是否已使用（每场战斗重置）
var author_note_shown: bool  = false  # 是否已看过作者说明（控制首次流程）
var from_settings:     bool  = false  # 从设置页跳过来，不自动跳过 ApiKey

var is_run_active:  bool  = false
var player_hp:      int   = 80
var player_max_hp:  int   = 80
var player_souls:   int   = 0
var bonus_energy:   int   = 0   # 商店购买地府令牌后永久+1
var current_deck:   Array = []  # Array[CardData]，每场战斗用 duplicate() 拷贝

# ══════════════════════════════════════════════════════
# 已解锁的高级卡牌（每个流派独立追踪）
# ══════════════════════════════════════════════════════
var unlocked_cards: Dictionary = {
	"fire":  [],   # 火焰系已解锁高级卡
	"bone":  [],   # 白骨系已解锁高级卡
	"blood": [],   # 血煞系已解锁高级卡
	"ghost": [],   # 幽魂系已解锁高级卡
	"cycle": [],   # 轮回系已解锁高级卡
}

# ══════════════════════════════════════════════════════
# 商店状态（每次跑局重置）
# ══════════════════════════════════════════════════════
var shop_scroll_purchased: bool = false  # 本次跑局是否已购买幽冥秘卷

# ══════════════════════════════════════════════════════
# 当前战斗奖励类型
# ══════════════════════════════════════════════════════
var current_battle_gives_card: bool = false  # true=精英/boss给卡牌奖励，false=普通只给魂魄

# ══════════════════════════════════════════════════════
# 地图状态
# ══════════════════════════════════════════════════════
var current_node_id: int   = -1   # 当前所在节点（-1=未开始）
var visited_nodes:   Array = []   # 已访问节点 id 列表

# ══════════════════════════════════════════════════════
# 当前战斗的敌人信息（MapScene 写入，BattleScene 读取）
# ══════════════════════════════════════════════════════
var enemy_name:         String = ""
var enemy_max_hp:       int    = 0
var enemy_atk:          int    = 0
var enemy_souls_reward: int    = 0
var current_node_type:  String = ""  # "battle" / "elite" / "boss"

# ══════════════════════════════════════════════════════
# 初始化新跑局（角色选择时调用）
# ══════════════════════════════════════════════════════
func init_run(deck_id: String) -> void:
	selected_deck    = deck_id
	is_run_active    = true
	player_hp        = 80
	player_max_hp    = 80
	player_souls     = 0
	bonus_energy     = 0
	current_node_id  = -1
	visited_nodes    = []
	shop_scroll_purchased = false
	# 已解锁卡牌保留（跨跑局不重置）

	# 初始卡组 = 基础5张 x3 + 已解锁的高级卡
	match deck_id:
		"fire":  current_deck = CardLibrary.get_starting_deck("fire").duplicate()
		"bone":  current_deck = CardLibrary.get_starting_deck("bone").duplicate()
		"blood": current_deck = CardLibrary.get_starting_deck("blood").duplicate()
		"ghost": current_deck = CardLibrary.get_starting_deck("ghost").duplicate()
		"cycle": current_deck = CardLibrary.get_starting_deck("cycle").duplicate()
		_:       current_deck = CardLibrary.get_starting_deck("fire").duplicate()

	# 合并已解锁的高级卡
	var unlocked: Array = unlocked_cards.get(deck_id, [])
	for card in unlocked:
		current_deck.append(card)

# ══════════════════════════════════════════════════════
# 战斗结束后写回 HP（BattleScene 调用）
# ══════════════════════════════════════════════════════
func save_battle_result(hp_remaining: int, souls_earned: int) -> void:
	player_hp     = hp_remaining
	player_souls += souls_earned

# ══════════════════════════════════════════════════════
# 解锁一张高级卡（幽冥秘卷使用）- 三位一体入库
# ══════════════════════════════════════════════════════
func unlock_card(card: CardData) -> void:
	var deck: String = selected_deck
	if not unlocked_cards.has(deck):
		unlocked_cards[deck] = []
	unlocked_cards[deck].append(card)
	# 三位一体：直接加入3张复制品
	for i in 3:
		current_deck.append(card)

# ══════════════════════════════════════════════════════
# 添加三张卡牌到当前卡组（三位一体法则）
# ══════════════════════════════════════════════════════
func add_cards_3_to_deck(card: CardData) -> void:
	for i in 3:
		current_deck.append(card)
