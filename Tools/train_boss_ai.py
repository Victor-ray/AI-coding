"""
黑无常神经网络训练脚本
======================
运行方式：python train_boss_ai.py
输出：boss_nn_weights.json（复制到游戏的 user:// 目录）

Windows user:// 目录通常在：
  C:/Users/<你的用户名>/AppData/Roaming/Godot/app_userdata/狱火爬升/
"""

import json
import math
import random

random.seed(42)

# ──────────────────────────────────────────────────────
# 网络结构
# ──────────────────────────────────────────────────────
IN, H1, H2, OUT = 18, 24, 16, 16

CARD_ORDER = [
    "soul_chain", "dark_fan", "judgment", "underworld_cmd",
    "wind_fire", "cold_shield", "bone_pierce", "soften",
    "life_cut", "blood_acc", "exorcism", "yang_energy",
    "energy_seal", "chain_break", "manifestation", "full_power",
]

# ──────────────────────────────────────────────────────
# 矩阵工具
# ──────────────────────────────────────────────────────
def zeros(r, c=None):
    if c is None: return [0.0] * r
    return [[0.0]*c for _ in range(r)]

def randn_mat(r, c, scale=0.25):
    import random
    return [[random.gauss(0, scale) for _ in range(c)] for _ in range(r)]

def randn_vec(n, scale=0.1):
    return [random.gauss(0, scale) for _ in range(n)]

def relu(x): return [max(0.0, v) for v in x]

def softmax(x):
    mx = max(x)
    exps = [math.exp(v - mx) for v in x]
    s = sum(exps)
    return [v/s for v in exps]

def dot_add(x, w, b, use_relu=True):
    out = []
    for j in range(len(b)):
        s = b[j] + sum(x[i]*w[i][j] for i in range(len(x)))
        out.append(s)
    return relu(out) if use_relu else out

def forward(x, w1, b1, w2, b2, wo, bo):
    h1 = dot_add(x, w1, b1, True)
    h2 = dot_add(h1, w2, b2, True)
    out = dot_add(h2, wo, bo, False)
    return softmax(out)

def cross_entropy(probs, target_idx):
    return -math.log(max(1e-9, probs[target_idx]))

# ──────────────────────────────────────────────────────
# 专家系统：根据玩家特征决定最优出牌
# ──────────────────────────────────────────────────────
def expert_decision(feat, boss_hp_ratio, player_hp_ratio):
    """
    feat[0..17]:
      0:atk_r 1:skl_r 2:pow_r 3:cpt
      4:burn_u 5:blk_u 6:bone_u 7:bld_u 8:gst_u 9:cyc_u
      10:aggr 11:early_aggr 12:avg_d 13:avg_b
      14:p_hp_r 15:boss_hp_r 16:turn_r 17:p_blk_r
    """
    scores = {c: 0.0 for c in CARD_ORDER}

    # 基础分：通用牌
    scores["judgment"]      += 0.4
    scores["soul_chain"]    += 0.35
    scores["dark_fan"]      += 0.3
    scores["underworld_cmd"]+= 0.2

    # Boss血量低 → 强攻
    if boss_hp_ratio < 0.35:
        scores["full_power"]    += 1.2
        scores["judgment"]      += 0.5
        scores["life_cut"]      += 0.4

    # Boss血量高 → 能力牌
    if boss_hp_ratio > 0.7:
        scores["manifestation"] += 0.8

    # 玩家激进 → 防御
    if feat[10] > 0.6 or feat[0] > 0.5:
        scores["dark_fan"]      += 0.6
        scores["cold_shield"]   += 0.3
        scores["exorcism"]      += 0.3

    # 玩家防御型 → 穿透
    if feat[13] > 0.5 or feat[5] > 0.3:
        scores["bone_pierce"]   += 0.5
        scores["blood_acc"]     += 0.4

    # 燃烧依赖
    if feat[4] > 0.2:
        scores["wind_fire"]     += feat[4] * 2.0
        scores["cold_shield"]   += feat[4] * 1.5
        scores["soul_chain"]    += feat[4] * 0.8

    # 骨刺依赖
    if feat[6] > 0.15:
        scores["bone_pierce"]   += feat[6] * 2.5
        scores["soften"]        += feat[6] * 2.0

    # 血肉依赖
    if feat[7] > 0.15:
        scores["life_cut"]      += feat[7] * 2.5
        scores["blood_acc"]     += feat[7] * 2.0

    # 幽灵依赖
    if feat[8] > 0.15:
        scores["exorcism"]      += feat[8] * 2.5
        scores["yang_energy"]   += feat[8] * 2.0

    # 循环依赖
    if feat[9] > 0.15:
        scores["energy_seal"]   += feat[9] * 2.5
        scores["chain_break"]   += feat[9] * 2.0

    # 玩家手牌多 → 断链
    if feat[3] > 0.6:
        scores["chain_break"]   += 0.4

    # 玩家格挡高 → 穿透/直扣
    if feat[17] > 0.4:
        scores["blood_acc"]     += 0.5
        scores["bone_pierce"]   += 0.3

    # 找最高分
    best = max(scores, key=lambda c: scores[c])
    return CARD_ORDER.index(best)

