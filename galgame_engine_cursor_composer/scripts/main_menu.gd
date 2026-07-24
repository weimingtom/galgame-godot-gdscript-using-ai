extends Control

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var quit_button: Button = %QuitButton
@onready var subtitle: Label = %Subtitle


func _ready() -> void:
	continue_button.disabled = not GameState.has_save()
	start_button.pressed.connect(_on_start)
	continue_button.pressed.connect(_on_continue)
	quit_button.pressed.connect(_on_quit)
	AudioManager.play_bgm("res://assets/audio/bgm/title.wav", 1.0, -12.0)


func _on_start() -> void:
	GameState.reset_for_new_game()
	AudioManager.stop_bgm(0.8)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_continue() -> void:
	if GameState.load_game():
		AudioManager.stop_bgm(0.8)
		get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_quit() -> void:
	get_tree().quit()
