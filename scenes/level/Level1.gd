extends Node2D

const TRANSITION_DURATION: float = 2.0
const BOSS_SECTION: int = 3
const MIDBOSS_SECTION: int = 2
const COMBO_WINDOW: float = 2.0
const COMBO_STEP: int = 8
const COMBO_MAX_MULT: int = 8
const TINT_ALPHA: float = 0.32
const FAR_SCROLL_FACTOR: float = 0.0
const MID_SCROLL_FACTOR: float = 0.6
const NEAR_SCROLL_FACTOR: float = 1.2

var sections: Array[Dictionary] = [
	{
		"bg_color": Color(0.05, 0.10, 0.25),
		"scroll_speed": 133.0,
		"duration": 14.0,
		"waves": [
			[2.0, 250.0, 0],
			[2.5, 500.0, 0],
			[2.5, 750.0, 0],
			[6.0, 333.0, 4],
			[6.5, 583.0, 4],
			[10.0, 200.0, 1],
			[10.0, 667.0, 1],
			[12.0, 417.0, 0],
		],
	},
	{
		"bg_color": Color(0.35, 0.18, 0.08),
		"scroll_speed": 200.0,
		"duration": 14.0,
		"waves": [
			[1.0, 167.0, 0],
			[1.5, 500.0, 3],
			[1.5, 833.0, 0],
			[4.0, 333.0, 2],
			[4.0, 667.0, 2],
			[7.0, 250.0, 4],
			[7.5, 500.0, 1],
			[7.5, 750.0, 1],
			[10.0, 417.0, 3],
			[10.0, 583.0, 3],
			[12.5, 333.0, 5],
			[12.5, 667.0, 5],
			[8.5, 400.0, 6],
			[10.5, 680.0, 6],
		],
	},
	{
		"bg_color": Color(0.02, 0.12, 0.08),
		"scroll_speed": 267.0,
		"duration": 14.0,
		"waves": [
			[1.0, 250.0, 3],
			[1.5, 500.0, 1],
			[1.5, 750.0, 1],
			[3.0, 333.0, 4],
			[3.5, 583.0, 2],
			[6.0, 167.0, 3],
			[6.0, 500.0, 3],
			[6.0, 833.0, 3],
			[8.5, 500.0, 5],
			[9.0, 333.0, 0],
			[9.5, 667.0, 0],
			[11.0, 417.0, 2],
			[4.5, 750.0, 6],
			[10.0, 250.0, 6],
		],
	},
	{
		"bg_color": Color(0.15, 0.02, 0.02),
		"scroll_speed": 0.0,
		"duration": -1.0,
		"waves": [],
	},
]

var current_section: int = 0
var section_elapsed: float = 0.0
var wave_index: int = 0
var scroll_speed: float = 133.0
var screen_width: float
var boss_spawned: bool = false
var midboss_spawned: bool = false
var midboss_alive: bool = false
var score: int = 0
var game_finished: bool = false
var combo: int = 0
var combo_timer: float = 0.0
var _last_known_hp: int = 5
var _shake_tween: Tween = null
var _shown_hi: int = 0

var enemy_scenes: Array[PackedScene] = [
	preload("res://scenes/enemy/BasicEnemy.tscn"),
	preload("res://scenes/enemy/DiveEnemy.tscn"),
	preload("res://scenes/enemy/SniperEnemy.tscn"),
	preload("res://scenes/enemy/RushEnemy.tscn"),
	preload("res://scenes/enemy/FormationEnemy.tscn"),
	preload("res://scenes/enemy/RingShooterEnemy.tscn"),
	preload("res://scenes/enemy/SpreadEnemy.tscn"),
]
var midboss_scene: PackedScene = preload("res://scenes/enemy/MidBoss.tscn")
var boss_scene: PackedScene = preload("res://scenes/enemy/Boss.tscn")
var bomb_effect_scene: PackedScene = preload("res://scenes/effect/BombEffect.tscn")

