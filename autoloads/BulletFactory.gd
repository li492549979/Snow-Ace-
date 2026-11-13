extends Node
## 子弹对象池 + 可复用弹幕生成器（autoload）。
## 公共 API 保持向后兼容：spawn_enemy_bullet / spawn_player_bullet 仍返回 Area2D。
## 子弹常驻挂在本节点下，跨场景重载复用；关卡（重）开始时调 despawn_all() 清残留。
## 新增弹幕生成器：fire_ring / fire_nway / fire_aimed。

const POOL_ENEMY_INIT: int = 80
const POOL_PLAYER_INIT: int = 24
const POOL_GROW_STEP: int = 32
const PARK_POS: Vector2 = Vector2(-9999, -9999)

var enemy_bullet_scene: PackedScene = preload("res://scenes/bullet/EnemyBullet.tscn")
var player_bullet_scene: PackedScene = preload("res://scenes/bullet/PlayerBullet.tscn")

var _enemy_pool: Array[Area2D] = []
var _player_pool: Array[Area2D] = []

# 特效池（爆炸/飘字/命中火花）—— 轻量池化
var explosion_scene: PackedScene = preload("res://scenes/effect/ExplosionEffect.tscn")
var score_popup_scene: PackedScene = preload("res://scenes/effect/ScorePopup.tscn")
var hitspark_scene: PackedScene = preload("res://scenes/effect/HitSpark.tscn")
var _explosion_pool: Array[Node2D] = []
var _score_popup_pool: Array[Node2D] = []
var _hitspark_pool: Array[Node2D] = []

func _ready() -> void:
	for i in POOL_ENEMY_INIT:
		_enemy_pool.append(_create_enemy_bullet())
	for i in POOL_PLAYER_INIT:
		_player_pool.append(_create_player_bullet())

# ===================== 子弹：创建 / 池 =====================

func _create_enemy_bullet() -> Area2D:
	var b := enemy_bullet_scene.instantiate()
	add_child(b)
	b.add_to_group("enemy_bullet")
	_deactivate_immediate(b)
	return b

func _create_player_bullet() -> Area2D:
	var b := player_bullet_scene.instantiate()
	add_child(b)
	b.add_to_group("player_bullet")
	_deactivate_immediate(b)
	return b

func spawn_enemy_bullet(pos: Vector2, dir: Vector2, rot_speed: float = 0.0, speed: float = 500.0) -> Area2D:
	var b := _acquire(_enemy_pool, _create_enemy_bullet)
	b.global_position = pos
	b.direction = dir
	b.rotation = dir.angle()  # 贴图对齐飞行方向（环形/自机狙弹不转向会明显违和）
	b.rotation_speed = rot_speed
	b.speed = speed
	_activate(b)
	AudioManager.play_throttled("enemy_shoot", 0.05)
	return b

func spawn_player_bullet(pos: Vector2, dir: Vector2 = Vector2.RIGHT, speed: float = 1333.0) -> Area2D:
	var b := _acquire(_player_pool, _create_player_bullet)
	b.global_position = pos
	b.direction = dir
	b.speed = speed
	b.damage = 1
	b.scale = Vector2.ONE
	_activate(b)
	return b

func spawn_charged_shot(pos: Vector2, dir: Vector2, damage: int, scale_factor: float) -> Area2D:
	var b := _acquire(_player_pool, _create_player_bullet)
	b.global_position = pos
	b.direction = dir
	b.speed = 1000.0
	b.damage = damage
	b.scale = Vector2.ONE * scale_factor
	_activate(b)
	AudioManager.play("charge_fire")
	return b

func release_enemy_bullet(b: Area2D) -> void:
	_release(b, _enemy_pool)

func release_player_bullet(b: Area2D) -> void:
	_release(b, _player_pool)

func despawn_all() -> void:
	# 关卡（重）开始时清掉残留的活动子弹（池里的失活子弹不动）
	for node in get_tree().get_nodes_in_group("enemy_bullet"):
		if node is Area2D and node.visible:
			release_enemy_bullet(node)
	for node in get_tree().get_nodes_in_group("player_bullet"):
		if node is Area2D and node.visible:
			release_player_bullet(node)

func _acquire(pool: Array, factory: Callable) -> Area2D:
	if pool.is_empty():
		for i in POOL_GROW_STEP:
			pool.append(factory.call())
	return pool.pop_back()