# ──────────────────────────────────────────────────────
# 生成训练数据
# ──────────────────────────────────────────────────────
def gen_feature():
    """生成一个随机但合理的特征向量"""
    atk = random.random()
    skl = random.random() * (1 - atk)
    pow_ = max(0, 1 - atk - skl)
    # 效果使用（玩家偏向某一套路）
    deck_type = random.choice(["fire","bone","blood","ghost","cycle","hybrid"])
    burn_u = random.gauss(0.3, 0.15) if deck_type in ["fire","hybrid"] else random.gauss(0.05, 0.05)
    bone_u = random.gauss(0.3, 0.15) if deck_type in ["bone","hybrid"] else random.gauss(0.05, 0.05)
    bld_u  = random.gauss(0.3, 0.15) if deck_type in ["blood","hybrid"] else random.gauss(0.05, 0.05)
    gst_u  = random.gauss(0.3, 0.15) if deck_type in ["ghost","hybrid"] else random.gauss(0.05, 0.05)
    cyc_u  = random.gauss(0.3, 0.15) if deck_type in ["cycle","hybrid"] else random.gauss(0.05, 0.05)
    blk_u  = random.gauss(0.2, 0.1)

    def clamp(v): return max(0.0, min(1.0, v))

    p_hp  = random.random()
    b_hp  = random.random()
    turn  = random.random()
    aggr  = clamp(atk / max(0.01, atk + blk_u))

    return [
        clamp(atk), clamp(skl), clamp(pow_), clamp(random.gauss(0.5, 0.2)),
        clamp(burn_u), clamp(blk_u), clamp(bone_u), clamp(bld_u),
        clamp(gst_u), clamp(cyc_u),
        clamp(aggr), clamp(random.gauss(0.4, 0.2)),
        clamp(random.gauss(0.4, 0.2)), clamp(random.gauss(0.3, 0.15)),
        clamp(p_hp), clamp(b_hp), clamp(turn), clamp(random.gauss(0.2, 0.15)),
    ]

# ──────────────────────────────────────────────────────
# 反向传播（简单SGD）
# ──────────────────────────────────────────────────────
def backward(x, target_idx, w1, b1, w2, b2, wo, bo, lr=0.005):
    # 前向
    h1_pre = [b1[j] + sum(x[i]*w1[i][j] for i in range(len(x))) for j in range(H1)]
    h1 = relu(h1_pre)
    h2_pre = [b2[j] + sum(h1[i]*w2[i][j] for i in range(len(h1))) for j in range(H2)]
    h2 = relu(h2_pre)
    o_pre = [bo[j] + sum(h2[i]*wo[i][j] for i in range(len(h2))) for j in range(OUT)]
    probs = softmax(o_pre)

    loss = cross_entropy(probs, target_idx)

    # 输出层梯度
    d_out = probs[:]
    d_out[target_idx] -= 1.0  # softmax+CE梯度

    # 反向到 wo, bo
    for i in range(H2):
        for j in range(OUT):
            wo[i][j] -= lr * d_out[j] * h2[i]
    for j in range(OUT):
        bo[j] -= lr * d_out[j]

    # 反向到 h2
    d_h2 = [sum(d_out[j]*wo[i][j] for j in range(OUT)) * (1.0 if h2_pre[i] > 0 else 0.0)
            for i in range(H2)]

    # 反向到 w2, b2
    for i in range(H1):
        for j in range(H2):
            w2[i][j] -= lr * d_h2[j] * h1[i]
    for j in range(H2):
        b2[j] -= lr * d_h2[j]

    # 反向到 h1
    d_h1 = [sum(d_h2[j]*w2[i][j] for j in range(H2)) * (1.0 if h1_pre[i] > 0 else 0.0)
            for i in range(H1)]

    # 反向到 w1, b1
    for i in range(IN):
        for j in range(H1):
            w1[i][j] -= lr * d_h1[j] * x[i]
    for j in range(H1):
        b1[j] -= lr * d_h1[j]

    return loss