@onready var layer_far: Sprite2D = $Background/Far
@onready var layer_mid: Sprite2D = $Background/Mid
@onready var layer_near: Sprite2D = $Background/Near
@onready var tint: ColorRect = $Background/Tint
@onready var camera: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $Player
@onready var hp_label: Label = $HUD/HPLabel
@onready var lives_label: Label = $HUD/LivesLabel
@onready var score_label: Label = $HUD/ScoreLabel
@onready var weapon_label: Label = $HUD/WeaponLabel
@onready var weapon_pips: Array[ColorRect] = [
	$HUD/WeaponPip1, $HUD/WeaponPip2, $HUD/WeaponPip3, $HUD/WeaponPip4, $HUD/WeaponPip5,
]
@onready var bomb_label: Label = $HUD/BombLabel
@onready var combo_label: Label = $HUD/ComboLabel
@onready var boss_bar: ProgressBar = $HUD/BossBar
@onready var boss_name_label: Label = $HUD/BossBar/BossNameLabel
@onready var warning_label: Label = $HUD/WarningLabel
@onready var stage_label: Label = $HUD/StageLabel
@onready var damage_flash: ColorRect = $HUD/DamageFlash
@onready var result_panel: Panel = $HUD/ResultPanel
@onready var result_title: Label = $HUD/ResultPanel/TitleLabel
@onready var result_subtitle: Label = $HUD/ResultPanel/SubtitleLabel
@onready var restart_button: Button = $HUD/ResultPanel/RestartButton
@onready var hi_label: Label = $HUD/HiScoreLabel
@onready var pause_panel: Panel = $HUD/PausePanel
@onready var pause_resume_button: Button = $HUD/PausePanel/ResumeButton
@onready var pause_restart_button: Button = $HUD/PausePanel/RestartButton

func _ready() -> void:
	# 波次按时间排序：表内乱序条目（如写在 12.5s 之后的 8.5s 条目）会被 while 循环顺延到同帧扎堆刷出
	for sec: Dictionary in sections:
		(sec["waves"] as Array).sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	BulletFactory.despawn_all()  # 清掉上一局残留的活动子弹（池跨场景存活）
	screen_width = get_viewport_rect().size.x
	_apply_section(0, false)
	_update_score_label()
	_update_weapon_label()
	_update_bomb_label()
	_update_lives_label()
	result_panel.visible = false
	boss_bar.visible = false
	boss_name_label.visible = false
	warning_label.visible = false
	combo_label.visible = false
	stage_label.visible = false
	_show_stage_title()
	_last_known_hp = player.hp
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	player.bomb_used.connect(_on_player_bomb_used)
	player.weapon_changed.connect(_update_weapon_label)
	player.bombs_changed.connect(_update_bomb_label)
	player.lives_changed.connect(_update_lives_label)
	_on_player_health_changed(player.hp, player.max_hp)
	restart_button.pressed.connect(_restart_level)
	AudioManager.play_music("stage1")
	_shown_hi = GameState.hi_score
	hi_label.text = "HI: %06d" % _shown_hi
	GameState.pause_changed.connect(_on_pause_changed)
	pause_resume_button.pressed.connect(_on_pause_resume)
	pause_restart_button.pressed.connect(_restart_level)

func _process(delta: float) -> void:
	if game_finished:
		return

	_scroll_background(delta)
	_process_section(delta)
	_update_combo(delta)

func _unhandled_input(event: InputEvent) -> void:
	if game_finished and event.is_action_pressed("ui_accept"):
		_restart_level()

func _scroll_background(delta: float) -> void:
	# region_rect.position.x 增大 → 纹理内容向左滚动；远景慢、近景快
	_scroll_layer(layer_far, scroll_speed * FAR_SCROLL_FACTOR, delta)
	_scroll_layer(layer_mid, scroll_speed * MID_SCROLL_FACTOR, delta)
	_scroll_layer(layer_near, scroll_speed * NEAR_SCROLL_FACTOR, delta)

