extends Node2D
## 得分飘字（池化）：activate 时设置文本/颜色/位置并跑 Tween，结束后回池。

const FONT_SIZE: int = 24
const BOX_WIDTH: float = 160.0
const RISE: float = 42.0
const LIFE: float = 0.7

var text: String = ""
var text_color: Color = Color(1.0, 0.95, 0.4)
var _tween: Tween = null

func activate(pos: Vector2, popup_text: String, color: Color) -> void:
	global_position = pos
	text = popup_text
	text_color = color
	scale = Vector2(0.5, 0.5)
	modulate = Color.WHITE
	visible = true
	queue_redraw()
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position:y", position.y - RISE, LIFE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 0.0, LIFE * 0.7).set_delay(LIFE * 0.3)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_callback(func() -> void: BulletFactory.release_score_popup(self))

func deactivate() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	visible = false

func _draw() -> void:
	var font := get_tree().root.get_theme_default_font()
	draw_string(font, Vector2(-BOX_WIDTH * 0.5, -FONT_SIZE * 0.5), text, HORIZONTAL_ALIGNMENT_CENTER, BOX_WIDTH, FONT_SIZE, text_color)
