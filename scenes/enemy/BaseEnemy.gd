class_name BaseEnemy
extends CharacterBody2D

signal destroyed(score_value: int, at: Vector2)
signal hp_changed(current: int, maximum: int)

const DROP_CHANCE_WEAPON: float = 0.12
const DROP_CHANCE_HEALTH: float = 0.12
const DROP_CHANCE_BOMB: float = 0.08
const DROP_CHANCE_SCORE_SMALL: float = 0.25
const DROP_CHANCE_SCORE_BIG: float = 0.03

@export var max_hp: int = 3
@export var score_value: int = 100
@export var dies_on_contact: bool = false  # 撞到玩家时是否自毁（神风），如 RushEnemy

var hp: int
var is_dead: bool = false
var score_callback: Callable = Callable()

var hitbox: Area2D
@onready var sprite: AnimatedSprite2D = $Sprite
var _hit_tween: Tween = null
var _last_hit_flash_msec: int = -1000

var pickup_scene: PackedScene = preload("res://scenes/pickup/Pickup.tscn")

func _ready() -> void:
	add_to_group("enemy")
	hitbox = get_node_or_null("Hitbox")
	if hitbox:
		hitbox.add_to_group("enemy_hitbox")
		hitbox.area_entered.connect(_on_hitbox_area_entered)
	hp = max_hp
	sprite.play("idle")
	sprite.animation_finished.connect(_on_sprite_animation_finished)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_bullet"):
		var d = area.get("damage")
		var dmg: int = d if d is int else 1
		BulletFactory.release_player_bullet(area)
		take_damage(dmg)

func take_damage(amount: int = 1) -> void:
	if is_dead:
		return
	hp -= amount
	hp_changed.emit(hp, max_hp)
	_flash_hit()
	if hp <= 0:
		_die()
	else:
		_play_hit_sound()

func _play_hit_sound() -> void:
	# Boss/MidBoss 覆写为更低沉的 boss_hit；节流避免多路弹齐射刷屏
	AudioManager.play_throttled("hit", 0.05)

func _flash_hit() -> void:
	# 节流，避免高频子弹把闪烁刷成常亮
	var now := Time.get_ticks_msec()
	if now - _last_hit_flash_msec < 50:
		return
	_last_hit_flash_msec = now
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("hit"):
		sprite.play("hit")
	if _hit_tween:
		_hit_tween.kill()
	# modulate > 1 会提亮，营造“打白”的受击反馈
	sprite.modulate = Color(2.6, 2.6, 2.6)
	_hit_tween = create_tween()
	_hit_tween.tween_property(sprite, "modulate", Color.WHITE, 0.08)

func _on_sprite_animation_finished() -> void:
	if sprite != null and sprite.animation == "hit":
		sprite.play("idle")

func _die() -> void:
	is_dead = true
	destroyed.emit(score_value, global_position)
	AudioManager.play("explosion")
	_spawn_explosion()
	_try_drop_pickup()
	queue_free()

func _spawn_explosion() -> void:
	BulletFactory.spawn_explosion(global_position)

func _try_drop_pickup() -> void:
	var roll := randf()
	var cumulative := 0.0

	cumulative += DROP_CHANCE_WEAPON
	if roll < cumulative:
		_spawn_pickup(0)
		return
	cumulative += DROP_CHANCE_HEALTH
	if roll < cumulative:
		_spawn_pickup(1)
		return
	cumulative += DROP_CHANCE_BOMB
	if roll < cumulative:
		_spawn_pickup(2)
		return
	cumulative += DROP_CHANCE_SCORE_SMALL
	if roll < cumulative:
		_spawn_pickup(3)
		return
	cumulative += DROP_CHANCE_SCORE_BIG
	if roll < cumulative:
		_spawn_pickup(4)

func _spawn_pickup(pickup_type: int) -> void:
	var pickup := pickup_scene.instantiate()
	pickup.position = global_position
	pickup.pickup_type = pickup_type
	pickup.score_callback = score_callback
	# 延迟到物理查询刷新结束后再入树，避免在 area_entered 回调里改碰撞状态报错
	get_tree().current_scene.call_deferred("add_child", pickup)
