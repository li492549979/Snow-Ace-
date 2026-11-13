extends Node
## 全局运行状态（autoload）。
## 缓存唯一玩家引用，避免各处反复 get_tree().get_nodes_in_group("player")。
## 暂停开关：树暂停时本节点仍需响应暂停键，故为 PROCESS_MODE_ALWAYS；
## 是否允许暂停由当前场景实现 is_pause_allowed() 决定（如结算画面禁止）。
## 最高分持久化：user://save.cfg。

signal pause_changed(paused: bool)

const SAVE_PATH: String = "user://save.cfg"

var player: Node2D = null
var hi_score: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_hi_score()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("is_pause_allowed") and not scene.is_pause_allowed():
		return
	set_paused(not get_tree().paused)

func set_paused(value: bool) -> void:
	get_tree().paused = value
	pause_changed.emit(value)

func submit_score(score: int) -> bool:
	## 结算时调用；刷新最高分并落盘，返回是否为新纪录。
	if score <= hi_score:
		return false
	hi_score = score
	var cfg := ConfigFile.new()
	cfg.set_value("score", "hi_score", hi_score)
	cfg.save(SAVE_PATH)
	return true

func _load_hi_score() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		hi_score = int(cfg.get_value("score", "hi_score", 0))
