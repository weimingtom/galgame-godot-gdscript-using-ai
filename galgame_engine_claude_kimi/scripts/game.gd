extends Control

# 主游戏控制器
# 管理整个 Galgame 的运行流程

@onready var background = $Background
@onready var character_left = $CharacterLeft
@onready var character_center = $CharacterCenter
@onready var character_right = $CharacterRight
@onready var dialogue_panel = $DialoguePanel
@onready var speaker_label = $DialoguePanel/SpeakerLabel
@onready var text_label = $DialoguePanel/TextLabel
@onready var choices_container = $ChoicesContainer
@onready var choices_vbox = $ChoicesContainer/VBoxContainer
@onready var auto_indicator = $AutoIndicator
@onready var save_load_panel = $SaveLoadPanel

var script_parser: ScriptParser
var dialogue_manager: DialogueManager

var current_background: String = ""
var current_characters: Dictionary = {}
var is_waiting_for_input: bool = false
var is_in_choice: bool = false

# 脚本文件路径
@export var script_path: String = "res://resources/demo_script.json"

func _ready():
	# 初始化解析器和对话管理器
	script_parser = ScriptParser.new()
	dialogue_manager = DialogueManager.new()
	add_child(dialogue_manager)

	# 连接信号
	dialogue_manager.text_completed.connect(_on_text_completed)
	dialogue_manager.text_advanced.connect(_on_text_advanced)

	# 隐藏UI元素
	choices_container.hide()
	save_load_panel.hide()
	dialogue_panel.hide()

	# 加载剧本
	if script_parser.load_script(script_path):
		# 从第一个场景开始
		if script_parser.script_data.scenes.size() > 0:
			var first_scene = script_parser.script_data.scenes[0]
			start_scene(first_scene.id)
	else:
		text_label.text = "无法加载剧本文件！"

func _input(event):
	if is_in_choice:
		return

	if save_load_panel.visible:
		if event.is_action_pressed("ui_skip"):
			save_load_panel.hide()
			get_viewport().set_input_as_handled()
		return

	# 空格或点击继续
	if event.is_action_pressed("ui_advance"):
		if dialogue_manager.is_currently_typing():
			# 如果正在打字，立即完成
			dialogue_manager.skip_typing()
		elif is_waiting_for_input:
			# 等待输入时，前进到下一句
			advance_line()
		get_viewport().set_input_as_handled()

	# ESC 或 Enter 跳过
	if event.is_action_pressed("ui_skip"):
		if dialogue_manager.is_currently_typing():
			dialogue_manager.skip_typing()
		get_viewport().set_input_as_handled()

	# A 键切换自动播放
	if event.is_action_pressed("ui_auto"):
		toggle_auto_play()
		get_viewport().set_input_as_handled()

	# S 键保存
	if event.is_action_pressed("ui_save"):
		show_save_menu()
		get_viewport().set_input_as_handled()

	# L 键读取
	if event.is_action_pressed("ui_load"):
		show_load_menu()
		get_viewport().set_input_as_handled()

# 开始场景
func start_scene(scene_id: String) -> void:
	script_parser.jump_to_scene(scene_id)
	dialogue_panel.show()
	process_current_line()

# 处理当前行
func process_current_line() -> void:
	if not script_parser.has_more_lines():
		# 场景结束，检查是否有默认跳转
		var scene = script_parser.get_current_scene()
		if scene.has("next_scene"):
			start_scene(scene.next_scene)
		else:
			text_label.text = "—— 结束 ——"
			speaker_label.text = ""
		return

	var line = script_parser.get_current_line()
	var line_type = line.get("type", "dialogue")

	match line_type:
		"dialogue":
			process_dialogue(line)
		"narration":
			process_narration(line)
		"choice":
			process_choice(line)
		"scene_change":
			process_scene_change(line)
		"bgm":
			process_bgm(line)
		"sfx":
			process_sfx(line)
		"wait":
			process_wait(line)
		_:
			# 未知类型，跳过
			advance_line()

