class_name FormationEnemy
extends BaseEnemy

const MOVE_SPEED: float = 233.0
const SHOOT_COOLDOWN: float = 2.5
const SINE_AMPLITUDE: float = 42.0
const SINE_SPEED: float = 3.0

var shoot_timer: float = 0.0
var time_alive: float = 0.0
var base_y: float = 0.0

func _ready() -> void:
	max_hp = 2
	score_value = 120
	super()
	base_y = position.y
	shoot_timer = randf_range(0.8, SHOOT_COOLDOWN)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	velocity.x = -MOVE_SPEED
	move_and_slide()

	time_alive += delta
	position.y = base_y + sin(time_alive * SINE_SPEED) * SINE_AMPLITUDE

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = SHOOT_COOLDOWN
		_fire()

	if position.x < -100.0:
		queue_free()

func _fire() -> void:
	BulletFactory.spawn_enemy_bullet($BulletSpawn.global_position, Vector2.LEFT)