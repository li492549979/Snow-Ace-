extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
signal bomb_used
signal lives_changed(current: int)
signal weapon_changed(level: int)
signal bombs_changed(count: int)

const SPEED: float = 500.0
const SHOOT_COOLDOWN: float = 0.15
const INVULNERABLE_TIME: float = 1.2
const RESPAWN_INVULNERABLE: float = 2.0
const MAX_WEAPON_LEVEL: int = 5
const CHARGE_THRESHOLD: float = 0.25   # 进入蓄力
const CHARGE_TIER2: float = 0.55        # 二层（大弹）
const CHARGE_TIER3: float = 1.0         # 满层（激光）
const CHARGE_T1_DMG: int = 3
const CHARGE_T1_SCALE: float = 1.8
const CHARGE_T2_DMG: int = 5
const CHARGE_T2_SCALE: float = 2.7

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
var _charge_tier: int = 0
var _sprite_base_scale: Vector2 = Vector2.ONE

@onready var bullet_spawn: Marker2D = $BulletSpawn
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var charge_ring: Sprite2D = $ChargeRing
@onready var muzzle_flash: Sprite2D = $MuzzleFlash
@onready var laser: Area2D = $Laser

func _ready() -> void:
	add_to_group("player")
	GameState.player = self
	_sprite_base_scale = sprite.scale
	sprite.play("fly")
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
	position = position.clamp(Vector2(70.0, 45.0), screen_size - Vector2(70.0, 45.0))

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
	# get_vector 同时覆盖键盘（归一化八向）与左摇杆（模拟量），并应用各动作 deadzone
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED

func _handle_shooting(delta: float) -> void:
	if input_locked:
		_reset_charge()
		return
	# 射击冷却每帧都递减（不按也走），这样点按不会被卡住
	shoot_timer -= delta
	if Input.is_action_pressed("fire"):
		charge_time += delta
		if charge_time < CHARGE_THRESHOLD:
			# 短按：普通连射
			is_charging = false
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
	var pos := bullet_spawn.global_position
	if charge_time >= CHARGE_TIER3:
		_fire_laser()
		_shake(9.0, 0.2)
		_muzzle_flash()
	elif charge_time >= CHARGE_TIER2:
		BulletFactory.spawn_charged_shot(pos, Vector2.RIGHT, CHARGE_T2_DMG, CHARGE_T2_SCALE)
		_shake(5.0, 0.12)
		_muzzle_flash()
	else:
		BulletFactory.spawn_charged_shot(pos, Vector2.RIGHT, CHARGE_T1_DMG, CHARGE_T1_SCALE)
		_muzzle_flash()

func _fire_laser() -> void:
	if laser:
		laser.activate()

func _shake(intensity: float = 6.0, duration: float = 0.15) -> void:
	var scene := get_tree().current_scene
	if scene and scene.has_method("_shake_screen"):
		scene._shake_screen(intensity, duration)

func _muzzle_flash() -> void:
	if muzzle_flash == null:
		return
	muzzle_flash.visible = true
	muzzle_flash.modulate = Color(1.0, 1.0, 0.9, 0.95)
	muzzle_flash.scale = Vector2.ONE * 0.6
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(muzzle_flash, "modulate:a", 0.0, 0.16)
	tw.tween_property(muzzle_flash, "scale", Vector2.ONE * 1.5, 0.16)
	tw.chain().tween_callback(func() -> void: muzzle_flash.visible = false)

func _reset_charge() -> void:
	charge_time = 0.0
	is_charging = false
	_charge_tier = 0
	_update_charge_indicator()

func _update_charge_indicator() -> void:
	if charge_ring == null:
		return
	if is_charging:
		var col: Color = Color(1.0, 0.9, 0.3)
		var scl: float = 0.9
		var tier: int = 0
		if charge_time >= CHARGE_TIER3:
			col = Color(1.0, 0.25, 0.25)
			scl = 1.8 + sin(charge_time * 24.0) * 0.12  # 满层脉动，提示释放
			tier = 2
		elif charge_time >= CHARGE_TIER2:
			col = Color(1.0, 0.6, 0.2)
			scl = 1.3
			tier = 1
		if tier != _charge_tier:
			_charge_tier = tier
			AudioManager.play("charge")  # 蓄力升级音，提示可释放更强攻击
		charge_ring.visible = true
		charge_ring.modulate = col
		charge_ring.scale = Vector2.ONE * scl
		charge_ring.rotation += 0.03
	else:
		charge_ring.visible = false
		charge_ring.scale = Vector2.ONE

func _handle_bomb() -> void:
	if input_locked:
		return
	if Input.is_action_just_pressed("bomb") and bombs > 0:
		bombs -= 1
		bombs_changed.emit(bombs)
		bomb_used.emit()
		invulnerable_timer = max(invulnerable_timer, 1.5)
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
		weapon_changed.emit(weapon_level)
		_on_weapon_upgraded()

func _on_weapon_upgraded() -> void:
	AudioManager.play("powerup")
	BulletFactory.spawn_score_popup(global_position + Vector2(0, -40), "LEVEL UP!", Color(0.4, 1.0, 0.5))
	var tw := create_tween()
	tw.tween_property(sprite, "scale", _sprite_base_scale * 1.3, 0.08).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "scale", _sprite_base_scale, 0.14).set_ease(Tween.EASE_IN_OUT)

func heal(amount: int) -> void:
	hp = min(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)

func add_bomb(amount: int) -> void:
	bombs += amount
	bombs_changed.emit(bombs)

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
	if laser:
		laser.deactivate()
	hp = max_hp
	health_changed.emit(hp, max_hp)
	invulnerable_timer = RESPAWN_INVULNERABLE
	weapon_level = max(1, weapon_level - 1)
	weapon_changed.emit(weapon_level)
	position = Vector2(200.0, screen_size.y * 0.5)
	velocity = Vector2.ZERO

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	if charge_ring:
		charge_ring.visible = false
	if laser:
		laser.deactivate()
	for i in 5:
		BulletFactory.spawn_explosion(global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30)))
	AudioManager.play("explosion")
	GameState.player = null
	died.emit()
	queue_free()

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_bullet"):
		BulletFactory.release_enemy_bullet(area)
		take_damage(1)
	elif area.is_in_group("enemy_hitbox"):
		take_damage(1)
		_crash_enemy(area)
	elif area.is_in_group("pickup"):
		area.collect(self)

func _crash_enemy(hitbox: Area2D) -> void:
	# 只有 dies_on_contact 的敌人（如 RushEnemy 神风兵）撞击会自毁；其余只扣玩家血、本体存活
	var enemy = hitbox.get_parent()
	if not is_instance_valid(enemy) or not enemy.has_method("take_damage"):
		return
	var dies_on_contact: bool = enemy.get("dies_on_contact") if "dies_on_contact" in enemy else false
	if not dies_on_contact:
		return
	var enemy_hp: int = enemy.get("hp") if "hp" in enemy else 1
	enemy.take_damage(enemy_hp)