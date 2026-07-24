extends Control

signal choice_selected(index: int)

@onready var button_container: VBoxContainer = %ButtonContainer


func show_choices(options: Array) -> void:
	_clear_buttons()
	for i in options.size():
		var option: Dictionary = options[i]
		var btn := Button.new()
		btn.text = str(option.get("text", "……"))
		btn.custom_minimum_size = Vector2(600, 48)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var idx := i
		btn.pressed.connect(func() -> void:
			_on_choice(idx)
		)
		button_container.add_child(btn)
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func hide_choices() -> void:
	visible = false
	_clear_buttons()


func _clear_buttons() -> void:
	for child in button_container.get_children():
		child.queue_free()


func _on_choice(index: int) -> void:
	hide_choices()
	choice_selected.emit(index)
