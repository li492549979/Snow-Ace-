class_name BasicEnemy
extends BaseEnemy

const MOVE_SPEED: float = 200.0
const SHOOT_COOLDOWN: float = 2.0

var shoot_timer: float = 0.0

func _ready() -> void:
	max_hp = 3
	score_value = 100
	super()
	shoot_timer = randf_range(0.5, SHOOT_COOLDOWN)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	velocity.x = -MOVE_SPEED
	move_and_slide()
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = SHOOT_COOLDOWN
		_fire()
	if position.x < -100.0:
		queue_free()

func _fire() -> void:
	BulletFactory.spawn_enemy_bullet($BulletSpawn.global_position, Vector2.LEFT)