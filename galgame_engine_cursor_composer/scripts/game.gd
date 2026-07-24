extends Control

@onready var background_layer: Control = %BackgroundLayer
@onready var character_layer: Control = %CharacterLayer
@onready var dialogue_box: Control = %DialogueBox
@onready var choice_panel: Control = %ChoicePanel
@onready var chapter_title: Label = %ChapterTitle
@onready var menu_button: Button = %MenuButton

var _story: Dictionary = {}
var _node_index: int = 0
var _waiting_choice: bool = false
var _paused: bool = false


func _ready() -> void:
	choice_panel.choice_selected.connect(_on_choice_selected)
	menu_button.pressed.connect(_open_pause_menu)
	_load_story(GameState.current_chapter)
	_node_index = GameState.current_node_index
	_apply_chapter_header()
	_run_from_current()


func _process(delta: float) -> void:
	if not _paused and not _waiting_choice:
		GameState.play_time_seconds += delta


func _load_story(chapter_id: String) -> void:
	_story = StoryLoader.load_chapter(chapter_id)
	if _story.is_empty():
		push_error("无法加载章节")
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _apply_chapter_header() -> void:
	if _story.has("title"):
		chapter_title.text = str(_story["title"])
	if _story.has("bgm") and _node_index == 0:
		var bgm_path := str(_story["bgm"])
		var volume := float(_story.get("bgm_volume", -10.0))
		AudioManager.play_bgm(bgm_path, 0.0, volume)


func _run_from_current() -> void:
	var nodes: Array = _story.get("nodes", [])
	while _node_index < nodes.size():
		var node: Dictionary = nodes[_node_index]
		GameState.current_node_index = _node_index
		var node_type: String = str(node.get("type", "dialogue"))
		match node_type:
			"bg":
				background_layer.apply(node)
				_node_index += 1
			"show":
				_show_character(node)
				_node_index += 1
			"hide":
				character_layer.hide_character(str(node.get("id", "")))
				_node_index += 1
			"hide_all":
				character_layer.hide_all()
				_node_index += 1
			"expression":
				character_layer.set_expression(str(node.get("id", "")), str(node.get("expression", "default")))
				_node_index += 1
			"dialogue":
				await _play_dialogue(node)
				_node_index += 1
			"choice":
				await _play_choice(node)
				return
			"jump":
				_node_index = int(node.get("index", _node_index + 1))
			"set_flag":
				_apply_flags(node)
				_node_index += 1
			"if_flag":
				if GameState.get_flag(str(node.get("flag", "")), false):
					_node_index = int(node.get("then", _node_index + 1))
				else:
					_node_index = int(node.get("else", _node_index + 1))
			"bgm":
				_play_bgm(node)
				_node_index += 1
			"bgm_stop":
				AudioManager.stop_bgm(float(node.get("fade", 1.0)))
				_node_index += 1
			"se":
				AudioManager.play_se(str(node.get("path", "")), float(node.get("volume", -6.0)))
				_node_index += 1
			"chapter":
				await _load_chapter_and_continue(str(node.get("id", "")), node)
				return
			"end":
				await _show_ending(node)
				return
			_:
				_node_index += 1
	_check_chapter_complete()


func _show_character(node: Dictionary) -> void:
	var char_id := str(node.get("id", "unknown"))
	var slot := str(node.get("slot", "center"))
	var color := str(node.get("color", "#cccccc"))
	var name_text := str(node.get("name", char_id))
	var image_path := str(node.get("image", ""))
	var expression := str(node.get("expression", "default"))
	character_layer.show_character(char_id, name_text, slot, color, true, image_path, expression)
	character_layer.set_active(char_id)


func _play_dialogue(node: Dictionary) -> void:
	var speaker := str(node.get("speaker", ""))
	var text := str(node.get("text", ""))
	if node.has("active"):
		character_layer.set_active(str(node["active"]))
	if node.has("expression") and node.has("active"):
		character_layer.set_expression(str(node["active"]), str(node["expression"]))
	dialogue_box.show_line(speaker, text)
	await dialogue_box.typing_finished
	await _wait_advance()


