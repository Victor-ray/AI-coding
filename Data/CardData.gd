class_name CardData
extends Resource

# 0=攻击  1=技能  2=能力
@export var type: int = 0
@export var card_name: String = ""
@export var description: String = ""
@export var cost: int = 1
@export var is_x_cost: bool = false   # X费：消耗所有剩余能量
@export var unplayable: bool = false  # 不可主动打出（怨灵缠身）
@export var exhaust: bool = false     # 消耗牌：打出后移出本局

# ── 基础数值 ──────────────────────────────────────
@export var damage: int = 0
@export var block: int = 0
@export var burn: int = 0         # 对敌人施加燃烧层数
@export var bone_spikes: int = 0  # 玩家获得骨刺层数
@export var draw_cards: int = 0
@export var gain_energy: int = 0
@export var heal_self: int = 0    # 正=回血  负=失血
@export var lifesteal: bool = false

# ── 特殊效果 ID ───────────────────────────────────
# 空字符串 = 只有基础效果，无需特殊处理
@export var effect_id: String = ""