# 处理对话
func process_dialogue(line: Dictionary) -> void:
	is_waiting_for_input = false

	# 更新说话人
	var speaker = line.get("speaker", "")
	speaker_label.text = speaker

	# 更新背景
	if line.has("background"):
		change_background(line.background)

	# 更新角色立绘
	if line.has("character"):
		var position = line.get("position", "center")
		var expression = line.get("expression", "")
		update_character(line.character, position, expression)

	# 隐藏角色
	if line.has("hide_character"):
		hide_character(line.hide_character)

	# 应用效果
	if line.has("effect"):
		apply_effect(line.effect)

	# 开始打字机效果
	var text = line.get("text", "")
	dialogue_manager.start_typing(text)

# 处理旁白
func process_narration(line: Dictionary) -> void:
	speaker_label.text = ""

	if line.has("background"):
		change_background(line.background)

	var text = line.get("text", "")
	dialogue_manager.start_typing(text)

# 处理分支选项
func process_choice(line: Dictionary) -> void:
	is_in_choice = true
	choices_container.show()

	# 清除旧选项
	for child in choices_vbox.get_children():
		child.queue_free()

	var options = line.get("options", [])
	for option in options:
		var btn = Button.new()
		btn.text = option.get("text", "选项")
		btn.custom_minimum_size = Vector2(400, 50)
		btn.pressed.connect(_on_choice_selected.bind(option))
		choices_vbox.add_child(btn)

# 处理场景切换
func process_scene_change(line: Dictionary) -> void:
	var target = line.get("target", "")
	if target != "":
		start_scene(target)
	else:
		advance_line()

# 处理BGM
func process_bgm(line: Dictionary) -> void:
	var bgm_path = line.get("path", "")
	var action = line.get("action", "play")

	# 简化实现：这里可以扩展为实际的 AudioStreamPlayer 控制
	match action:
		"play":
			print("播放BGM: " + bgm_path)
		"stop":
			print("停止BGM")

	advance_line()

# 处理音效
func process_sfx(line: Dictionary) -> void:
	var sfx_path = line.get("path", "")
	print("播放音效: " + sfx_path)
	advance_line()

# 处理等待
func process_wait(line: Dictionary) -> void:
	var duration = line.get("duration", 1.0)
	await get_tree().create_timer(duration).timeout
	advance_line()

# 前进到下一行
func advance_line() -> void:
	if is_in_choice:
		return

	if script_parser.advance():
		process_current_line()
	else:
		# 场景结束
		var scene = script_parser.get_current_scene()
		if scene.has("next_scene"):
			start_scene(scene.next_scene)
		else:
			text_label.text = "—— 结束 ——"
			speaker_label.text = ""

# 文本完成回调
func _on_text_completed() -> void:
	is_waiting_for_input = true
	if dialogue_manager.is_auto_play:
		dialogue_manager.start_auto_advance()

# 自动前进回调
func _on_text_advanced() -> void:
	if is_waiting_for_input:
		advance_line()

# 选项选择回调
func _on_choice_selected(option: Dictionary) -> void:
	is_in_choice = false
	choices_container.hide()

	# 检查条件（简化实现）
	if option.has("condition"):
		var condition = option.condition
		if not check_condition(condition):
			# 条件不满足，显示提示并返回
			text_label.text = "条件不满足"
			return

	# 执行效果
	if option.has("effects"):
		for effect in option.effects:
			apply_game_effect(effect)

	# 跳转到目标
	if option.has("target"):
		start_scene(option.target)
	else:
		advance_line()

# 检查条件
func check_condition(condition: Dictionary) -> bool:
	# 简化实现，可根据需要扩展
	return true

# 应用游戏效果（变量修改等）
func apply_game_effect(effect: Dictionary) -> void:
	var effect_type = effect.get("type", "")
	match effect_type:
		"set_variable":
			var var_name = effect.get("name", "")
			var var_value = effect.get("value", "")
			print("设置变量: " + var_name + " = " + str(var_value))

