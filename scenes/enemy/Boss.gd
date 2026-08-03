class_name Boss
extends BaseEnemy

const ENTER_SPEED: float = 300.0
const IDLE_X: float = 1500.0
const MOVE_RANGE_Y: float = 300.0
const MOVE_SPEED_Y: float = 117.0
const PHASE2_THRESHOLD: float = 0.5
const SHOOT_CD_P1: float = 1.2
const SHOOT_CD_P2: float = 0.7
const SPIRAL_INTERVAL: float = 0.08
const SPIRAL_COUNT: int = 16

var phase: int = 1
var is_entering: bool = true
var shoot_timer: float = 1.0
var center_y: float = 540.0
var patrol_dir: float = 1.0
var pattern_index: int = 0
var spiral_timer: float = 0.0
var spiral_angle: float = 0.0
var spiral_remaining: int = 0
var is_doing_spiral: bool = false
var ring_angle: float = 0.0

func _ready() -> void:
	add_to_group("boss")
	max_hp = 30
	score_value = 5000
	super()
	center_y = get_viewport_rect().size.y * 0.5

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if is_entering:
		_enter(delta)
	else:
		_patrol(delta)
		_tick_shoot(delta)
	move_and_slide()

func _enter(delta: float) -> void:
	position.x -= ENTER_SPEED * delta
	if position.x <= IDLE_X:
		position.x = IDLE_X
		is_entering = false

func _patrol(delta: float) -> void:
	position.y += MOVE_SPEED_Y * patrol_dir * delta
	if position.y > center_y + MOVE_RANGE_Y:
		patrol_dir = -1.0
	elif position.y < center_y - MOVE_RANGE_Y:
		patrol_dir = 1.0
	velocity = Vector2.ZERO

func _tick_shoot(delta: float) -> void:
	if is_doing_spiral:
		spiral_timer -= delta
		if spiral_timer <= 0.0 and spiral_remaining > 0:
			_emit_spiral_bullet()
			spiral_timer = SPIRAL_INTERVAL
			spiral_remaining -= 1
		elif spiral_remaining <= 0:
			is_doing_spiral = false
			shoot_timer = SHOOT_CD_P1 if phase == 1 else SHOOT_CD_P2
		return

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = SHOOT_CD_P1 if phase == 1 else SHOOT_CD_P2
		if phase == 1:
			pattern_index = (pattern_index + 1) % 2
			match pattern_index:
				0:
					_shoot_triple()
				1:
					_shoot_aimed_3way()
		else:
			pattern_index = (pattern_index + 1) % 4
			match pattern_index:
				0:
					_shoot_spread5()
				1:
					_start_spiral()
				2:
					_shoot_aimed_burst()
				3:
					_shoot_ring_burst()

func _shoot_triple() -> void:
	BulletFactory.fire_nway(_muzzle(), Vector2.LEFT, 3, 0.9, 500.0)

func _shoot_aimed_3way() -> void:
	var target_pos := Vector2(200.0, center_y)
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_pos = players[0].global_position
	BulletFactory.fire_aimed(_muzzle(), target_pos, 3, 0.5, 500.0)

func _shoot_spread5() -> void:
	BulletFactory.fire_nway(_muzzle(), Vector2.LEFT, 5, 1.5, 500.0)

func _start_spiral() -> void:
	is_doing_spiral = true
	spiral_timer = 0.0
	spiral_angle = 0.0
	spiral_remaining = SPIRAL_COUNT

func _emit_spiral_bullet() -> void:
	# 双螺旋：两发相隔 PI，慢速曲射，保证可读性
	BulletFactory.spawn_enemy_bullet(_muzzle(), Vector2.LEFT.rotated(spiral_angle), 3.0, 380.0)
	BulletFactory.spawn_enemy_bullet(_muzzle(), Vector2.LEFT.rotated(spiral_angle + PI), 3.0, 380.0)
	spiral_angle += TAU / SPIRAL_COUNT

func _shoot_aimed_burst() -> void:
	var target_pos := Vector2(200.0, center_y)
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_pos = players[0].global_position
	BulletFactory.fire_aimed(_muzzle(), target_pos, 7, 0.72, 500.0)

func _shoot_ring_burst() -> void:
	# 慢速 16 发旋转环
	BulletFactory.fire_ring(_muzzle(), 16, 380.0, ring_angle)
	ring_angle += TAU / 16.0

func _muzzle() -> Vector2:
	return global_position + Vector2(-67.0, 0.0)

func take_damage(amount: int = 1) -> void:
	if is_dead:
		return
	hp -= amount
	hp_changed.emit(hp, max_hp)
	if phase == 1 and hp <= max_hp * PHASE2_THRESHOLD:
		phase = 2
		_on_phase2_start()
	if hp <= 0:
		_die()
	else:
		AudioManager.play_throttled("boss_hit", 0.08)

func _on_phase2_start() -> void:
	AudioManager.play("phase")
	var sprite := get_node_or_null("Sprite")
	if sprite:
		var tw: Tween = create_tween().set_loops(4)
		tw.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.2), 0.1)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _die() -> void:
	is_dead = true
	destroyed.emit(score_value, global_position)
	AudioManager.play("explosion")
	_spawn_pickup(0)
	_spawn_boss_explosion()
	queue_free()

func _spawn_boss_explosion() -> void:
	for i in range(5):
		BulletFactory.spawn_explosion(global_position + Vector2(randf_range(-50, 50), randf_range(-33, 33)))

func _try_drop_pickup() -> void:
	pass