func _release(b: Area2D, pool: Array) -> void:
	if not is_instance_valid(b):
		return
	_deactivate(b)
	# 防止同帧被重复回收（如命中 + 出屏同时触发）造成重复入池
	if not pool.has(b):
		pool.append(b)

func _activate(b: CanvasItem) -> void:
	b.visible = true
	b.set_physics_process(true)
	if b is Area2D:
		(b as Area2D).set_deferred("monitoring", true)

func _deactivate(b: CanvasItem) -> void:
	if b is Area2D:
		(b as Area2D).set_deferred("monitoring", false)
	b.set_physics_process(false)
	b.visible = false
	if b is Node2D:
		# 用 deferred 改位置，避免在 area_entered 回调（查询刷新期间）改物理状态报错
		(b as Node2D).set_deferred("global_position", PARK_POS)

# 创建期停用：立即生效（创建发生在 autoload _ready，不在物理查询刷新期间，无需 deferred）。
# 关键：不能用 deferred，否则被取用的对象会在第一帧末被创建期 deferred 错误地挪回 PARK。
func _deactivate_immediate(b: CanvasItem) -> void:
	if b is Area2D:
		(b as Area2D).monitoring = false
	b.set_physics_process(false)
	b.visible = false
	if b is Node2D:
		(b as Node2D).global_position = PARK_POS

# ===================== 弹幕生成器 =====================

func fire_ring(pos: Vector2, count: int, speed: float, base_angle: float, rot_speed: float = 0.0) -> void:
	for i in count:
		var a := base_angle + (TAU * i / count)
		spawn_enemy_bullet(pos, Vector2(cos(a), sin(a)), rot_speed, speed)

func fire_nway(pos: Vector2, base_dir: Vector2, count: int, spread: float, speed: float, rot_speed: float = 0.0) -> void:
	if count <= 0:
		return
	if count == 1:
		spawn_enemy_bullet(pos, base_dir, rot_speed, speed)
		return
	var base_angle := base_dir.angle()
	for i in count:
		var t := float(i) / float(count - 1)
		var a := base_angle + lerpf(-spread * 0.5, spread * 0.5, t)
		spawn_enemy_bullet(pos, Vector2(cos(a), sin(a)), rot_speed, speed)

func fire_aimed(pos: Vector2, target: Vector2, count: int, spread: float, speed: float, rot_speed: float = 0.0) -> void:
	fire_nway(pos, (target - pos).normalized(), count, spread, speed, rot_speed)

# ===================== 特效：池 =====================

func spawn_explosion(pos: Vector2) -> void:
	var e: Node2D = _acquire_node(_explosion_pool, _create_explosion)
	if e.has_method("activate"):
		e.activate(pos)

func release_explosion(e: Node2D) -> void:
	if not is_instance_valid(e):
		return
	if e.has_method("deactivate"):
		e.deactivate()
	if not _explosion_pool.has(e):
		_explosion_pool.append(e)

func _create_explosion() -> Node2D:
	var e := explosion_scene.instantiate()
	add_child(e)  # _ready 负责一次性预创建粒子
	if e.has_method("deactivate"):
		e.deactivate()
	return e

func spawn_score_popup(pos: Vector2, text: String, color: Color) -> void:
	var p: Node2D = _acquire_node(_score_popup_pool, _create_score_popup)
	if p.has_method("activate"):
		p.activate(pos, text, color)

func release_score_popup(p: Node2D) -> void:
	if not is_instance_valid(p):
		return
	if p.has_method("deactivate"):
		p.deactivate()
	if not _score_popup_pool.has(p):
		_score_popup_pool.append(p)

func _create_score_popup() -> Node2D:
	var p := score_popup_scene.instantiate()
	add_child(p)
	if p.has_method("deactivate"):
		p.deactivate()
	return p

func spawn_hit_spark(pos: Vector2) -> void:
	var s: Node2D = _acquire_node(_hitspark_pool, _create_hitspark)
	if s.has_method("activate"):
		s.activate(pos)

func release_hit_spark(s: Node2D) -> void:
	if not is_instance_valid(s):
		return
	if s.has_method("deactivate"):
		s.deactivate()
	if not _hitspark_pool.has(s):
		_hitspark_pool.append(s)

func _create_hitspark() -> Node2D:
	var s := hitspark_scene.instantiate()
	add_child(s)
	if s.has_method("deactivate"):
		s.deactivate()
	return s

func _acquire_node(pool: Array, factory: Callable) -> Node2D:
	if pool.is_empty():
		return factory.call()
	return pool.pop_back()
