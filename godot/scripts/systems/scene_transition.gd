extends CanvasLayer
## Global scene transition overlay. Autoloaded singleton.
## Usage: SceneTransition.change_scene("res://scenes/combat.tscn")
##
## Uses a pattern-based shader (transition.gdshader). Per-scene presets pick
## a gradient (transition shape) + pattern (thematic overlay) automatically
## from the destination scene path.

const SHADER := preload("res://shaders/transition.gdshader")
const TEX_GRAD_RADIAL := preload("res://assets/sprites/ui/transitions/gradient_radial.png")
const TEX_GRAD_LINEAR := preload("res://assets/sprites/ui/transitions/gradient_linear.png")
const TEX_PAT_CUNEIFORM := preload("res://assets/sprites/ui/transitions/pattern_cuneiform.png")
const TEX_PAT_ZIGGURAT := preload("res://assets/sprites/ui/transitions/pattern_ziggurat.png")

# Per-scene transition presets. Key = scene file basename (no extension).
const PRESETS := {
	"combat":    {"gradient": "radial", "pattern": "cuneiform", "tiling": 16.0, "rotation": 0.0},
	"library":   {"gradient": "radial", "pattern": "cuneiform", "tiling": 20.0, "rotation": 15.0},
	"event":     {"gradient": "linear", "pattern": "cuneiform", "tiling": 14.0, "rotation": 30.0},
	"map":       {"gradient": "linear", "pattern": "ziggurat",  "tiling": 12.0, "rotation": 0.0},
	"rest_site": {"gradient": "radial", "pattern": "ziggurat",  "tiling": 10.0, "rotation": 0.0},
	"shop":      {"gradient": "linear", "pattern": "ziggurat",  "tiling": 14.0, "rotation": 45.0},
	"main_menu": {"gradient": "radial", "pattern": "cuneiform", "tiling": 18.0, "rotation": 0.0},
}

const DEFAULT_PRESET := {"gradient": "radial", "pattern": "cuneiform", "tiling": 16.0, "rotation": 0.0}

var _overlay: ColorRect
var _material: ShaderMaterial


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS

	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("base_color", Color.BLACK)
	# Width = depth of the transition band; gives shapes room to grow before
	# adjacent ones start appearing. Larger = more overlap between shape lifecycles.
	_material.set_shader_parameter("width", 0.45)
	# Feathering = softness of the per-pixel alpha ramp. With distance-field
	# pattern textures this becomes the fade-in window for each shape.
	_material.set_shader_parameter("shape_feathering", 0.115)
	_material.set_shader_parameter("shape_treshold", 1.0)
	# factor=0.0 → overlay invisible (idle); factor=1.0 → fully covered.
	_material.set_shader_parameter("factor", 0.0)

	_overlay = ColorRect.new()
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = Color.WHITE  # ignored — shader writes COLOR.rgb directly
	_overlay.material = _material
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# Apply a default preset so the shader has textures bound from the start.
	_apply_preset_dict(DEFAULT_PRESET)

	get_viewport().size_changed.connect(_update_resolution)
	_update_resolution()


func _update_resolution() -> void:
	if _material:
		var sz: Vector2 = get_viewport().get_visible_rect().size
		_material.set_shader_parameter("node_resolution", sz)


func _apply_preset_dict(preset: Dictionary) -> void:
	var grad_tex: Texture2D = TEX_GRAD_RADIAL if preset["gradient"] == "radial" else TEX_GRAD_LINEAR
	var pat_tex: Texture2D = TEX_PAT_CUNEIFORM if preset["pattern"] == "cuneiform" else TEX_PAT_ZIGGURAT
	_material.set_shader_parameter("gradient_texture", grad_tex)
	_material.set_shader_parameter("shape_texture", pat_tex)
	_material.set_shader_parameter("shape_tiling", preset["tiling"])
	_material.set_shader_parameter("shape_rotation", preset["rotation"])


func _preset_for_scene(scene_path: String) -> Dictionary:
	# "res://scenes/combat.tscn" → "combat"
	var base := scene_path.get_file().get_basename()
	return PRESETS.get(base, DEFAULT_PRESET)


func change_scene(scene_path: String, duration: float = 0.5) -> void:
	_apply_preset_dict(_preset_for_scene(scene_path))
	_update_resolution()

	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	# Cover phase: factor 0 → 1 (overlay fills the screen).
	tween.tween_method(_set_factor, 0.0, 1.0, duration)
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))
	# Reveal phase: factor 1 → 0 (overlay clears).
	tween.tween_method(_set_factor, 1.0, 0.0, duration)
	tween.tween_callback(func(): _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE)


func _set_factor(v: float) -> void:
	_material.set_shader_parameter("factor", v)
