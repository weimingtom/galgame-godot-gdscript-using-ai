extends Control

@onready var name_label: Label = %NameLabel
@onready var text_label: RichTextLabel = %TextLabel
@onready var continue_indicator: Label = %ContinueIndicator

const CHARS_PER_SECOND := 40.0

var _full_text: String = ""
var _visible_chars: int = 0
var _typing: bool = false
var _finished: bool = false

signal typing_finished
signal advance_requested


func _ready() -> void:
	continue_indicator.visible = false
	text_label.visible_characters = 0


var _accum_time: float = 0.0


func _process(delta: float) -> void:
	if not _typing:
		return
	_accum_time += delta
	var target := int(_accum_time * CHARS_PER_SECOND)
	target = mini(target, _full_text.length())
	if target > _visible_chars:
		_visible_chars = target
		text_label.visible_characters = _visible_chars
	if _visible_chars >= _full_text.length():
		_finish_typing()


func show_line(speaker: String, text: String) -> void:
	_full_text = text
	_visible_chars = 0
	_accum_time = 0.0
	_typing = true
	_finished = false
	continue_indicator.visible = false

	name_label.text = speaker
	text_label.text = text
	text_label.visible_characters = 0
	set_process(true)


func skip_typing() -> void:
	if _typing:
		_visible_chars = _full_text.length()
		text_label.visible_characters = _visible_chars
		_finish_typing()


func is_typing() -> bool:
	return _typing


func is_finished() -> bool:
	return _finished and not _typing


func _finish_typing() -> void:
	_typing = false
	_finished = true
	continue_indicator.visible = true
	set_process(false)
	typing_finished.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("skip_typing") and _typing:
		skip_typing()
		if get_viewport_rect():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("advance_dialogue") and _finished:
		advance_requested.emit()
		if get_viewport_rect():
			get_viewport().set_input_as_handled()
