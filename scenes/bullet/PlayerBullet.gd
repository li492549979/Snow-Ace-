extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 1333.0
var damage: int = 1
const _MARGIN: float = 80.0

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	# 显式边界检查回收（VisibleOnScreenNotifier2D 对从池里瞬移过来的子弹会误判）
	var vr := get_viewport_rect()
	if position.x < -_MARGIN or position.x > vr.size.x + _MARGIN or position.y < -_MARGIN or position.y > vr.size.y + _MARGIN:
		despawn()

func despawn() -> void:
	BulletFactory.release_player_bullet(self)
