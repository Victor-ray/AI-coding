class_name CardLibrary

# ══════════════════════════════════════════════════════
# 火焰卡组
# ══════════════════════════════════════════════════════
static func c_zhuo_re_da_ji() -> CardData:
	var c := CardData.new()
	c.card_name = "灼热打击"; c.type = 0; c.cost = 1
	c.damage = 6; c.burn = 2
	c.description = "造成6点伤害\n施加2层燃烧"
	return c

static func c_yan_hu_dun() -> CardData:
	var c := CardData.new()
	c.card_name = "炎护盾"; c.type = 1; c.cost = 1
	c.block = 8
	c.description = "获得8点格挡"
	return c

static func c_yin_huo_shao_shen() -> CardData:
	var c := CardData.new()
	c.card_name = "引火烧身"; c.type = 1; c.cost = 1
	c.heal_self = -2; c.burn = 5
	c.description = "失去2点HP\n对敌施加5层燃烧"
	return c

static func c_ming_he_huo_zhong() -> CardData:
	var c := CardData.new()
	c.card_name = "冥河火种"; c.type = 1; c.cost = 1
	c.burn = 3; c.effect_id = "ming_he"
	c.description = "施加3层燃烧\n生成一张灰烬到手牌"
	return c

static func c_fei_e_pu_huo() -> CardData:
	var c := CardData.new()
	c.card_name = "飞蛾扑火"; c.type = 0; c.cost = 1
	c.damage = 5; c.effect_id = "fei_e"
	c.description = "造成5点伤害\n若敌人有燃烧则额外造成3点伤害"
	return c

static func c_jiao_tu_zhan_shu() -> CardData:
	var c := CardData.new()
	c.card_name = "焦土战术"; c.type = 1; c.cost = 2
	c.effect_id = "jiao_tu"
	c.description = "消耗所有燃烧层数\n每层造成2点伤害"
	return c

static func c_rong_yan_hu_jia() -> CardData:
	var c := CardData.new()
	c.card_name = "熔岩护甲"; c.type = 2; c.cost = 3
	c.effect_id = "pow_lava_enchant"
	c.description = "【能力】每当你受到伤害\n对敌施加1层燃烧"
	return c

static func c_huo_yan_pen_she() -> CardData:
	var c := CardData.new()
	c.card_name = "火焰喷射"; c.type = 0; c.cost = 2
	c.damage = 15
	c.description = "造成15点伤害"
	return c

static func c_lie_huo_chong_sheng() -> CardData:
	var c := CardData.new()
	c.card_name = "烈火重生"; c.type = 1; c.cost = 2
	c.exhaust = true; c.heal_self = 10
	c.effect_id = "lie_huo_chong_sheng"
	c.description = "回复10点HP\n消除所有格挡（消耗）"
	return c

static func c_lian_yu_lie_yan() -> CardData:
	var c := CardData.new()
	c.card_name = "炼狱烈焰"; c.type = 0; c.cost = 3
	c.damage = 20; c.effect_id = "lian_yu"
	c.description = "造成20点伤害\n若敌人有燃烧则再造成10点伤害"
	return c

# 废牌：冥河火种生成
static func c_hui_jin() -> CardData:
	var c := CardData.new()
	c.card_name = "灰烬"; c.type = 1; c.cost = 0
	c.effect_id = "hui_jin"
	c.description = "（废牌）无任何效果"
	return c

# ══════════════════════════════════════════════════════
# 骨刺卡组
# ══════════════════════════════════════════════════════
static func c_gu_ci_tu_xi() -> CardData:
	var c := CardData.new()
	c.card_name = "骨刺突袭"; c.type = 0; c.cost = 1
	c.damage = 5; c.bone_spikes = 2
	c.description = "造成5点伤害\n获得2层骨刺"
	return c

static func c_bai_gu_zhi_dun() -> CardData:
	var c := CardData.new()
	c.card_name = "白骨之盾"; c.type = 1; c.cost = 1
	c.block = 5; c.bone_spikes = 2
	c.description = "获得5点格挡\n获得2层骨刺"
	return c