func _scroll_layer(sprite: Sprite2D, speed: float, delta: float) -> void:
	if sprite == null:
		return
	var r: Rect2 = sprite.region_rect
	r.position.x += speed * delta
	sprite.region_rect = r

func _process_section(delta: float) -> void:
	section_elapsed += delta
	var sec: Dictionary = sections[current_section]

	while wave_index < sec["waves"].size() and section_elapsed >= sec["waves"][wave_index][0]:
		var wave: Array = sec["waves"][wave_index]
		var enemy_type: int = wave[2] if wave.size() > 2 else 0
		if enemy_type == 4:
			_spawn_formation(wave[1])
		else:
			_spawn_enemy(wave[1], enemy_type)
		wave_index += 1

	if current_section == MIDBOSS_SECTION and section_elapsed > sections[current_section]["duration"] - 2.0 and not midboss_spawned:
		midboss_spawned = true
		_spawn_midboss()

	if current_section == BOSS_SECTION and not boss_spawned:
		boss_spawned = true
		_spawn_boss()

	if sec["duration"] > 0.0 and section_elapsed >= sec["duration"]:
		# MidBoss 未被击杀前，停留在此 section 不推进
		if current_section == MIDBOSS_SECTION and midboss_alive:
			pass
		else:
			var next: int = current_section + 1
			if next < sections.size():
				_apply_section(next, true)

func _apply_section(index: int, animated: bool) -> void:
	current_section = index
	section_elapsed = 0.0
	wave_index = 0
	var sec: Dictionary = sections[index]
	scroll_speed = sec["scroll_speed"]

	var tint_color: Color = sec["bg_color"]
	tint_color.a = TINT_ALPHA
	if animated:
		var tw: Tween = create_tween()
		tw.tween_property(tint, "color", tint_color, TRANSITION_DURATION)
	else:
		tint.color = tint_color

func _spawn_enemy(y: float, enemy_type: int = 0) -> void:
	var scene: PackedScene = enemy_scenes[enemy_type]
	var enemy = scene.instantiate()
	enemy.position = Vector2(screen_width + 67.0, y)
	enemy.score_callback = _on_pickup_score
	enemy.destroyed.connect(_on_threat_destroyed)
	add_child(enemy)

func _spawn_formation(center_y: float) -> void:
	var offsets: Array[Vector2] = [
		Vector2(0, 0),
		Vector2(135, -90),
		Vector2(135, 90),
		Vector2(270, -180),
		Vector2(270, 180),
	]
	for offset in offsets:
		var enemy = enemy_scenes[4].instantiate()
		enemy.position = Vector2(screen_width + 67.0 + offset.x, center_y + offset.y)
		enemy.score_callback = _on_pickup_score
		enemy.destroyed.connect(_on_threat_destroyed)
		add_child(enemy)

func _spawn_midboss() -> void:
	var mb = midboss_scene.instantiate()
	mb.position = Vector2(screen_width + 133.0, get_viewport_rect().size.y * 0.5)
	mb.score_callback = _on_pickup_score
	mb.destroyed.connect(_on_midboss_destroyed)
	mb.hp_changed.connect(_on_boss_hp_changed)
	add_child(mb)
	midboss_alive = true
	_show_boss_bar(mb, "MID BOSS")
	_show_warning()

func _spawn_boss() -> void:
	var boss = boss_scene.instantiate()
	boss.position = Vector2(screen_width + 133.0, get_viewport_rect().size.y * 0.5)
	boss.score_callback = _on_pickup_score
	boss.destroyed.connect(_on_boss_destroyed)
	boss.hp_changed.connect(_on_boss_hp_changed)
	add_child(boss)
	_show_boss_bar(boss, "BOSS")
	_show_warning()

