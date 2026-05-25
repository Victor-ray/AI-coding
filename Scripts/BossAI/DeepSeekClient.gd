extends Node
class_name DeepSeekClient

# ══════════════════════════════════════════════════════
# DeepSeek API 客户端
# ══════════════════════════════════════════════════════
const API_URL := "https://api.deepseek.com/chat/completions"
const MODEL   := "deepseek-chat"

var api_key:  String = ""
var _http:    HTTPRequest
var _busy:    bool   = false

signal response_ready(card_id: String)
signal failed

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_completed)

func query(game_state: Dictionary, profile: Dictionary, boss_hand: Array) -> void:
	if _busy or api_key.is_empty():
		failed.emit(); return
	_busy = true

	var prompt := _build_prompt(game_state, profile, boss_hand)
	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key,
	])
	var body := JSON.stringify({
		"model": MODEL,
		"messages": [{"role": "user", "content": prompt}],
		"max_tokens": 80,
		"temperature": 0.6,
	})
	var err := _http.request(API_URL, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_busy = false; failed.emit()

func _build_prompt(gs: Dictionary, pp: Dictionary, hand: Array) -> String:
	var hand_list := ""
	for cid in hand:
		var c: Dictionary = BossCardLibrary.CARDS.get(cid, {})
		hand_list += "· %s：%s\n" % [c.get("name","?"), c.get("desc","").replace("\n","，")]

	var burn_level  := "高" if float(pp.get("burn_usage",  0)) > 0.25 else "低"
	var bone_level  := "高" if float(pp.get("bone_usage",  0)) > 0.15 else "低"
	var blood_level := "高" if float(pp.get("blood_usage", 0)) > 0.15 else "低"
	var ghost_level := "高" if float(pp.get("ghost_usage", 0)) > 0.15 else "低"
	var cycle_level := "高" if float(pp.get("cycle_usage", 0)) > 0.15 else "低"
	var aggr_level  := "激进" if float(pp.get("attack_ratio", 0)) > 0.55 else "均衡"

	return """你是中国冥府的黑无常，正在与亡魂进行卡牌博弈。神经网络已分析出玩家习惯，你需据此选择最具针对性的卡牌。

【玩家历史画像（%d局数据）】
出牌风格：%s | 燃烧依赖：%s | 骨刺依赖：%s | 血肉依赖：%s | 幽灵依赖：%s | 循环依赖：%s

【当前战场】
玩家HP：%d/%d，玩家格挡：%d
黑无常HP：%d/%d，第%d回合

【你的手牌】
%s
请直接输出你选择的卡牌名称（如：勾魂索），不要解释。""" % [
		int(pp.get("total_games", 0)),
		aggr_level, burn_level, bone_level, blood_level, ghost_level, cycle_level,
		int(gs.get("player_hp", 80)),   int(gs.get("player_max_hp", 80)),
		int(gs.get("player_block", 0)),
		int(gs.get("boss_hp", 100)),    int(gs.get("boss_max_hp", 100)),
		int(gs.get("turn", 1)),
		hand_list,
	]

func _on_completed(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	if code != 200:
		failed.emit(); return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if not json is Dictionary:
		failed.emit(); return

	var choices = json.get("choices", [])
	if choices.is_empty():
		failed.emit(); return

	var content: String = choices[0].get("message", {}).get("content", "")
	var matched := _match_name(content)
	if matched.is_empty():
		failed.emit()
	else:
		response_ready.emit(matched)

func _match_name(text: String) -> String:
	for cid in BossCardLibrary.CARD_ORDER:
		var cname: String = BossCardLibrary.CARDS[cid].get("name", "")
		if cname in text:
			return cid
	return ""
