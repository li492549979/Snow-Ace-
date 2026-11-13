class_name RushEnemy
extends BaseEnemy

const RUSH_SPEED: float = 583.0

var rush_dir: Vector2 = Vector2.LEFT
var is_charging: bool = false
var charge_timer: float = 0.5

func _ready() -> void:
	max_hp = 1
	score_value = 120
	dies_on_contact = true
	super()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_charging:
		velocity.x = -133.0
		velocity.y = 0.0
		charge_timer -= delta
		if charge_timer <= 0.0:
			_start_charge()
	else:
		# 冲刺方向在起冲瞬间锁定，直线冲不再追踪（持续追踪会折返纠缠、永不离场）
		velocity = rush_dir * RUSH_SPEED

	move_and_slide()

	if position.x < -100.0 or position.x > get_viewport_rect().size.x + 100.0:
		queue_free()

func _start_charge() -> void:
	is_charging = true
	# 锁定起冲瞬间玩家所在位置，朝其直线俯冲；miss 后径直飞出屏幕
	var p: Node2D = GameState.player
	var target: Vector2 = p.global_position if is_instance_valid(p) else Vector2(global_position.x - 833.0, global_position.y)
	rush_dir = (target - global_position).normalized()
	var tw: Tween = create_tween().set_loops(3)
	tw.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.0), 0.08)
	tw.tween_property(sprite, "modulate", Color(1.0, 0.8, 0.0), 0.08)