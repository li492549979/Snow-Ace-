extends Area2D

var direction: Vector2 = Vector2.LEFT
var rotation_speed: float = 0.0
var speed: float = 500.0
const _MARGIN: float = 80.0

func _physics_process(delta: float) -> void:
	if rotation_speed != 0.0:
		direction = direction.rotated(rotation_speed * delta)
		rotation = direction.angle()  # 弯转弹贴图跟随弹道
	position += direction * speed * delta
	# 显式边界检查回收（VisibleOnScreenNotifier2D 对从池里瞬移过来的子弹会误判）
	var vr := get_viewport_rect()
	if position.x < -_MARGIN or position.x > vr.size.x + _MARGIN or position.y < -_MARGIN or position.y > vr.size.y + _MARGIN:
		despawn()

func despawn() -> void:
	BulletFactory.release_enemy_bullet(self)
