extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
signal bomb_used
signal lives_changed(current: int)

const SPEED: float = 500.0
const SHOOT_COOLDOWN: float = 0.15
const INVULNERABLE_TIME: float = 1.2
const RESPAWN_INVULNERABLE: float = 2.0
const MAX_WEAPON_LEVEL: int = 5
const CHARGE_THRESHOLD: float = 0.25
const FULL_CHARGE_TIME: float = 1.1
const CHARGE_MIN_DMG: int = 4
const CHARGE_MAX_DMG: int = 8
const CHARGE_MIN_SCALE: float = 2.0
const CHARGE_MAX_SCALE: float = 3.5

var screen_size: Vector2
var shoot_timer: float = 0.0
var invulnerable_timer: float = 0.0
var hp: int = 5
var max_hp: int = 5
var lives: int = 3
var weapon_level: int = 1
var bombs: int = 3
var is_dead: bool = false
var input_locked: bool = false
var charge_time: float = 0.0
var is_charging: bool = false

@onready var bullet_spawn: Marker2D = $BulletSpawn
@onready var sprite: ColorRect = $Sprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var charge_ring: ColorRect = $ChargeRing

func _ready() -> void:
	add_to_group("player")
	screen_size = get_viewport_rect().size
	hurtbox.collision_mask = (1 << 2) | (1 << 3) | (1 << 15)
	health_changed.emit(hp, max_hp)
	lives_changed.emit(lives)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_handle_invulnerability(delta)
	_handle_movement(delta)
	_handle_shooting(delta)
	_handle_bomb()
	move_and_slide()
	position = position.clamp(Vector2(40.0, 40.0), screen_size - Vector2(40.0, 40.0))

func _handle_invulnerability(delta: float) -> void:
	if invulnerable_timer <= 0.0:
		sprite.modulate = Color.WHITE
		return

	invulnerable_timer -= delta
	var flash_on := int(invulnerable_timer * 12.0) % 2 == 0
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.35 if flash_on else 1.0)

func _handle_movement(_delta: float) -> void:
	if input_locked:
		velocity = Vector2.ZERO
		return
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1

	velocity = dir.normalized() * SPEED if dir != Vector2.ZERO else Vector2.ZERO

func _handle_shooting(delta: float) -> void:
	if input_locked:
		_reset_charge()
		return
	if Input.is_action_pressed("ui_accept"):
		charge_time += delta
		if charge_time < CHARGE_THRESHOLD:
			# 短按：普通连射
			is_charging = false
			shoot_timer -= delta
			if shoot_timer <= 0.0:
				shoot_timer = SHOOT_COOLDOWN
				_fire()
		else:
			# 长按：蓄力（停止连射）
			is_charging = true
		_update_charge_indicator()
	else:
		if is_charging:
			_release_charged_shot()
		_reset_charge()

func _release_charged_shot() -> void:
	var t: float = clampf((charge_time - CHARGE_THRESHOLD) / (FULL_CHARGE_TIME - CHARGE_THRESHOLD), 0.0, 1.0)
	var dmg: int = roundi(lerpf(CHARGE_MIN_DMG, CHARGE_MAX_DMG, t))
	var scl: float = lerpf(CHARGE_MIN_SCALE, CHARGE_MAX_SCALE, t)
	BulletFactory.spawn_charged_shot(bullet_spawn.global_position, Vector2.RIGHT, dmg, scl)

func _reset_charge() -> void:
	charge_time = 0.0
	is_charging = false
	_update_charge_indicator()

func _update_charge_indicator() -> void:
	if charge_ring == null:
		return
	if is_charging:
		var t: float = clampf((charge_time - CHARGE_THRESHOLD) / (FULL_CHARGE_TIME - CHARGE_THRESHOLD), 0.0, 1.0)
		charge_ring.visible = true
		charge_ring.scale = Vector2.ONE * lerpf(0.6, 1.8, t)
		charge_ring.color = Color(1.0, 0.9, 0.3).lerp(Color(1.0, 0.35, 0.35), t)
	else:
		charge_ring.visible = false
		charge_ring.scale = Vector2.ONE