# 切换背景
func change_background(path: String) -> void:
	if path == current_background:
		return

	current_background = path
	if path == "" or path == "none":
		background.texture = null
		return

	var texture = load(path)
	if texture != null:
		background.texture = texture
	else:
		push_warning("Failed to load background: " + path)

# 更新角色立绘
func update_character(character_path: String, position: String, expression: String = "") -> void:
	var target_node: TextureRect
	match position:
		"left":
			target_node = character_left
		"right":
			target_node = character_right
		_:
			target_node = character_center

	# 构建完整路径（支持表情后缀）
	var full_path = character_path
	if expression != "":
		full_path = character_path.replace(".png", "_" + expression + ".png")

	var texture = load(full_path)
	if texture != null:
		target_node.texture = texture
		target_node.show()
		current_characters[position] = character_path
	else:
		push_warning("Failed to load character: " + full_path)

# 隐藏角色
func hide_character(position: String) -> void:
	match position:
		"left":
			character_left.hide()
			character_left.texture = null
		"right":
			character_right.hide()
			character_right.texture = null
		"center":
			character_center.hide()
			character_center.texture = null
		"all":
			character_left.hide()
			character_right.hide()
			character_center.hide()
			character_left.texture = null
			character_right.texture = null
			character_center.texture = null

	current_characters.erase(position)

# 应用视觉效果
func apply_effect(effect_name: String) -> void:
	match effect_name:
		"fade_in":
			modulate.a = 0
			var tween = create_tween()
			tween.tween_property(self, "modulate:a", 1.0, 0.5)
		"fade_out":
			var tween = create_tween()
			tween.tween_property(self, "modulate:a", 0.0, 0.5)
		"shake":
			var original_pos = position
			var tween = create_tween()
			for i in range(10):
				tween.tween_property(self, "position", original_pos + Vector2(randi() % 10 - 5, randi() % 10 - 5), 0.05)
			tween.tween_property(self, "position", original_pos, 0.05)
		"flash":
			var flash = ColorRect.new()
			flash.color = Color.WHITE
			flash.size = get_viewport_rect().size
			flash.z_index = 100
			add_child(flash)
			var tween = create_tween()
			tween.tween_property(flash, "modulate:a", 0.0, 0.3)
			tween.tween_callback(flash.queue_free)

# 切换自动播放
func toggle_auto_play() -> void:
	dialogue_manager.toggle_auto_play()
	auto_indicator.visible = dialogue_manager.is_auto_play

# 保存游戏
func save_game(slot: int = 0) -> void:
	var save_data = {
		"script_state": script_parser.save_state(),
		"background": current_background,
		"characters": current_characters
	}

	var save_path = "user://save_" + str(slot) + ".json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("游戏已保存到槽位 " + str(slot))
	else:
		push_error("保存失败")

# 读取游戏
func load_game(slot: int = 0) -> bool:
	var save_path = "user://save_" + str(slot) + ".json"
	if not FileAccess.file_exists(save_path):
		return false

	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		return false

	var save_data = json.data

	# 恢复脚本状态
	if save_data.has("script_state"):
		script_parser.load_state(save_data.script_state)

	# 恢复背景
	if save_data.has("background"):
		change_background(save_data.background)

	# 恢复角色
	if save_data.has("characters"):
		for pos in save_data.characters:
			update_character(save_data.characters[pos], pos)

	# 继续游戏
	is_in_choice = false
	choices_container.hide()
	process_current_line()

	print("游戏已从槽位 " + str(slot) + " 读取")
	return true

# 显示保存菜单（简化实现）
func show_save_menu() -> void:
	save_game(0)
	# 可以扩展为更复杂的UI
	print("快速保存完成（按S）")

# 显示读取菜单（简化实现）
func show_load_menu() -> void:
	load_game(0)
	print("快速读取完成（按L）")

func _process(delta):
	# 更新文本显示
	if dialogue_manager:
		text_label.text = dialogue_manager.get_display_text()