func _on_player_health_changed(current: int, maximum: int) -> void:
	if current < _last_known_hp:
		combo = 0
		_flash_damage()
		_shake_screen(11.0, 0.25)
	_last_known_hp = current
	hp_label.text = "HP: %d/%d" % [current, maximum]

func _flash_damage() -> void:
	if damage_flash == null:
		return
	damage_flash.color = Color(1.0, 0.0, 0.0, 0.35)
	damage_flash.visible = true
	var tw := create_tween()
	tw.tween_property(damage_flash, "color:a", 0.0, 0.25)
	tw.tween_callback(func() -> void: damage_flash.visible = false)

func _on_player_died() -> void:
	_finish_game(false)

func _on_player_bomb_used() -> void:
	_activate_bomb()

func _activate_bomb() -> void:
	for node in get_tree().get_nodes_in_group("enemy_bullet"):
		BulletFactory.release_enemy_bullet(node as Area2D)
	# MidBoss/Boss 也属于 "enemy" 组（经由 BaseEnemy._ready），故只需遍历一次，
	# 避免重复 take_damage 造成双倍伤害。
	for node in get_tree().get_nodes_in_group("enemy"):
		if node.has_method("take_damage"):
			node.take_damage(8)
	var flash := bomb_effect_scene.instantiate()
	add_child(flash)
	_shake_screen(13.0, 0.3)

func _on_threat_destroyed(score_value: int, at: Vector2) -> void:
	combo += 1
	combo_timer = COMBO_WINDOW
	var award: int = score_value * _combo_multiplier()
	_add_score(award)
	_spawn_score_popup(at, award)

func _on_midboss_destroyed(score_value: int, at: Vector2) -> void:
	midboss_alive = false
	_hide_boss_bar()
	combo += 1
	combo_timer = COMBO_WINDOW
	var award: int = score_value * _combo_multiplier()
	_add_score(award)
	_spawn_score_popup(at, award)
	_apply_section(BOSS_SECTION, true)

func _on_boss_destroyed(score_value: int, at: Vector2) -> void:
	_hide_boss_bar()
	_add_score(score_value)
	_spawn_score_popup(at, score_value)
	_shake_screen(20.0, 0.8)
	# 终结爆发播完再出结算；tween 绑定本节点，期间重载场景会自动作废
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_callback(func() -> void: _finish_game(true))

func _on_boss_hp_changed(current: int, _maximum: int) -> void:
	boss_bar.value = current

func _on_pickup_score(bonus: int) -> void:
	_add_score(bonus)

func _add_score(amount: int) -> void:
	score += amount
	_update_score_label()
	if score > _shown_hi:  # 街机惯例：进行中实时顶掉旧纪录
		_shown_hi = score
		hi_label.text = "HI: %06d" % _shown_hi

func _update_score_label() -> void:
	score_label.text = "SCORE: %06d" % score

func _update_weapon_label(_level: int = -1) -> void:
	var lvl: int = player.weapon_level if is_instance_valid(player) else 0
	if weapon_label:
		weapon_label.text = "WPN: Lv%d" % lvl
	for i in weapon_pips.size():
		weapon_pips[i].color = Color(0.2, 0.8, 1.0) if i < lvl else Color(0.2, 0.25, 0.3)

func _update_bomb_label(_count: int = -1) -> void:
	if bomb_label and is_instance_valid(player):
		bomb_label.text = "BOMB: %d" % player.bombs

func _update_lives_label(_current: int = -1) -> void:
	if lives_label and is_instance_valid(player):
		lives_label.text = "LIVES: %d" % player.lives

func _update_combo(delta: float) -> void:
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
	if combo > 0:
		combo_label.visible = true
		var mult: int = _combo_multiplier()
		combo_label.text = "COMBO %d   ×%d" % [combo, mult]
		combo_label.modulate = _combo_color(mult)
	else:
		combo_label.visible = false

func _combo_multiplier() -> int:
	return clampi(floori(combo / float(COMBO_STEP)) + 1, 1, COMBO_MAX_MULT)