static func c_gu_lin_chuan_ci() -> CardData:
	var c := CardData.new()
	c.card_name = "骨林穿刺"; c.type = 0; c.cost = 2
	c.damage = 14
	c.description = "造成14点伤害"
	return c

static func c_qiang_hua_gu_ci() -> CardData:
	var c := CardData.new()
	c.card_name = "强化骨刺"; c.type = 1; c.cost = 1
	c.bone_spikes = 5
	c.description = "获得5层骨刺"
	return c

static func c_sui_gu_da_ji() -> CardData:
	var c := CardData.new()
	c.card_name = "碎骨打击"; c.type = 0; c.cost = 2
	c.damage = 8; c.effect_id = "sui_gu"
	c.description = "造成8点伤害\n额外造成等同骨刺层数的伤害"
	return c

static func c_gu_ci_fan_tan() -> CardData:
	var c := CardData.new()
	c.card_name = "骨刺反弹"; c.type = 1; c.cost = 1
	c.exhaust = true; c.effect_id = "gu_ci_fan_tan"
	c.description = "将所有骨刺层数转化为直接伤害（消耗）"
	return c

static func c_sen_luo_gu_zhen() -> CardData:
	var c := CardData.new()
	c.card_name = "森罗骨阵"; c.type = 2; c.cost = 3
	c.effect_id = "pow_bone_forest"
	c.description = "【能力】每回合开始\n获得等同当前回合数的骨刺层数"
	return c

static func c_gu_ci_fan_ji() -> CardData:
	var c := CardData.new()
	c.card_name = "骨刺反击"; c.type = 1; c.cost = 2
	c.block = 8; c.bone_spikes = 3
	c.description = "获得8点格挡\n获得3层骨刺"
	return c

static func c_gu_wang_zhen_nu() -> CardData:
	var c := CardData.new()
	c.card_name = "骨王震怒"; c.type = 0; c.cost = 3
	c.damage = 18; c.bone_spikes = 4
	c.description = "造成18点伤害\n获得4层骨刺"
	return c

static func c_bai_gu_fu_su() -> CardData:
	var c := CardData.new()
	c.card_name = "白骨复苏"; c.type = 1; c.cost = 1
	c.heal_self = 8
	c.description = "回复8点HP"
	return c

# ══════════════════════════════════════════════════════
# 血肉卡组
# ══════════════════════════════════════════════════════
static func c_shi_xue_da_ji() -> CardData:
	var c := CardData.new()
	c.card_name = "嗜血打击"; c.type = 0; c.cost = 1
	c.damage = 7; c.lifesteal = true
	c.description = "造成7点伤害\n吸取等量HP"
	return c

static func c_shi_xue_chong_ji() -> CardData:
	var c := CardData.new()
	c.card_name = "失血冲击"; c.type = 0; c.cost = 1
	c.damage = 10; c.heal_self = -4
	c.description = "失去4点HP\n造成10点伤害"
	return c

static func c_rou_dun_qiang_hua() -> CardData:
	var c := CardData.new()
	c.card_name = "肉盾强化"; c.type = 1; c.cost = 1
	c.heal_self = -3; c.block = 12
	c.description = "失去3点HP\n获得12点格挡"
	return c

static func c_xue_rou_yu_he() -> CardData:
	var c := CardData.new()
	c.card_name = "血肉愈合"; c.type = 1; c.cost = 1
	c.heal_self = 6
	c.description = "回复6点HP"
	return c

static func c_yi_xue_ji_xue() -> CardData:
	var c := CardData.new()
	c.card_name = "以血祭血"; c.type = 1; c.cost = 0
	c.exhaust = true; c.heal_self = -5; c.effect_id = "yi_xue_ji_xue"
	c.description = "失去5点HP\n对敌造成15点直接伤害（消耗）"
	return c

static func c_xue_rou_ku_ruo() -> CardData:
	var c := CardData.new()
	c.card_name = "血肉苦弱"; c.type = 2; c.cost = 2
	c.effect_id = "pow_blood_flesh"
	c.description = "【能力】每当你主动失去HP\n对敌造成等量直接伤害"
	return c

