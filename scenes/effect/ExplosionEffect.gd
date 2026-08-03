extends Node2D
## 爆炸特效（池化）：_ready 一次性预创建粒子，activate 时重置并跑 Tween，结束后回池。

const PARTICLE_COUNT: int = 10
const LIFE: float = 0.3

var base_color: Color = Color(1.0, 0.6, 0.2)
var _particles: Array[ColorRect] = []
var _tween: Tween = null

func _ready() -> void:
	for i in PARTICLE_COUNT:
		var p := ColorRect.new()
		var s := 8.0
		p.size = Vector2(s, s)
		p.position = -Vector2(s, s) * 0.5
		p.color = base_color
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.visible = false
		add_child(p)
		_particles.append(p)

func activate(pos: Vector2) -> void:
	global_position = pos
	visible = true
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	for p in _particles:
		var angle := randf() * TAU
		var dist := randf_range(33.0, 83.0)
		var target := Vector2(cos(angle), sin(angle)) * dist
		p.position = -p.size * 0.5
		p.modulate = Color.WHITE
		p.visible = true
		_tween.tween_property(p, "position", target, LIFE)
		_tween.tween_property(p, "modulate:a", 0.0, LIFE * 0.66)
	_tween.chain().tween_callback(func() -> void: BulletFactory.release_explosion(self))

func deactivate() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	visible = false
	for p in _particles:
		p.visible = false