func _handle_bomb() -> void:
	if input_locked:
		return
	if Input.is_action_just_pressed("ui_cancel") and bombs > 0:
		bombs -= 1
		bomb_used.emit()
		invulnerable_timer = max(invulnerable_timer, 1.0)
		AudioManager.play("bomb")

func _fire() -> void:
	AudioManager.play("shoot")
	var base_pos := bullet_spawn.global_position
	match weapon_level:
		1:
			_spawn_bullet(base_pos, Vector2.RIGHT)
		2:
			_spawn_bullet(base_pos + Vector2(0, -10), Vector2.RIGHT)
			_spawn_bullet(base_pos + Vector2(0, 10), Vector2.RIGHT)
		3:
			_spawn_bullet(base_pos, Vector2.RIGHT)
			_spawn_bullet(base_pos + Vector2(-7, -7), Vector2(1.0, -0.18).normalized())
			_spawn_bullet(base_pos + Vector2(-7, 7), Vector2(1.0, 0.18).normalized())
		4:
			_spawn_bullet(base_pos + Vector2(0, -10), Vector2.RIGHT)
			_spawn_bullet(base_pos + Vector2(0, 10), Vector2.RIGHT)
			_spawn_bullet(base_pos + Vector2(-7, -7), Vector2(1.0, -0.30).normalized())
			_spawn_bullet(base_pos + Vector2(-7, 7), Vector2(1.0, 0.30).normalized())
		_:
			_spawn_bullet(base_pos, Vector2.RIGHT)
			_spawn_bullet(base_pos + Vector2(-7, -7), Vector2(1.0, -0.18).normalized())
			_spawn_bullet(base_pos + Vector2(-7, 7), Vector2(1.0, 0.18).normalized())
			_spawn_bullet(base_pos + Vector2(-10, -10), Vector2(1.0, -0.42).normalized())
			_spawn_bullet(base_pos + Vector2(-10, 10), Vector2(1.0, 0.42).normalized())

func _spawn_bullet(pos: Vector2, dir: Vector2) -> void:
	BulletFactory.spawn_player_bullet(pos, dir)

func upgrade_weapon() -> void:
	if weapon_level < MAX_WEAPON_LEVEL:
		weapon_level += 1
		_on_weapon_upgraded()

func _on_weapon_upgraded() -> void:
	AudioManager.play("powerup")
	BulletFactory.spawn_score_popup(global_position + Vector2(0, -40), "LEVEL UP!", Color(0.4, 1.0, 0.5))
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.08).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.14).set_ease(Tween.EASE_IN_OUT)

func heal(amount: int) -> void:
	hp = min(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)

func add_bomb(amount: int) -> void:
	bombs += amount

func take_damage(amount: int = 1) -> void:
	if is_dead or invulnerable_timer > 0.0:
		return

	hp = max(0, hp - amount)
	health_changed.emit(hp, max_hp)
	AudioManager.play("player_hit")
	if hp <= 0:
		_on_hp_depleted()
	else:
		invulnerable_timer = INVULNERABLE_TIME

func _on_hp_depleted() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives > 0:
		_respawn()
	else:
		_die()

func _respawn() -> void:
	BulletFactory.spawn_explosion(global_position)
	hp = max_hp
	health_changed.emit(hp, max_hp)
	invulnerable_timer = RESPAWN_INVULNERABLE
	weapon_level = max(1, weapon_level - 1)
	position = Vector2(200.0, screen_size.y * 0.5)
	velocity = Vector2.ZERO

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	if charge_ring:
		charge_ring.visible = false
	for i in 5:
		BulletFactory.spawn_explosion(global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30)))
	AudioManager.play("explosion")
	died.emit()
	queue_free()

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_bullet"):
		BulletFactory.release_enemy_bullet(area)
		take_damage(1)
	elif area.is_in_group("enemy_hitbox"):
		take_damage(1)
	elif area.is_in_group("pickup"):
		area.collect(self)