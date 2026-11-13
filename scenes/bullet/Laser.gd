extends Area2D
## 满层蓄力激光：从玩家枪口向右持续的长条光束。
## 持续期间每 TICK_INTERVAL 对路径上的敌人造成一次伤害（持续灼烧），到 DURATION 自动熄灭。

const DURATION: float = 1.2
const TICK_INTERVAL: float = 0.12
const DAMAGE_PER_TICK: int = 1

var _time: float = 0.0
var _tick: float = 0.0

func _ready() -> void:
	monitoring = false
	visible = false
	set_physics_process(false)

func activate() -> void:
	_time = 0.0
	_tick = 0.0
	visible = true
	monitoring = true
	set_physics_process(true)
	AudioManager.play("laser")

func _physics_process(delta: float) -> void:
	_time += delta
	_tick += delta
	if _tick >= TICK_INTERVAL:
		_tick -= TICK_INTERVAL
		_damage_tick()
	if _time >= DURATION:
		deactivate()

func _damage_tick() -> void:
	for hb in get_overlapping_areas():
		var enemy := hb.get_parent() as BaseEnemy
		if enemy != null:
			enemy.take_damage(DAMAGE_PER_TICK)

func deactivate() -> void:
	monitoring = false
	visible = false
	set_physics_process(false)
