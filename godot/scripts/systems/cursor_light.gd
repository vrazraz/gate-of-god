extends CanvasLayer
## Global cursor glow. Autoloaded singleton.
## Renders a soft warm radial halo that follows the mouse cursor in every scene.

const GLOW_TEXTURE_PATH := "res://assets/sprites/ui/cursor_glow.png"
const GLOW_ALPHA := 0.22

var _glow_rect: TextureRect = null


func _ready() -> void:
	# Above gameplay + pause menu (100), below scene transitions (200).
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not ResourceLoader.exists(GLOW_TEXTURE_PATH):
		push_warning("[CursorLight] glow texture missing: " + GLOW_TEXTURE_PATH)
		return

	var tex: Texture2D = load(GLOW_TEXTURE_PATH)
	_glow_rect = TextureRect.new()
	_glow_rect.texture = tex
	_glow_rect.size = tex.get_size()
	_glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow_rect.modulate = Color(1.0, 1.0, 1.0, GLOW_ALPHA)

	# Additive blend so the glow tints content underneath instead of replacing it.
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow_rect.material = mat

	add_child(_glow_rect)


func _process(_delta: float) -> void:
	if _glow_rect == null:
		return
	var pos: Vector2 = get_viewport().get_mouse_position()
	_glow_rect.position = pos - _glow_rect.size / 2.0
