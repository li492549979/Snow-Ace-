class_name RingShooterEnemy
extends BaseEnemy
## 环形射手：从右侧进入，停位后周期性发射旋转的 12 发环形弹幕。

const ENTER_SPEED: float = 167.0
const STOP_X_RATIO: float = 0.78
const SHOOT_COOLDOWN: float = 2.2
const RING_COUNT: int = 12
const DWELL_TIME: float = 8.0
const DEPART_SPEED: float = 300.0

var stop_x: float
var is_positioning: bool = true
var departing: bool = false
var dwell_timer: float = 0.0
var shoot_timer: float = 0.0
var ring_angle: float = 0.0

func _ready() -> void:
	max_hp = 6
	score_value = 250
	super()
	stop_x = get_viewport_rect().size.x * STOP_X_RATIO
	shoot_timer = randf_range(1.0, SHOOT_COOLDOWN)

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
			_fire_ring()

	if position.x < -100.0:
		queue_free()

func _fire_ring() -> void:
	BulletFactory.fire_ring($BulletSpawn.global_position, RING_COUNT, 500.0, ring_angle)
	# 每圈整体旋转一格，形成连绵的旋转弹幕
	ring_angle += TAU / RING_COUNT