static func c_xian_xue_fei_jian() -> CardData:
	var c := CardData.new()
	c.card_name = "鲜血飞溅"; c.type = 0; c.cost = 1
	c.damage = 4; c.effect_id = "xian_xue_fei_jian"
	c.description = "造成4点伤害\n再造成等同失血量的伤害（最多12）"
	return c

static func c_xian_xue_qiang_hua() -> CardData:
	var c := CardData.new()
	c.card_name = "献血强化"; c.type = 1; c.cost = 2
	c.heal_self = -8; c.effect_id = "xian_xue_qiang_hua"
	c.description = "失去8点HP\n永久获得4点攻击加成"
	return c

static func c_xiang_si_er_sheng() -> CardData:
	var c := CardData.new()
	c.card_name = "向死而生"; c.type = 1; c.cost = 3
	c.exhaust = true; c.effect_id = "xiang_si_er_sheng"
	c.description = "将HP降至1\n下回合开始时获得30点格挡（消耗）"
	return c

static func c_bo_pi_zhi_shu() -> CardData:
	var c := CardData.new()
	c.card_name = "剥皮之术"; c.type = 0; c.cost = 2
	c.damage = 10; c.effect_id = "bo_pi_zhi_shu"
	c.description = "造成10点伤害\n清除敌人所有格挡"
	return c

# ══════════════════════════════════════════════════════
# 幽灵卡组
# ══════════════════════════════════════════════════════
static func c_you_hun_da_ji() -> CardData:
	var c := CardData.new()
	c.card_name = "幽魂打击"; c.type = 0; c.cost = 1
	c.damage = 7
	c.description = "造成7点伤害"
	return c

static func c_ling_ti_shan_bi() -> CardData:
	var c := CardData.new()
	c.card_name = "灵体闪避"; c.type = 1; c.cost = 1
	c.block = 9
	c.description = "获得9点格挡"
	return c

static func c_yuan_ling_chan_shen() -> CardData:
	var c := CardData.new()
	c.card_name = "怨灵缠身"; c.type = 1; c.cost = 0
	c.unplayable = true; c.effect_id = "yuan_ling_chan_shen"
	c.description = "（废牌）无法主动打出\n被弃牌时对敌施加2层易伤"
	return c

static func c_suo_hun_suo() -> CardData:
	var c := CardData.new()
	c.card_name = "索魂锁"; c.type = 1; c.cost = 1
	c.effect_id = "suo_hun_suo"
	c.description = "对敌施加3层易伤"
	return c

static func c_you_ming_ping_zhang() -> CardData:
	var c := CardData.new()
	c.card_name = "幽冥屏障"; c.type = 1; c.cost = 2
	c.block = 15
	c.description = "获得15点格挡"
	return c

static func c_ling_hun_ji_qu() -> CardData:
	var c := CardData.new()
	c.card_name = "灵魂汲取"; c.type = 0; c.cost = 1
	c.damage = 5; c.draw_cards = 2
	c.description = "造成5点伤害\n抽2张牌"
	return c

static func c_yin_hun_bu_san() -> CardData:
	var c := CardData.new()
	c.card_name = "阴魂不散"; c.type = 0; c.cost = 2
	c.damage = 12; c.effect_id = "yin_hun_bu_san"
	c.description = "造成12点伤害\n若敌人有易伤则再造成6点伤害"
	return c

static func c_xu_kong_yin_ying() -> CardData:
	var c := CardData.new()
	c.card_name = "虚空阴影"; c.type = 2; c.cost = 3
	c.effect_id = "pow_void_shadow"
	c.description = "【能力】每回合开始\n对敌施加1层易伤"
	return c

static func c_you_ling_jiu_chan() -> CardData:
	var c := CardData.new()
	c.card_name = "幽灵纠缠"; c.type = 1; c.cost = 1
	c.draw_cards = 1; c.effect_id = "you_ling_jiu_chan"
	c.description = "将一张怨灵缠身加入手牌\n抽1张牌"
	return c

