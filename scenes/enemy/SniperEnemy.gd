class_name SniperEnemy
extends BaseEnemy

const ENTER_SPEED: float = 167.0
const STOP_X_RATIO: float = 0.75
const SHOOT_COOLDOWN: float = 1.8
const PATROL_RANGE_Y: float = 50.0
const PATROL_SPEED_Y: float = 67.0

var stop_x: float
var is_positioning: bool = true
var shoot_timer: float = 0.0
var patrol_dir: float = 1.0
var base_y: float = 0.0

func _ready() -> void:
	max_hp = 4
	score_value = 200
	super()
	stop_x = get_viewport_rect().size.x * STOP_X_RATIO
	base_y = position.y
	shoot_timer = randf_range(0.5, SHOOT_COOLDOWN)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_positioning:
		velocity.x = -ENTER_SPEED
		velocity.y = 0.0
		if position.x <= stop_x:
			position.x = stop_x
			is_positioning = false
	else:
		velocity.x = 0.0
		velocity.y = PATROL_SPEED_Y * patrol_dir
		if position.y > base_y + PATROL_RANGE_Y:
			patrol_dir = -1.0
		elif position.y < base_y - PATROL_RANGE_Y:
			patrol_dir = 1.0

	move_and_slide()

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = SHOOT_COOLDOWN
		_fire_aimed()

func _fire_aimed() -> void:
	var target_pos := Vector2(200.0, get_viewport_rect().size.y * 0.5)
	var p: Node2D = GameState.player
	if is_instance_valid(p):
		target_pos = p.global_position
	var dir := (target_pos - global_position).normalized()
	BulletFactory.spawn_enemy_bullet($BulletSpawn.global_position, dir)