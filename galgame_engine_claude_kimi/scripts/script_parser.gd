class_name ScriptParser
extends Node

# JSON 脚本解析器
# 负责加载和解析 JSON 格式的剧本文件

var script_data: Dictionary = {}
var current_scene_id: String = ""
var current_line_index: int = 0

# 加载剧本文件
func load_script(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("Script file not found: " + path)
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open script file: " + path)
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("JSON parse error: " + json.get_error_message() + " at line " + str(json.get_error_line()))
		return false

	script_data = json.data

	# 验证必要字段
	if not script_data.has("scenes"):
		push_error("Script missing 'scenes' field")
		return false

	return true

# 跳转到指定场景
func jump_to_scene(scene_id: String) -> bool:
	for scene in script_data.scenes:
		if scene.id == scene_id:
			current_scene_id = scene_id
			current_line_index = 0
			return true
	push_error("Scene not found: " + scene_id)
	return false

# 获取当前行
func get_current_line() -> Dictionary:
	var scene = get_current_scene()
	if scene == null:
		return {}

	if current_line_index >= scene.lines.size():
		return {}

	return scene.lines[current_line_index]

# 前进到下一行
func advance() -> bool:
	var scene = get_current_scene()
	if scene == null:
		return false

	current_line_index += 1
	return current_line_index < scene.lines.size()

# 获取当前场景
func get_current_scene() -> Dictionary:
	for scene in script_data.scenes:
		if scene.id == current_scene_id:
			return scene
	return {}

# 检查是否还有更多行
func has_more_lines() -> bool:
	var scene = get_current_scene()
	if scene == null:
		return false
	return current_line_index < scene.lines.size()

# 获取当前场景ID
func get_scene_id() -> String:
	return current_scene_id

# 获取当前行号
func get_line_index() -> int:
	return current_line_index

# 保存状态
func save_state() -> Dictionary:
	return {
		"scene_id": current_scene_id,
		"line_index": current_line_index
	}

# 加载状态
func load_state(state: Dictionary) -> void:
	if state.has("scene_id"):
		current_scene_id = state.scene_id
	if state.has("line_index"):
		current_line_index = state.line_index