static func c_bi_an_hua_kai() -> CardData:
	var c := CardData.new()
	c.card_name = "彼岸花开"; c.type = 2; c.cost = 2
	c.effect_id = "pow_biangan"
	c.description = "【能力】每回合开始\n每张被弃置的怨灵缠身使你额外抽1张牌"
	return c

# ══════════════════════════════════════════════════════
# 循环卡组
# ══════════════════════════════════════════════════════
static func c_lun_hui_da_ji() -> CardData:
	var c := CardData.new()
	c.card_name = "轮回打击"; c.type = 0; c.cost = 0
	c.damage = 4; c.draw_cards = 1
	c.description = "造成4点伤害\n抽1张牌"
	return c

static func c_ling_ji_yi_dong() -> CardData:
	var c := CardData.new()
	c.card_name = "灵机一动"; c.type = 1; c.cost = 0
	c.draw_cards = 2; c.gain_energy = 1
	c.description = "抽2张牌\n获得1点能量"
	return c

static func c_xiao_hao_lun_zhuan() -> CardData:
	var c := CardData.new()
	c.card_name = "消耗轮转"; c.type = 1; c.cost = 1
	c.exhaust = true; c.draw_cards = 3
	c.description = "抽3张牌（消耗）"
	return c

static func c_lian_huan_chong_ji() -> CardData:
	var c := CardData.new()
	c.card_name = "连环冲击"; c.type = 0; c.cost = 1
	c.damage = 3; c.effect_id = "lian_huan_chong_ji"
	c.description = "造成3点伤害\n若本回合已打出≥3张牌则再造成3点伤害"
	return c

static func c_liu_dao_lian_dan() -> CardData:
	var c := CardData.new()
	c.card_name = "六道连弹"; c.type = 0; c.cost = 2
	c.effect_id = "liu_dao_lian_dan"
	c.description = "造成6×2点伤害（共12点）\n每回合开始自动从弃牌堆回到牌堆"
	return c

static func c_wu_xian_xun_huan() -> CardData:
	var c := CardData.new()
	c.card_name = "无限循环"; c.type = 1; c.cost = 1
	c.exhaust = true; c.gain_energy = 3; c.draw_cards = 2
	c.description = "获得3点能量\n抽2张牌（消耗）"
	return c

static func c_ji_feng_lian_zhan() -> CardData:
	var c := CardData.new()
	c.card_name = "疾风连斩"; c.type = 0; c.cost = 1
	c.effect_id = "ji_feng_lian_zhan"
	c.description = "抽1张牌\n造成手牌中每张0费攻击牌×3的伤害"
	return c

static func c_shun_xi_wan_bian() -> CardData:
	var c := CardData.new()
	c.card_name = "瞬息万变"; c.type = 1; c.cost = 0
	c.draw_cards = 1; c.effect_id = "shun_xi_wan_bian"
	c.description = "抽1张牌\n若抽到的牌费用为0则再抽1张牌"
	return c

static func c_neng_liang_yin_bao() -> CardData:
	var c := CardData.new()
	c.card_name = "能量引爆"; c.type = 0; c.cost = 0
	c.is_x_cost = true; c.effect_id = "neng_liang_yin_bao"
	c.description = "消耗所有能量\n每点能量造成8点伤害"
	return c

static func c_gong_ming_lian_ji() -> CardData:
	var c := CardData.new()
	c.card_name = "共鸣连击"; c.type = 0; c.cost = 2
	c.effect_id = "gong_ming_lian_ji"
	c.description = "造成本回合已打出牌数×4的伤害"
	return c

# ══════════════════════════════════════════════════════
# 牌组构建器
# ══════════════════════════════════════════════════════
static func get_fire_deck() -> Array:
	return [
		c_zhuo_re_da_ji(), c_zhuo_re_da_ji(), c_zhuo_re_da_ji(),
		c_yan_hu_dun(), c_yan_hu_dun(),
		c_yin_huo_shao_shen(), c_yin_huo_shao_shen(),
		c_ming_he_huo_zhong(),
		c_fei_e_pu_huo(), c_fei_e_pu_huo(),
		c_jiao_tu_zhan_shu(),
		c_rong_yan_hu_jia(),
		c_huo_yan_pen_she(),
		c_lie_huo_chong_sheng(),
		c_lian_yu_lie_yan(),
	]

