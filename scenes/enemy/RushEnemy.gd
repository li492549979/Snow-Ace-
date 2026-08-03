class_name RushEnemy
extends BaseEnemy

const RUSH_SPEED: float = 583.0
const DETECT_RANGE: float = 833.0

var target_pos: Vector2 = Vector2.ZERO
var is_charging: bool = false
var charge_timer: float = 0.5

func _ready() -> void:
	max_hp = 1
	score_value = 120
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
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_pos = players[0].global_position
		velocity = (target_pos - global_position).normalized() * RUSH_SPEED

	move_and_slide()

	if position.x < -100.0 or position.x > get_viewport_rect().size.x + 100.0:
		queue_free()

func _start_charge() -> void:
	is_charging = true
	var sprite := get_node_or_null("Sprite")
	if sprite:
		var tw: Tween = create_tween().set_loops(3)
		tw.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.0), 0.08)
		tw.tween_property(sprite, "modulate", Color(1.0, 0.8, 0.0), 0.08)