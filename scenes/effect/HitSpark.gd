extends Node2D
## 命中火花（池化）：玩家子弹命中敌人处的小型闪光，快速放大并淡出。

const LIFE: float = 0.12

var _tween: Tween = null

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	visible = false

func activate(pos: Vector2) -> void:
	global_position = pos
	rotation = randf() * TAU
	scale = Vector2.ONE * 0.4
	modulate = Color(1.0, 0.95, 0.7, 0.9)
	visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "scale", Vector2.ONE * 1.1, LIFE)
	_tween.tween_property(self, "modulate:a", 0.0, LIFE)
	_tween.chain().tween_callback(func() -> void: BulletFactory.release_hit_spark(self))

func deactivate() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	visible = false