func _combo_color(mult: int) -> Color:
	return Color(1.0, 1.0 - 0.08 * (mult - 1), 0.4)

func _spawn_score_popup(pos: Vector2, award: int) -> void:
	var mult := _combo_multiplier()
	if mult > 1:
		BulletFactory.spawn_score_popup(pos, "+%d   ×%d" % [award, mult], _combo_color(mult))
	else:
		BulletFactory.spawn_score_popup(pos, "+%d" % award, Color(1.0, 0.95, 0.4))

func _show_boss_bar(threat: BaseEnemy, display_name: String) -> void:
	boss_name_label.text = display_name
	boss_bar.max_value = threat.max_hp
	boss_bar.value = threat.max_hp
	boss_bar.visible = true
	boss_name_label.visible = true

func _hide_boss_bar() -> void:
	boss_bar.visible = false
	boss_name_label.visible = false

func _show_warning() -> void:
	# 警报两遍 + 2 秒红字闪烁，给玩家留出清屏/归位的反应时间
	AudioManager.play("warning")
	get_tree().create_timer(0.8).timeout.connect(func() -> void: AudioManager.play("warning"))
	warning_label.visible = true
	warning_label.modulate.a = 1.0
	var tw := create_tween()
	tw.set_loops(4)
	tw.tween_property(warning_label, "modulate:a", 0.0, 0.25)
	tw.tween_property(warning_label, "modulate:a", 1.0, 0.25)
	tw.tween_callback(func() -> void: warning_label.visible = false)

func _show_stage_title() -> void:
	stage_label.visible = true
	stage_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(stage_label, "modulate:a", 1.0, 0.4)
	tw.tween_interval(1.2)
	tw.tween_property(stage_label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: stage_label.visible = false)

func is_pause_allowed() -> bool:
	return not game_finished

func _on_pause_changed(paused: bool) -> void:
	pause_panel.visible = paused
	if paused:
		pause_resume_button.grab_focus()

func _on_pause_resume() -> void:
	GameState.set_paused(false)

func _finish_game(stage_clear: bool) -> void:
	if game_finished:
		return

	game_finished = true
	GameState.set_paused(false)
	AudioManager.stop_music()
	player.input_locked = true
	scroll_speed = 0.0
	_clear_active_threats()
	AudioManager.play("clear" if stage_clear else "over")
	result_panel.visible = true
	var new_record: bool = GameState.submit_score(score)
	if stage_clear:
		result_title.text = "STAGE CLEAR"
	else:
		result_title.text = "GAME OVER"
	if new_record:
		result_subtitle.text = "Score  %06d   NEW RECORD!" % score
	else:
		result_subtitle.text = "Score  %06d   Best  %06d" % [score, GameState.hi_score]
	restart_button.grab_focus()

func _clear_active_threats() -> void:
	for node in get_tree().get_nodes_in_group("enemy"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("midboss"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("boss"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("enemy_bullet"):
		BulletFactory.release_enemy_bullet(node as Area2D)
	for node in get_tree().get_nodes_in_group("player_bullet"):
		BulletFactory.release_player_bullet(node as Area2D)

func _restart_level() -> void:
	GameState.set_paused(false)  # 带着暂停状态重载场景会把新场景也冻住
	AudioManager.stop_music()    # 新一局从头播 BGM
	get_tree().reload_current_scene()

func _shake_screen(intensity: float = 10.0, duration: float = 0.2) -> void:
	if camera == null:
		return
	# 同帧多次触发（受击+炸弹等）时旧震动未结束会与新 tween 争抢 offset，先杀掉
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
		camera.offset = Vector2.ZERO
	var tw: Tween = create_tween()
	_shake_tween = tw
	var steps: int = max(1, int(duration / 0.04))
	for i in steps:
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(camera, "offset", offset, 0.04)
	tw.tween_property(camera, "offset", Vector2.ZERO, 0.04)