static func get_bone_deck() -> Array:
	return [
		c_gu_ci_tu_xi(), c_gu_ci_tu_xi(), c_gu_ci_tu_xi(),
		c_bai_gu_zhi_dun(), c_bai_gu_zhi_dun(),
		c_gu_lin_chuan_ci(),
		c_qiang_hua_gu_ci(), c_qiang_hua_gu_ci(),
		c_sui_gu_da_ji(),
		c_gu_ci_fan_tan(),
		c_sen_luo_gu_zhen(),
		c_gu_ci_fan_ji(),
		c_gu_wang_zhen_nu(),
		c_bai_gu_fu_su(), c_bai_gu_fu_su(),
	]

static func get_blood_deck() -> Array:
	return [
		c_shi_xue_da_ji(), c_shi_xue_da_ji(), c_shi_xue_da_ji(),
		c_shi_xue_chong_ji(), c_shi_xue_chong_ji(),
		c_rou_dun_qiang_hua(), c_rou_dun_qiang_hua(),
		c_xue_rou_yu_he(),
		c_yi_xue_ji_xue(),
		c_xue_rou_ku_ruo(),
		c_xian_xue_fei_jian(), c_xian_xue_fei_jian(),
		c_xian_xue_qiang_hua(),
		c_xiang_si_er_sheng(),
		c_bo_pi_zhi_shu(),
	]

static func get_ghost_deck() -> Array:
	return [
		c_you_hun_da_ji(), c_you_hun_da_ji(), c_you_hun_da_ji(),
		c_ling_ti_shan_bi(), c_ling_ti_shan_bi(),
		c_suo_hun_suo(), c_suo_hun_suo(),
		c_you_ming_ping_zhang(),
		c_ling_hun_ji_qu(), c_ling_hun_ji_qu(),
		c_yin_hun_bu_san(),
		c_xu_kong_yin_ying(),
		c_you_ling_jiu_chan(),
		c_bi_an_hua_kai(),
	]

static func get_cycle_deck() -> Array:
	return [
		c_lun_hui_da_ji(), c_lun_hui_da_ji(), c_lun_hui_da_ji(),
		c_ling_ji_yi_dong(), c_ling_ji_yi_dong(),
		c_xiao_hao_lun_zhuan(),
		c_lian_huan_chong_ji(), c_lian_huan_chong_ji(),
		c_liu_dao_lian_dan(),
		c_wu_xian_xun_huan(),
		c_ji_feng_lian_zhan(),
		c_shun_xi_wan_bian(), c_shun_xi_wan_bian(),
		c_neng_liang_yin_bao(),
		c_gong_ming_lian_ji(),
	]

