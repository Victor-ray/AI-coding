extends Node
class_name BossTauntSystem

# ══════════════════════════════════════════════════════
# 黑无常嘲讽系统
# AI模式：实时调用DeepSeek，根据玩家行为生成嘲讽台词
# 离线模式：从预设台词池随机抽取，避免重复
# ══════════════════════════════════════════════════════

signal taunt_ready(text: String)

# ── 离线台词池 ────────────────────────────────────────
const OFFLINE_TAUNTS := [
	"哟，这点把戏也敢在本使面前耍？",
	"孟婆汤白喝了，连死都不会死。",
	"有点意思……不过也就这点意思。",
	"大闹阎罗殿的本事，就这？",
	"你这执念，倒让本使有些刮目相看。",
	"小孩儿，认输吧，本使不为难你。",
	"为了个妹妹，至于吗？",
	"阳间的事，一个亡魂管不了的。",
	"死都死了，还不服气？",
	"挣扎什么，早晚乖乖入轮回。",
	"嗯……你还真有两下子。",
	"本使见过的亡魂，比你执拗的多的是。",
	"这招倒还算机灵，可惜不够用。",
	"你的心思，本使看得透透的。",
	"小鬼头，骨气倒是有，可惜白费。",
	"好好一个人，非要在无间地狱撒野。",
	"罢了，本使就当陪你走这一遭。",
]

# 玩家卡牌特征 → 针对性嘲讽
const CARD_TYPE_TAUNTS := {
	"fire":  ["玩火的小鬼，在地狱里玩火？", "这把火烧不到本使的。"],
	"bone":  ["骨头架子撑着？有趣。", "骨刺？本使见得多了。"],
	"blood": ["以血祭战？胆子倒大。", "把自己的血当筹码，值得吗？"],
	"ghost": ["幽魂对抗鬼使，自相残杀？", "连自身都是鬼，还想超度别人？"],
	"cycle": ["转来转去的，转晕了吗？", "轮回这东西，你掌控不了的。"],
}

var _http:        HTTPRequest = null
var _busy:        bool        = false
var _last_taunts: Array       = []   # 防止短时间重复

func _ready() -> void:
	if Global.use_ai_mode and not Global.deepseek_api_key.is_empty():
		_http = HTTPRequest.new()
		add_child(_http)
		_http.request_completed.connect(_on_http_response)

# ══════════════════════════════════════════════════════
# 请求一句嘲讽
# ══════════════════════════════════════════════════════
func request_taunt(p_hp: int, p_max_hp: int,
		e_hp: int, e_max_hp: int,
		turn: int, last_card_name: String, deck_type: String) -> void:

	if _http == null or _busy:
		taunt_ready.emit(_pick_offline(deck_type, last_card_name))
		return

	_busy = true

	var sys := (
		"你是黑无常，阴间傲慢戏谑的执法使者，对眼前这个不肯认命的亡魂暗含欣赏。"
		+ "用1到2句话嘲讽对方，称呼为「小孩儿」或「死鬼」。"
		+ "要有古风戏剧感，简短有力，不超过30个字。只输出台词，不加引号、不加说明。"
	)
	var usr := "当前：玩家%d/%dHP，Boss%d/%dHP，第%d回合。玩家刚出了【%s】，使用【%s】系牌组。" % [
		p_hp, p_max_hp, e_hp, e_max_hp, turn, last_card_name, deck_type
	]

	var body := JSON.stringify({
		"model": "deepseek-chat",
		"messages": [
			{"role": "system", "content": sys},
			{"role": "user",   "content": usr},
		],
		"max_tokens": 80,
		"temperature": 0.92,
	})
	var headers := [
		"Content-Type: application/json",
		"Authorization: Bearer " + Global.deepseek_api_key,
	]
	var err := _http.request(
		"https://api.deepseek.com/chat/completions",
		headers, HTTPClient.METHOD_POST, body
	)
	if err != OK:
		_busy = false
		taunt_ready.emit(_pick_offline(deck_type, last_card_name))
		return

	# 3 秒超时兜底
	get_tree().create_timer(3.0).timeout.connect(func():
		if _busy:
			_busy = false
			taunt_ready.emit(_pick_offline(deck_type, last_card_name))
	, CONNECT_ONE_SHOT)

func _on_http_response(_result: int, code: int,
		_headers: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	if code != 200:
		taunt_ready.emit(_pick_offline("", ""))
		return
	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if parsed == null:
		taunt_ready.emit(_pick_offline("", ""))
		return
	var text: String = (
		parsed.get("choices", [{}])[0]
		.get("message", {})
		.get("content", "")
		.strip_edges()
	)
	taunt_ready.emit(text if not text.is_empty() else _pick_offline("", ""))

# ══════════════════════════════════════════════════════
# 离线选词（避免近期重复，结合牌组特征）
# ══════════════════════════════════════════════════════
func _pick_offline(deck_type: String, _last_card: String) -> String:
	# 30% 概率使用针对牌组的专属嘲讽
	var pool: Array = OFFLINE_TAUNTS.duplicate()
	if deck_type in CARD_TYPE_TAUNTS and randf() < 0.30:
		var special: Array = CARD_TYPE_TAUNTS[deck_type]
		pool = special + pool

	# 排除最近说过的
	for t in _last_taunts:
		pool.erase(t)
	if pool.is_empty():
		pool = OFFLINE_TAUNTS.duplicate()

	var pick: String = pool[randi() % pool.size()]
	_last_taunts.append(pick)
	if _last_taunts.size() > 5:
		_last_taunts.remove_at(0)
	return pick
