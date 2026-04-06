extends CanvasLayer
## Global scene transition overlay. Autoloaded singleton.
## Usage: SceneTransition.change_scene("res://scenes/combat.tscn")

var _overlay: ColorRect


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS

	_overlay = ColorRect.new()
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = Color(0, 0, 0, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)


func change_scene(scene_path: String, duration: float = 0.4) -> void:
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, duration)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(scene_path)
	)
	tween.tween_property(_overlay, "color:a", 0.0, duration)
	tween.tween_callback(func():
		_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
