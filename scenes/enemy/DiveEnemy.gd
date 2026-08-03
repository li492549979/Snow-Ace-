class_name DiveEnemy
extends BaseEnemy

const ENTER_SPEED_X: float = 267.0
const DIVE_SPEED_Y: float = 367.0
const DIVE_ACCEL_Y: float = 667.0
const MAX_DIVE_SPEED: float = 633.0
const SHOOT_COOLDOWN: float = 1.5

var dive_vy: float = 0.0
var shoot_timer: float = 0.0
var has_dived: bool = false

func _ready() -> void:
	max_hp = 2
	score_value = 150
	super()
	shoot_timer = randf_range(0.3, SHOOT_COOLDOWN)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	velocity.x = -ENTER_SPEED_X

	if not has_dived and position.x < get_viewport_rect().size.x * 0.65:
		has_dived = true

	if has_dived:
		dive_vy = min(dive_vy + DIVE_ACCEL_Y * delta, MAX_DIVE_SPEED)
		velocity.y = dive_vy
	else:
		velocity.y = DIVE_SPEED_Y * 0.3

	move_and_slide()

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = SHOOT_COOLDOWN
		_fire()

	if position.y > get_viewport_rect().size.y + 67.0 or position.x < -100.0:
		queue_free()

func _fire() -> void:
	BulletFactory.spawn_enemy_bullet(
		$BulletSpawn.global_position, Vector2(-1.0, 0.5).normalized())