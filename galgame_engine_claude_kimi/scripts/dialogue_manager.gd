class_name DialogueManager
extends Node

# 对话管理器
# 处理文本显示、打字机效果、自动播放等

signal text_completed
signal text_advanced

@export var typing_speed: float = 0.05  # 每个字符的显示间隔（秒）
@export var auto_advance_delay: float = 2.0  # 自动播放等待时间（秒）

var is_typing: bool = false
var is_auto_play: bool = false
var current_text: String = ""
var display_text: String = ""
var char_index: int = 0

var typing_timer: Timer
var auto_timer: Timer

func _ready():
	typing_timer = Timer.new()
	typing_timer.one_shot = true
	typing_timer.timeout.connect(_on_typing_timer_timeout)
	add_child(typing_timer)

	auto_timer = Timer.new()
	auto_timer.one_shot = true
	auto_timer.timeout.connect(_on_auto_timer_timeout)
	add_child(auto_timer)

# 开始显示文本（打字机效果）
func start_typing(text: String) -> void:
	current_text = text
	display_text = ""
	char_index = 0
	is_typing = true
	typing_timer.start(typing_speed)

# 立即完成当前文本
func skip_typing() -> void:
	if is_typing:
		is_typing = false
		typing_timer.stop()
		display_text = current_text
		emit_signal("text_completed")

# 获取当前显示的文本
func get_display_text() -> String:
	return display_text

# 检查是否正在打字
func is_currently_typing() -> bool:
	return is_typing

# 切换自动播放
func toggle_auto_play() -> void:
	is_auto_play = !is_auto_play
	if is_auto_play and not is_typing:
		start_auto_advance()

# 开始自动前进计时
func start_auto_advance() -> void:
	if is_auto_play:
		auto_timer.start(auto_advance_delay)

# 停止自动播放
func stop_auto_play() -> void:
	is_auto_play = false
	auto_timer.stop()

# 打字机计时器回调
func _on_typing_timer_timeout() -> void:
	if char_index < current_text.length():
		display_text += current_text[char_index]
		char_index += 1
		typing_timer.start(typing_speed)
	else:
		is_typing = false
		emit_signal("text_completed")
		if is_auto_play:
			start_auto_advance()

# 自动前进计时器回调
func _on_auto_timer_timeout() -> void:
	emit_signal("text_advanced")