# ══════════════════════════════════════════════════════
# 战斗奖励牌池（每套卡组所有非废牌）
# ══════════════════════════════════════════════════════
static func get_reward_pool(deck: String) -> Array:
	match deck:
		"fire": return [
			c_zhuo_re_da_ji(), c_yan_hu_dun(), c_yin_huo_shao_shen(),
			c_ming_he_huo_zhong(), c_fei_e_pu_huo(), c_jiao_tu_zhan_shu(),
			c_rong_yan_hu_jia(), c_huo_yan_pen_she(),
			c_lie_huo_chong_sheng(), c_lian_yu_lie_yan(),
		]
		"bone": return [
			c_gu_ci_tu_xi(), c_bai_gu_zhi_dun(), c_gu_lin_chuan_ci(),
			c_qiang_hua_gu_ci(), c_sui_gu_da_ji(), c_gu_ci_fan_tan(),
			c_sen_luo_gu_zhen(), c_gu_ci_fan_ji(),
			c_gu_wang_zhen_nu(), c_bai_gu_fu_su(),
		]
		"blood": return [
			c_shi_xue_da_ji(), c_shi_xue_chong_ji(), c_rou_dun_qiang_hua(),
			c_xue_rou_yu_he(), c_yi_xue_ji_xue(), c_xue_rou_ku_ruo(),
			c_xian_xue_fei_jian(), c_xian_xue_qiang_hua(),
			c_xiang_si_er_sheng(), c_bo_pi_zhi_shu(),
		]
		"ghost": return [
			c_you_hun_da_ji(), c_ling_ti_shan_bi(), c_suo_hun_suo(),
			c_you_ming_ping_zhang(), c_ling_hun_ji_qu(), c_yin_hun_bu_san(),
			c_xu_kong_yin_ying(), c_you_ling_jiu_chan(), c_bi_an_hua_kai(),
		]
		"cycle": return [
			c_lun_hui_da_ji(), c_ling_ji_yi_dong(), c_xiao_hao_lun_zhuan(),
			c_lian_huan_chong_ji(), c_liu_dao_lian_dan(), c_wu_xian_xun_huan(),
			c_ji_feng_lian_zhan(), c_shun_xi_wan_bian(),
			c_neng_liang_yin_bao(), c_gong_ming_lian_ji(),
		]
	return []

# ══════════════════════════════════════════════════════
# 初始卡组（每流派5张基础卡）
# ══════════════════════════════════════════════════════
static func get_starting_deck(deck: String) -> Array:
	match deck:
		"fire": return [
			c_zhuo_re_da_ji(), c_zhuo_re_da_ji(), c_zhuo_re_da_ji(),   # 灼热打击 x3
			c_yan_hu_dun(), c_yan_hu_dun(), c_yan_hu_dun(),              # 炎护盾 x3
			c_fei_e_pu_huo(), c_fei_e_pu_huo(), c_fei_e_pu_huo(),        # 飞蛾扑火 x3
			c_huo_yan_pen_she(), c_huo_yan_pen_she(), c_huo_yan_pen_she(), # 火焰喷射 x3
			c_yin_huo_shao_shen(), c_yin_huo_shao_shen(), c_yin_huo_shao_shen(), # 引火烧身 x3
		]
		"bone": return [
			c_gu_ci_tu_xi(), c_gu_ci_tu_xi(), c_gu_ci_tu_xi(),           # 骨刺突袭 x3
			c_bai_gu_zhi_dun(), c_bai_gu_zhi_dun(), c_bai_gu_zhi_dun(),  # 白骨之盾 x3
			c_gu_ci_fan_ji(), c_gu_ci_fan_ji(), c_gu_ci_fan_ji(),        # 骨刺反击 x3
			c_gu_wang_zhen_nu(), c_gu_wang_zhen_nu(), c_gu_wang_zhen_nu(), # 骨王震怒 x3
			c_bai_gu_fu_su(), c_bai_gu_fu_su(), c_bai_gu_fu_su(),        # 白骨复苏 x3
		]
		"blood": return [
			c_shi_xue_da_ji(), c_shi_xue_da_ji(), c_shi_xue_da_ji(),     # 嗜血打击 x3
			c_rou_dun_qiang_hua(), c_rou_dun_qiang_hua(), c_rou_dun_qiang_hua(), # 肉盾强化 x3
			c_xiang_si_er_sheng(), c_xiang_si_er_sheng(), c_xiang_si_er_sheng(), # 向死而生 x3
			c_bo_pi_zhi_shu(), c_bo_pi_zhi_shu(), c_bo_pi_zhi_shu(),     # 剥皮之术 x3
			c_xue_rou_yu_he(), c_xue_rou_yu_he(), c_xue_rou_yu_he(),     # 血肉愈合 x3
		]
		"ghost": return [
			c_you_hun_da_ji(), c_you_hun_da_ji(), c_you_hun_da_ji(),     # 幽魂打击 x3
			c_ling_ti_shan_bi(), c_ling_ti_shan_bi(), c_ling_ti_shan_bi(), # 灵体闪避 x3
			c_suo_hun_suo(), c_suo_hun_suo(), c_suo_hun_suo(),           # 索魂锁 x3
			c_ling_hun_ji_qu(), c_ling_hun_ji_qu(), c_ling_hun_ji_qu(),  # 灵魂汲取 x3
			c_yuan_ling_chan_shen(), c_yuan_ling_chan_shen(), c_yuan_ling_chan_shen(), # 怨灵缠身 x3
		]
		"cycle": return [
			c_lun_hui_da_ji(), c_lun_hui_da_ji(), c_lun_hui_da_ji(),     # 轮回打击 x3
			c_ling_ji_yi_dong(), c_ling_ji_yi_dong(), c_ling_ji_yi_dong(), # 灵机一动 x3
			c_liu_dao_lian_dan(), c_liu_dao_lian_dan(), c_liu_dao_lian_dan(), # 六道连弹 x3
			c_gong_ming_lian_ji(), c_gong_ming_lian_ji(), c_gong_ming_lian_ji(), # 共鸣连击 x3
			c_yi_xue_ji_xue(), c_yi_xue_ji_xue(), c_yi_xue_ji_xue(),     # 以血祭血 x3
		]
	return []