func _wait_advance() -> void:
	await dialogue_box.advance_requested


func _play_choice(node: Dictionary) -> void:
	_waiting_choice = true
	dialogue_box.visible = false
	var options: Array = node.get("options", [])
	choice_panel.show_choices(options)
	await choice_panel.choice_selected
	AudioManager.play_se("res://assets/audio/se/click.wav", -8.0)
	_waiting_choice = false
	dialogue_box.visible = true


func _play_bgm(node: Dictionary) -> void:
	var path := str(node.get("path", ""))
	var fade := float(node.get("fade", 1.0))
	var volume := float(node.get("volume", -10.0))
	AudioManager.play_bgm(path, fade, volume)


func _on_choice_selected(index: int) -> void:
	var nodes: Array = _story.get("nodes", [])
	var node: Dictionary = nodes[_node_index]
	var options: Array = node.get("options", [])
	if index >= options.size():
		return
	var chosen: Dictionary = options[index]
	if chosen.has("set_flag"):
		var flag_data: Variant = chosen["set_flag"]
		if typeof(flag_data) == TYPE_DICTIONARY:
			for key in flag_data:
				GameState.set_flag(str(key), flag_data[key])
		else:
			GameState.set_flag(str(flag_data), true)
	_node_index = int(chosen.get("goto", _node_index + 1))
	_run_from_current()


func _apply_flags(node: Dictionary) -> void:
	var flag_data: Variant = node.get("flags", {})
	if typeof(flag_data) == TYPE_DICTIONARY:
		for key in flag_data:
			GameState.set_flag(str(key), flag_data[key])


func _load_chapter_and_continue(chapter_id: String, node: Dictionary = {}) -> void:
	if not StoryLoader.is_chapter_unlocked(chapter_id):
		dialogue_box.show_line("系统", "该章节尚未解锁。")
		await dialogue_box.typing_finished
		await dialogue_box.advance_requested
		_node_index += 1
		_run_from_current()
		return
	var fade := float(node.get("fade_bgm", 0.0))
	if fade > 0.0:
		AudioManager.stop_bgm(fade)
		await get_tree().create_timer(fade * 0.5).timeout
	character_layer.hide_all()
	GameState.current_chapter = chapter_id
	GameState.current_node_index = 0
	_node_index = 0
	_load_story(chapter_id)
	_apply_chapter_header()
	_run_from_current()


func _check_chapter_complete() -> void:
	var nodes: Array = _story.get("nodes", [])
	if _node_index >= nodes.size():
		_show_chapter_complete()


func _show_chapter_complete() -> void:
	dialogue_box.show_line("系统", "本章剧情已结束。感谢游玩！")
	await dialogue_box.typing_finished
	await dialogue_box.advance_requested
	_return_to_title()


func _show_ending(node: Dictionary) -> void:
	var title := str(node.get("title", "END"))
	var text := str(node.get("text", ""))
	dialogue_box.show_line(title, text)
	await dialogue_box.typing_finished
	await dialogue_box.advance_requested
	_return_to_title()


func _return_to_title() -> void:
	AudioManager.stop_bgm(1.5)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _open_pause_menu() -> void:
	_paused = true
	AudioManager.set_paused(true)
	var dialog := AcceptDialog.new()
	dialog.title = "菜单"
	dialog.dialog_text = "选择操作"
	dialog.ok_button_text = "继续"
	add_child(dialog)
	dialog.add_button("保存", false, "save")
	dialog.add_button("返回标题", true, "title")
	dialog.custom_action.connect(func(action: StringName) -> void:
		match action:
			"save":
				if GameState.save_game():
					dialog.dialog_text = "存档成功！"
				else:
					dialog.dialog_text = "存档失败。"
			"title":
				dialog.hide()
				_return_to_title()
	)
	dialog.canceled.connect(func() -> void:
		_paused = false
		AudioManager.set_paused(false)
		dialog.queue_free()
	)
	dialog.confirmed.connect(func() -> void:
		_paused = false
		AudioManager.set_paused(false)
		dialog.queue_free()
	)
	dialog.popup_centered()
