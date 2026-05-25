extends Node
class_name BossAIController

# ══════════════════════════════════════════════════════
# AI决策控制器 —— 协调神经网络与DeepSeek
# ══════════════════════════════════════════════════════

var _nn:      NeuralNetwork
var _tracker: PlayerBehaviorTracker
var _ds:      DeepSeekClient = null

var _ds_result:       String = ""
var _ds_done:         bool   = false
var _current_hand:    Array  = []   # decide() 调用时暂存，供回调使用
var _current_features: Array = []

signal card_decided(card_id: String)

func _ready() -> void:
	_nn      = NeuralNetwork.new()
	_tracker = Global.behavior_tracker

	if Global.use_ai_mode and not Global.deepseek_api_key.is_empty():
		_ds = DeepSeekClient.new()
		_ds.api_key = Global.deepseek_api_key
		add_child(_ds)
		_ds.response_ready.connect(_on_ds_ready)
		_ds.failed.connect(_on_ds_failed)

# ──────────────────────────────────────────────────────
# 主接口：异步选牌，通过 card_decided 信号返回结果
# ──────────────────────────────────────────────────────
func decide(game_state: Dictionary, boss_hand: Array) -> void:
	if boss_hand.is_empty():
		card_decided.emit("judgment"); return

	_current_hand     = boss_hand
	_current_features = _tracker.get_feature_vector(
		game_state.get("player_hp", 80),   game_state.get("player_max_hp", 80),
		game_state.get("boss_hp", 100),    game_state.get("boss_max_hp", 100),
		game_state.get("turn", 1),         game_state.get("player_block", 0),
	)

	if _ds != null:
		# DeepSeek 模式：发送请求，设置超时兜底
		_ds_done   = false
		_ds_result = ""
		var profile := _tracker.get_profile_dict()
		_ds.query(game_state, profile, boss_hand)
		# 2秒超时后强制用NN
		get_tree().create_timer(2.0).timeout.connect(
			func(): if not _ds_done: _fallback_nn(_current_features, _current_hand),
			CONNECT_ONE_SHOT
		)
	else:
		# 纯NN模式：直接同步决策
		var chosen := _nn_pick(_current_features, _current_hand)
		card_decided.emit(chosen)

func _on_ds_ready(card_id: String) -> void:
	if _ds_done: return
	_ds_done   = true
	_ds_result = card_id
	card_decided.emit(card_id)

func _on_ds_failed() -> void:
	# API失败，立即用NN兜底（不等超时）
	if _ds_done: return
	_ds_done = true
	_fallback_nn(_current_features, _current_hand)

func _fallback_nn(features: Array, boss_hand: Array) -> void:
	if _ds_done and not _ds_result.is_empty(): return  # DeepSeek已经回来了
	var chosen := _nn_pick(features, boss_hand)
	_ds_done   = true
	_ds_result = chosen
	card_decided.emit(chosen)

# ──────────────────────────────────────────────────────
# 神经网络选牌（只从手牌中选）
# ──────────────────────────────────────────────────────
func _nn_pick(features: Array, boss_hand: Array) -> String:
	if boss_hand.is_empty(): return "judgment"   # 终极兜底

	var probs := _nn.forward(features)

	# 按手牌过滤，构建局部概率表
	var valid: Dictionary = {}
	for cid in boss_hand:
		var idx := BossCardLibrary.CARD_ORDER.find(cid)
		if idx >= 0:
			valid[cid] = float(probs[idx])

	if valid.is_empty():
		return boss_hand[randi() % boss_hand.size()]  # 手牌不在 CARD_ORDER 里时随机

	# 归一化后采样（温度0.85）
	var sm: float = 0.0
	for v in valid.values(): sm += pow(float(v), 1.0 / 0.85)
	var r := randf() * sm
	var cum: float = 0.0
	for cid in valid:
		cum += pow(float(valid[cid]), 1.0 / 0.85)
		if r <= cum: return cid
	return boss_hand[0]

func get_tracker() -> PlayerBehaviorTracker:
	return _tracker
