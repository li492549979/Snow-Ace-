extends Area2D

enum Type { WEAPON, HEALTH, BOMB, SCORE_SMALL, SCORE_BIG }

const SCORE_SMALL_VALUE: int = 500
const SCORE_BIG_VALUE: int = 2000
const DRIFT_SPEED: float = 67.0
const BOB_AMPLITUDE: float = 5.0
const BOB_SPEED: float = 4.0
const MAGNET_RANGE: float = 220.0
const COLLECT_SPEED: float = 650.0

const TEX_WEAPON: Texture2D = preload("res://art/svg/pickup_weapon.svg")
const TEX_HEALTH: Texture2D = preload("res://art/svg/pickup_health.svg")
const TEX_BOMB: Texture2D = preload("res://art/svg/pickup_bomb.svg")
const TEX_SCORE_SMALL: Texture2D = preload("res://art/svg/pickup_score_small.svg")
const TEX_SCORE_BIG: Texture2D = preload("res://art/svg/pickup_score_big.svg")

@export var pickup_type: Type = Type.SCORE_SMALL

var start_y: float
var time_alive: float = 0.0
var collected: bool = false
var score_callback: Callable = Callable()

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	collision_layer = 1 << 15
	collision_mask = 0
	monitoring = false
	add_to_group("pickup")
	start_y = position.y
	match pickup_type:
		Type.WEAPON:
			sprite.texture = TEX_WEAPON
		Type.HEALTH:
			sprite.texture = TEX_HEALTH
		Type.BOMB:
			sprite.texture = TEX_BOMB
		Type.SCORE_SMALL:
			sprite.texture = TEX_SCORE_SMALL
		Type.SCORE_BIG:
			sprite.texture = TEX_SCORE_BIG

func _physics_process(delta: float) -> void:
	var p: Node2D = GameState.player
	if is_instance_valid(p):
		var to_p: Vector2 = p.global_position - global_position
		if to_p.length() < MAGNET_RANGE:
			global_position += to_p.normalized() * COLLECT_SPEED * delta
			return
	# 原漂移 + 上下浮动
	position.x -= DRIFT_SPEED * delta
	time_alive += delta
	position.y = start_y + sin(time_alive * BOB_SPEED) * BOB_AMPLITUDE

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func collect(player: Node2D) -> void:
	if collected:
		return
	collected = true
	AudioManager.play("pickup")
	var bonus := 0
	match pickup_type:
		Type.WEAPON:
			if player.has_method("upgrade_weapon"):
				player.upgrade_weapon()
		Type.HEALTH:
			if player.has_method("heal"):
				player.heal(1)
		Type.BOMB:
			if player.has_method("add_bomb"):
				player.add_bomb(1)
		Type.SCORE_SMALL:
			bonus = SCORE_SMALL_VALUE
		Type.SCORE_BIG:
			bonus = SCORE_BIG_VALUE
	if bonus > 0 and score_callback.is_valid():
		score_callback.call(bonus)
	queue_free()