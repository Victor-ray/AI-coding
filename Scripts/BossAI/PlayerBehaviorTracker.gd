extends RefCounted
class_name PlayerBehaviorTracker

# ══════════════════════════════════════════════════════
# 玩家行为追踪器 —— 跨局持久化学习
# ══════════════════════════════════════════════════════
const SAVE_PATH := "user://player_behavior.json"

# 跨局累计数据
var total_games:         int = 0
var total_turns:         int = 0
var total_cards_played:  int = 0
var total_damage_dealt:  int = 0
var total_block_gained:  int = 0

var cards_by_type: Dictionary = {"attack": 0, "skill": 0, "power": 0}
var effect_usage:  Dictionary = {
	"burn": 0, "block": 0, "bone": 0, "blood": 0, "ghost": 0, "cycle": 0
}

# 本局临时数据
var _cur_turn:             int   = 0
var _early_aggression:     float = 0.0  # 前3回合攻击倾向

func _init() -> void:
	load_data()

# ──────────────────────────────────────────────────────
# 持久化
# ──────────────────────────────────────────────────────
func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f: return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if not data is Dictionary: return
	total_games        = data.get("total_games", 0)
	total_turns        = data.get("total_turns", 0)
	total_cards_played = data.get("total_cards_played", 0)
	total_damage_dealt = data.get("total_damage_dealt", 0)
	total_block_gained = data.get("total_block_gained", 0)
	cards_by_type      = data.get("cards_by_type", {"attack":0,"skill":0,"power":0})
	effect_usage       = data.get("effect_usage", {"burn":0,"block":0,"bone":0,"blood":0,"ghost":0,"cycle":0})
	_early_aggression  = data.get("early_aggression", 0.0)

func save_data() -> void:
	var data := {
		"total_games":        total_games,
		"total_turns":        total_turns,
		"total_cards_played": total_cards_played,
		"total_damage_dealt": total_damage_dealt,
		"total_block_gained": total_block_gained,
		"cards_by_type":      cards_by_type,
		"effect_usage":       effect_usage,
		"early_aggression":   _early_aggression,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not f: return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()

# ──────────────────────────────────────────────────────
# 记录事件（BattleScene 调用）
# ──────────────────────────────────────────────────────
func record_card_played(card: CardData, turn: int) -> void:
	total_cards_played += 1
	var tk := "attack" if card.type == 0 else ("skill" if card.type == 1 else "power")
	cards_by_type[tk] = cards_by_type.get(tk, 0) + 1

	var desc := card.description.to_lower()
	if "燃烧" in desc:                       effect_usage["burn"]  = effect_usage.get("burn", 0) + 1
	if "格挡" in desc or "护盾" in desc:      effect_usage["block"] = effect_usage.get("block", 0) + 1
	if "骨刺" in desc:                       effect_usage["bone"]  = effect_usage.get("bone", 0) + 1
	if "失血" in desc or "献血" in desc:      effect_usage["blood"] = effect_usage.get("blood", 0) + 1
	if "怨灵" in desc or "易伤" in desc:      effect_usage["ghost"] = effect_usage.get("ghost", 0) + 1
	if "循环" in desc or "能量+1" in desc:    effect_usage["cycle"] = effect_usage.get("cycle", 0) + 1

	if turn <= 3 and card.type == 0:
		_early_aggression = minf(1.0, _early_aggression + 0.12)

func record_damage_dealt(dmg: int) -> void:
	total_damage_dealt += dmg

func record_block_gained(block: int) -> void:
	total_block_gained += block

func on_turn_end() -> void:
	total_turns += 1
	_cur_turn += 1

func on_game_end() -> void:
	total_games += 1
	save_data()

# ──────────────────────────────────────────────────────
# 生成18维特征向量（归一化到0-1），供神经网络使用
# ──────────────────────────────────────────────────────
func get_feature_vector(
	player_hp: int, player_max_hp: int,
	boss_hp: int, boss_max_hp: int,
	turn: int, player_block: int
) -> Array:
	var tc := maxf(1.0, float(total_cards_played))
	var tt := maxf(1.0, float(total_turns))

	var atk_r  := float(cards_by_type.get("attack", 0)) / tc
	var skl_r  := float(cards_by_type.get("skill",  0)) / tc
	var pow_r  := float(cards_by_type.get("power",  0)) / tc
	var cpt    := minf(1.0, (float(total_cards_played) / tt) / 5.0)
	var burn_u := minf(1.0, float(effect_usage.get("burn",  0)) / tc)
	var blk_u  := minf(1.0, float(effect_usage.get("block", 0)) / tc)
	var bone_u := minf(1.0, float(effect_usage.get("bone",  0)) / tc)
	var bld_u  := minf(1.0, float(effect_usage.get("blood", 0)) / tc)
	var gst_u  := minf(1.0, float(effect_usage.get("ghost", 0)) / tc)
	var cyc_u  := minf(1.0, float(effect_usage.get("cycle", 0)) / tc)
	var avg_d  := float(total_damage_dealt) / tt
	var avg_b  := float(total_block_gained) / tt
	var aggr   := avg_d / maxf(1.0, avg_d + avg_b)

	return [
		atk_r, skl_r, pow_r, cpt,
		burn_u, blk_u, bone_u, bld_u, gst_u, cyc_u,
		aggr, _early_aggression,
		minf(1.0, avg_d / 30.0),
		minf(1.0, avg_b / 20.0),
		float(player_hp) / maxf(1.0, float(player_max_hp)),
		float(boss_hp)   / maxf(1.0, float(boss_max_hp)),
		minf(1.0, float(turn) / 20.0),
		minf(1.0, float(player_block) / 30.0),
	]

# 生成画像摘要（给DeepSeek读）
func get_profile_dict() -> Dictionary:
	var tc := maxf(1.0, float(total_cards_played))
	return {
		"attack_ratio": float(cards_by_type.get("attack", 0)) / tc,
		"skill_ratio":  float(cards_by_type.get("skill",  0)) / tc,
		"burn_usage":   float(effect_usage.get("burn",  0)) / tc,
		"block_usage":  float(effect_usage.get("block", 0)) / tc,
		"bone_usage":   float(effect_usage.get("bone",  0)) / tc,
		"blood_usage":  float(effect_usage.get("blood", 0)) / tc,
		"ghost_usage":  float(effect_usage.get("ghost", 0)) / tc,
		"cycle_usage":  float(effect_usage.get("cycle", 0)) / tc,
		"early_aggr":   _early_aggression,
		"total_games":  total_games,
	}
