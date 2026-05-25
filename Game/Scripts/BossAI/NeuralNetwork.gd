extends RefCounted
class_name NeuralNetwork

# ══════════════════════════════════════════════════════
# 简单前馈神经网络（推理引擎）
# 架构：18 → 24 → 16 → 16（softmax）
# ══════════════════════════════════════════════════════
const WEIGHTS_PATH := "user://boss_nn_weights.json"
const INPUT_SZ  := 18
const HIDDEN1   := 24
const HIDDEN2   := 16
const OUTPUT_SZ := 16

var _w1:    Array = []
var _b1:    Array = []
var _w2:    Array = []
var _b2:    Array = []
var _w_out: Array = []
var _b_out: Array = []
var _ready: bool  = false

func _init() -> void:
	if FileAccess.file_exists(WEIGHTS_PATH):
		_load()
	else:
		_init_default()
		_save()
	_ready = true

# ──────────────────────────────────────────────────────
# 权重初始化（领域知识编码进偏置，权重小随机）
# ──────────────────────────────────────────────────────
func _init_default() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260523  # 固定种子，可复现
	_w1    = _rand_mat(rng, INPUT_SZ, HIDDEN1,  0.25)
	_b1    = _zeros(HIDDEN1)
	_w2    = _rand_mat(rng, HIDDEN1,  HIDDEN2,  0.25)
	_b2    = _zeros(HIDDEN2)
	_w_out = _rand_mat(rng, HIDDEN2,  OUTPUT_SZ, 0.20)
	# 输出偏置：编码先验知识
	# 顺序对应 BossCardLibrary.CARD_ORDER
	# [soul_chain, dark_fan, judgment, underworld_cmd,
	#  wind_fire, cold_shield, bone_pierce, soften,
	#  life_cut, blood_acc, exorcism, yang_energy,
	#  energy_seal, chain_break, manifestation, full_power]
	_b_out = [
		 0.4,  0.3,  0.4,  0.1,   # 通用牌：中等优先
		-0.6, -0.4, -0.6, -0.5,   # 克制牌：低（靠输入权重激活）
		-0.5, -0.6, -0.4, -0.5,
		-0.5, -0.4, -1.2, -0.9,   # 特殊牌：罕见使用
	]

func _rand_mat(rng: RandomNumberGenerator, rows: int, cols: int, scale: float) -> Array:
	var mat: Array = []
	for _i in rows:
		var row: Array = []
		for _j in cols:
			row.append(rng.randf_range(-scale, scale))
		mat.append(row)
	return mat

func _zeros(sz: int) -> Array:
	var a: Array = []
	for _i in sz: a.append(0.0)
	return a

# ──────────────────────────────────────────────────────
# 文件读写
# ──────────────────────────────────────────────────────
func _load() -> void:
	var f := FileAccess.open(WEIGHTS_PATH, FileAccess.READ)
	if not f: _init_default(); return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if not data is Dictionary: _init_default(); return
	_w1    = data.get("w1",    [])
	_b1    = data.get("b1",    [])
	_w2    = data.get("w2",    [])
	_b2    = data.get("b2",    [])
	_w_out = data.get("w_out", [])
	_b_out = data.get("b_out", [])
	if _w1.is_empty(): _init_default()

func _save() -> void:
	var data := {"w1":_w1,"b1":_b1,"w2":_w2,"b2":_b2,"w_out":_w_out,"b_out":_b_out}
	var f := FileAccess.open(WEIGHTS_PATH, FileAccess.WRITE)
	if not f: return
	f.store_string(JSON.stringify(data))
	f.close()

# ──────────────────────────────────────────────────────
# 前向传播
# ──────────────────────────────────────────────────────
func forward(input: Array) -> Array:
	if not _ready or _w1.is_empty(): return _uniform()
	var h1  := _dense(input, _w1, _b1, true)
	var h2  := _dense(h1,    _w2, _b2, true)
	var out := _dense(h2, _w_out, _b_out, false)
	return _softmax(out)

func _dense(x: Array, w: Array, b: Array, use_relu: bool) -> Array:
	var out: Array = []
	for j in b.size():
		var s: float = float(b[j])
		for i in x.size():
			s += float(x[i]) * float(w[i][j])
		out.append(maxf(0.0, s) if use_relu else s)
	return out

func _softmax(x: Array) -> Array:
	var mx: float = float(x[0])
	for v in x:
		if float(v) > mx: mx = float(v)
	var exps: Array = []
	var sm: float = 0.0
	for v in x:
		var e := exp(float(v) - mx)
		exps.append(e); sm += e
	var out: Array = []
	for e in exps: out.append(float(e) / sm)
	return out

func _uniform() -> Array:
	var a: Array = []
	for _i in OUTPUT_SZ: a.append(1.0 / OUTPUT_SZ)
	return a

# 带温度的概率采样（temperature<1更确定，>1更随机）
func sample(probs: Array, temperature: float = 0.85) -> int:
	var adj: Array = []
	var sm: float = 0.0
	for p in probs:
		var v := pow(maxf(1e-9, float(p)), 1.0 / temperature)
		adj.append(v); sm += v
	var r := randf() * sm
	var cum: float = 0.0
	for i in adj.size():
		cum += float(adj[i])
		if r <= cum: return i
	return OUTPUT_SZ - 1

# 外部调用：更新权重（Python训练后替换weights文件即可）
func reload_weights() -> void:
	if FileAccess.file_exists(WEIGHTS_PATH): _load()
