extends ColorRect

const FLASH_DURATION: float = 0.5

func _ready() -> void:
	color = Color(1, 1, 1, 0.6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw: Tween = create_tween()
	tw.tween_property(self, "color:a", 0.0, FLASH_DURATION)
	tw.tween_callback(queue_free)
