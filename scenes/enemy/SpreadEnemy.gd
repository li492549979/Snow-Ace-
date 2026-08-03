class_name SpreadEnemy
extends BaseEnemy
## 散射兵：从右进入→悬停（x≈0.72W）→周期性前向 3 连扇→驻留后向左撤离。

const ENTER_SPEED: float = 200.0
const STOP_X_RATIO: float = 0.72
const SHOOT_COOLDOWN: float = 1.6
const DWELL_TIME: float = 7.0
const DEPART_SPEED: float = 320.0
const SPREAD: float = 0.5

var stop_x: float
var is_positioning: bool = true
var departing: bool = false
var dwell_timer: float = 0.0
var shoot_timer: float = 0.0

func _ready() -> void:
	max_hp = 4
	score_value = 200
	super()
	stop_x = get_viewport_rect().size.x * STOP_X_RATIO
	shoot_timer = randf_range(0.8, SHOOT_COOLDOWN)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_positioning:
		velocity.x = -ENTER_SPEED
		velocity.y = 0.0
		if position.x <= stop_x:
			position.x = stop_x
			is_positioning = false
	elif departing:
		velocity.x = -DEPART_SPEED
		velocity.y = 0.0
	else:
		velocity = Vector2.ZERO
		dwell_timer += delta
		if dwell_timer >= DWELL_TIME:
			departing = true

	move_and_slide()

	if not is_positioning and not departing:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			shoot_timer = SHOOT_COOLDOWN
			_fire_spread()

	if position.x < -100.0:
		queue_free()

func _fire_spread() -> void:
	BulletFactory.fire_nway($BulletSpawn.global_position, Vector2.LEFT, 3, SPREAD, 500.0)