# ══════════════════════════════════════════════════════
# 高级卡池（初始卡之外的卡，用于幽冥秘卷）
# ══════════════════════════════════════════════════════
static func get_advanced_pool(deck: String) -> Array:
	match deck:
		"fire": return [
			c_yin_huo_shao_shen(), # 引火烧身
			c_ming_he_huo_zhong(), # 冥河火种
			c_jiao_tu_zhan_shu(), # 焦土战术
			c_rong_yan_hu_jia(),  # 熔岩护甲
			c_lie_huo_chong_sheng(), # 烈火重生
			c_lian_yu_lie_yan(),   # 炼狱烈焰
		]
		"bone": return [
			c_gu_lin_chuan_ci(),  # 骨林穿刺
			c_qiang_hua_gu_ci(),  # 强化骨刺
			c_sui_gu_da_ji(),     # 碎骨打击
			c_gu_ci_fan_tan(),    # 骨刺反弹
			c_sen_luo_gu_zhen(),  # 森罗骨阵
			c_bai_gu_fu_su(),     # 白骨复苏
		]
		"blood": return [
			c_shi_xue_chong_ji(), # 失血冲击
			c_xue_rou_yu_he(),   # 血肉愈合
			c_yi_xue_ji_xue(),   # 以血祭血
			c_xue_rou_ku_ruo(),   # 血肉苦弱
			c_xian_xue_fei_jian(), # 鲜血飞溅
			c_xian_xue_qiang_hua(), # 献血强化
		]
		"ghost": return [
			c_you_ming_ping_zhang(), # 幽冥屏障
			c_yin_hun_bu_san(),    # 阴魂不散
			c_xu_kong_yin_ying(),  # 虚空阴影
			c_you_ling_jiu_chan(), # 幽灵纠缠
			c_bi_an_hua_kai(),     # 彼岸花开
			c_yuan_ling_chan_shen(), # 怨灵缠身
		]
		"cycle": return [
			c_xiao_hao_lun_zhuan(), # 消耗轮转
			c_lian_huan_chong_ji(), # 连环冲击
			c_wu_xian_xun_huan(),  # 无限循环
			c_ji_feng_lian_zhan(), # 疾风连斩
			c_shun_xi_wan_bian(),  # 瞬息万变
			c_neng_liang_yin_bao(), # 能量引爆
		]
	return []

# ══════════════════════════════════════════════════════
# 从高级卡池抽取3张未解锁的卡（幽冥秘卷用）
# ══════════════════════════════════════════════════════
static func draw_advanced_cards(deck: String, unlocked: Array) -> Array:
	var pool: Array = get_advanced_pool(deck)
	var available: Array = []
	for card in pool:
		var is_unlocked := false
		for u in unlocked:
			if u.card_name == card.card_name:
				is_unlocked = true
				break
		if not is_unlocked:
			available.append(card)
	# 随机抽3张
	available.shuffle()
	var count := mini(3, available.size())
	return available.slice(0, count)
