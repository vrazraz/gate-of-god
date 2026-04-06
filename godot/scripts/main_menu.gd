extends Control
## Main menu screen. Entry point for the game.

@onready var new_run_button: TextureButton = $VBoxContainer/NewRunButton
@onready var continue_button: TextureButton = $VBoxContainer/ContinueButton
@onready var settings_button: TextureButton = $VBoxContainer/SettingsButton
@onready var tutorial_button: TextureButton = $VBoxContainer/TutorialButton
@onready var exit_button: TextureButton = $VBoxContainer/ExitButton


func _ready() -> void:
	new_run_button.pressed.connect(_on_new_run)
	continue_button.pressed.connect(_on_continue)
	settings_button.pressed.connect(_on_settings)
	tutorial_button.pressed.connect(_on_tutorial)
	exit_button.pressed.connect(_on_exit)

	# Show/hide continue based on save existence
	continue_button.visible = SaveManager.has_save()



func _on_new_run() -> void:
	GameState.start_new_run()
	TutorialManager.on_new_run()
	SceneTransition.change_scene("res://scenes/map.tscn")


func _on_continue() -> void:
	if SaveManager.load_run():
		SceneTransition.change_scene("res://scenes/map.tscn")


func _on_settings() -> void:
	# TODO: Open settings scene
	pass


func _on_tutorial() -> void:
	TutorialManager.start_tutorial()
	GameState.start_new_run()
	SceneTransition.change_scene("res://scenes/map.tscn")


func _on_exit() -> void:
	get_tree().quit()