# ──────────────────────────────────────────────────────
# 初始化权重（Xavier + 领域知识偏置）
# ──────────────────────────────────────────────────────
def init_weights():
    scale1 = math.sqrt(2.0 / IN)
    scale2 = math.sqrt(2.0 / H1)
    scale3 = math.sqrt(2.0 / H2)
    w1 = randn_mat(IN, H1, scale1)
    b1 = zeros(H1)
    w2 = randn_mat(H1, H2, scale2)
    b2 = zeros(H2)
    wo = randn_mat(H2, OUT, scale3)
    # 输出偏置：领域先验
    bo = [0.4, 0.3, 0.4, 0.1,
         -0.5,-0.4,-0.5,-0.5,
         -0.5,-0.5,-0.4,-0.5,
         -0.5,-0.4,-1.2,-0.9]
    return w1, b1, w2, b2, wo, bo

# ──────────────────────────────────────────────────────
# 训练主循环
# ──────────────────────────────────────────────────────
def train():
    print("开始训练黑无常神经网络...")
    w1, b1, w2, b2, wo, bo = init_weights()

    N_EPOCHS = 5000
    N_BATCH  = 64
    total_loss = 0.0

    for epoch in range(N_EPOCHS):
        epoch_loss = 0.0
        for _ in range(N_BATCH):
            feat = gen_feature()
            target = expert_decision(feat, feat[15], feat[14])
            loss = backward(feat, target, w1, b1, w2, b2, wo, bo,
                           lr=0.008 * (0.998 ** epoch))
            epoch_loss += loss
        total_loss = epoch_loss / N_BATCH
        if (epoch + 1) % 500 == 0:
            print(f"  Epoch {epoch+1}/{N_EPOCHS}  Loss={total_loss:.4f}")

    print(f"训练完成！最终Loss={total_loss:.4f}")
    return w1, b1, w2, b2, wo, bo

# ──────────────────────────────────────────────────────
# 测试
# ──────────────────────────────────────────────────────
def test(w1, b1, w2, b2, wo, bo):
    print("\n── 测试专家对比 ──")
    test_cases = [
        {"desc": "火焰系玩家（高燃烧）",   "feat_idx": 4,  "val": 0.7},
        {"desc": "骨刺系玩家（高骨刺）",   "feat_idx": 6,  "val": 0.7},
        {"desc": "血肉系玩家（高失血）",   "feat_idx": 7,  "val": 0.7},
        {"desc": "幽灵系玩家（高幽灵）",   "feat_idx": 8,  "val": 0.7},
        {"desc": "循环系玩家（高循环）",   "feat_idx": 9,  "val": 0.7},
        {"desc": "激进玩家（高攻击）",     "feat_idx": 0,  "val": 0.8},
        {"desc": "防御玩家（高格挡）",     "feat_idx": 5,  "val": 0.7},
        {"desc": "Boss快死了",            "feat_idx": 15, "val": 0.15},
    ]
    correct = 0
    for tc in test_cases:
        feat = [0.33]*18
        feat[tc["feat_idx"]] = tc["val"]
        feat[14] = 0.7  # 玩家血量
        feat[15] = tc.get("boss_hp", 0.7)
        expert = expert_decision(feat, feat[15], feat[14])
        probs = forward(feat, w1, b1, w2, b2, wo, bo)
        nn_pick = probs.index(max(probs))
        match = "✓" if nn_pick == expert else "✗"
        if nn_pick == expert: correct += 1
        print(f"  {match} {tc['desc']}")
        print(f"    专家: {CARD_ORDER[expert]}  NN: {CARD_ORDER[nn_pick]}")
    print(f"\n准确率: {correct}/{len(test_cases)} = {correct/len(test_cases)*100:.0f}%")

# ──────────────────────────────────────────────────────
# 保存权重
# ──────────────────────────────────────────────────────
def save(w1, b1, w2, b2, wo, bo):
    data = {"w1": w1, "b1": b1, "w2": w2, "b2": b2, "w_out": wo, "b_out": bo}
    with open("boss_nn_weights.json", "w") as f:
        json.dump(data, f)
    print("\n权重已保存到 boss_nn_weights.json")
    print("请将此文件复制到：")
    print("  Windows: C:/Users/<用户名>/AppData/Roaming/Godot/app_userdata/狱火爬升/")

if __name__ == "__main__":
    w1, b1, w2, b2, wo, bo = train()
    test(w1, b1, w2, b2, wo, bo)
    save(w1, b1, w2, b2, wo, bo)
