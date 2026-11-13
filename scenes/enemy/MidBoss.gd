class_name MidBoss
extends BaseEnemy

const ENTER_SPEED: float = 250.0
const IDLE_X: float = 1333.0
const MOVE_SPEED_X: float = 100.0
const SINE_AMPLITUDE: float = 200.0
const SINE_SPEED: float = 2.0
const SHOOT_COOLDOWN: float = 1.5

var is_entering: bool = true
var shoot_timer: float = 1.0
var time_alive: float = 0.0
var center_y: float = 540.0
var base_x: float = 0.0
var pattern_index: int = 1
var ring_angle: float = 0.0

func _ready() -> void:
	add_to_group("midboss")
	max_hp = 50
	score_value = 2000
	super()
	center_y = get_viewport_rect().size.y * 0.5

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_entering:
		position.x -= ENTER_SPEED * delta
		if position.x <= IDLE_X:
			base_x = IDLE_X
			is_entering = false
	else:
		time_alive += delta
		position.x = base_x + sin(time_alive * 0.8) * 100.0
		position.y = center_y + sin(time_alive * SINE_SPEED) * SINE_AMPLITUDE

	velocity = Vector2.ZERO
	move_and_slide()

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = SHOOT_COOLDOWN
		_fire_pattern()

func _play_hit_sound() -> void:
	AudioManager.play_throttled("boss_hit", 0.08)

func _fire_pattern() -> void:
	pattern_index = (pattern_index + 1) % 2
	match pattern_index:
		0:
			_fire_aimed_spread()
		1:
			_fire_ring()

func _fire_aimed_spread() -> void:
	var target_pos := Vector2(200.0, center_y)
	var p: Node2D = GameState.player
	if is_instance_valid(p):
		target_pos = p.global_position
	BulletFactory.fire_aimed(
		global_position + Vector2(-100, 0), target_pos, 5, 0.6, 500.0)

func _fire_ring() -> void:
	# 慢速旋转环，保证可读性
	BulletFactory.fire_ring(global_position, 10, 380.0, ring_angle)
	ring_angle += TAU / 10.0

func _die() -> void:
	is_dead = true
	destroyed.emit(score_value, global_position)
	AudioManager.play("explosion")
	_spawn_pickup(0)
	_spawn_pickup(1)
	queue_free()

func _try_drop_pickup() -> void:
	pass