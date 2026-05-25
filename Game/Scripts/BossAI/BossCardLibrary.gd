extends Node
class_name BossCardLibrary

# ══════════════════════════════════════════════════════
# 黑无常卡组 —— 针对五套玩家牌型的克制卡
# ══════════════════════════════════════════════════════
const CARDS: Dictionary = {
	# ── 通用牌 ──────────────────────────────────────
	"soul_chain": {
		"id": "soul_chain", "name": "勾魂索",
		"desc": "造成8点伤害\n若玩家有燃烧层则额外+4伤害",
		"type": "attack", "dmg": 8, "bonus_dmg": 4,
		"condition": "player_has_burn", "counter": "fire",
	},
	"dark_fan": {
		"id": "dark_fan", "name": "黑白扇",
		"desc": "获得10点格挡",
		"type": "block", "block": 10, "counter": "general",
	},
	"judgment": {
		"id": "judgment", "name": "无常判决",
		"desc": "造成16点伤害",
		"type": "attack", "dmg": 16, "counter": "general",
	},
	"underworld_cmd": {
		"id": "underworld_cmd", "name": "阴司令",
		"desc": "获得8点格挡\n下次攻击伤害+50%%",
		"type": "skill", "block": 8, "effect": "next_atk_boost", "counter": "general",
	},
	# ── 对火焰系克制 ───────────────────────────────
	"wind_fire": {
		"id": "wind_fire", "name": "阴风散火",
		"desc": "清除自身全部燃烧\n每清除1层造成4点伤害",
		"type": "skill", "effect": "clear_burn_dmg", "dmg_per_burn": 4, "counter": "fire",
	},
	"cold_shield": {
		"id": "cold_shield", "name": "寒气护体",
		"desc": "获得8点格挡\n若玩家燃烧层>3则额外+8格挡",
		"type": "block", "block": 8, "bonus_block": 8,
		"condition": "player_burn_gt3", "counter": "fire",
	},
	# ── 对骨刺系克制 ───────────────────────────────
	"bone_pierce": {
		"id": "bone_pierce", "name": "穿骨一击",
		"desc": "造成14点伤害\n无视骨刺反弹",
		"type": "attack", "dmg": 14, "ignore_bone": true, "counter": "bone",
	},
	"soften": {
		"id": "soften", "name": "软化术",
		"desc": "造成6点伤害\n移除玩家4层骨刺",
		"type": "skill", "dmg": 6, "remove_bone": 4, "counter": "bone",
	},
	# ── 对血肉系克制 ───────────────────────────────
	"life_cut": {
		"id": "life_cut", "name": "生机斩断",
		"desc": "造成伤害 = 玩家已损失HP ÷ 3",
		"type": "attack", "effect": "dmg_by_missing_hp", "divisor": 3, "counter": "blood",
	},
	"blood_acc": {
		"id": "blood_acc", "name": "失血加速",
		"desc": "使玩家直接失去5点HP\n（穿透格挡）",
		"type": "skill", "effect": "direct_hp_loss", "value": 5, "counter": "blood",
	},
	# ── 对幽灵系克制 ───────────────────────────────
	"exorcism": {
		"id": "exorcism", "name": "破邪咒",
		"desc": "获得10点格挡\n清除自身易伤效果",
		"type": "skill", "block": 10, "effect": "clear_self_vulnerable", "counter": "ghost",
	},
	"yang_energy": {
		"id": "yang_energy", "name": "阳气冲煞",
		"desc": "造成12点伤害\n本回合玩家易伤加成无效",
		"type": "attack", "dmg": 12, "effect": "negate_vulnerable", "counter": "ghost",
	},
	# ── 对循环系克制 ───────────────────────────────
	"energy_seal": {
		"id": "energy_seal", "name": "能量封印",
		"desc": "造成6点伤害\n玩家下回合最大能量-1",
		"type": "skill", "dmg": 6, "effect": "reduce_player_energy", "counter": "cycle",
	},
	"chain_break": {
		"id": "chain_break", "name": "断链术",
		"desc": "造成10点伤害\n玩家随机丢弃1张手牌",
		"type": "attack", "dmg": 10, "effect": "discard_player_card", "counter": "cycle",
	},
	# ── 特殊牌 ──────────────────────────────────────
	"manifestation": {
		"id": "manifestation", "name": "无常显形",
		"desc": "【能力】每回合开始\n自动获得4点格挡",
		"type": "power", "effect": "per_turn_block", "value": 4, "counter": "general",
	},
	"full_power": {
		"id": "full_power", "name": "黑白无常",
		"desc": "造成22点伤害\n清除玩家所有增益效果",
		"type": "attack", "dmg": 22, "effect": "clear_player_buffs", "counter": "general",
	},
}

# 16张牌的固定索引顺序（与神经网络输出层对应）
const CARD_ORDER: Array = [
	"soul_chain", "dark_fan", "judgment", "underworld_cmd",
	"wind_fire", "cold_shield", "bone_pierce", "soften",
	"life_cut", "blood_acc", "exorcism", "yang_energy",
	"energy_seal", "chain_break", "manifestation", "full_power",
]

static func get_deck() -> Array:
	var deck: Array = []
	for card_id in CARD_ORDER:
		deck.append(card_id)
		# 特殊牌只放1张，其余2张
		if card_id not in ["manifestation", "full_power"]:
			deck.append(card_id)
	return deck
