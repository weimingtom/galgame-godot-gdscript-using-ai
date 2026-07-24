extends Node

## 全局游戏状态：剧情标记、存档、当前进度

signal flags_changed

const SAVE_PATH := "user://savegame.json"

var current_chapter: String = "chapter1"
var current_node_index: int = 0
var flags: Dictionary = {}
var play_time_seconds: float = 0.0


func _ready() -> void:
	set_process(false)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func set_flag(key: String, value: Variant = true) -> void:
	flags[key] = value
	flags_changed.emit()


func get_flag(key: String, default: Variant = false) -> Variant:
	return flags.get(key, default)


func reset_for_new_game() -> void:
	current_chapter = "chapter1"
	current_node_index = 0
	flags.clear()
	play_time_seconds = 0.0


func save_game() -> bool:
	var data := {
		"chapter": current_chapter,
		"node_index": current_node_index,
		"flags": flags.duplicate(true),
		"play_time": play_time_seconds,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("无法写入存档: %s" % SAVE_PATH)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	current_chapter = str(parsed.get("chapter", "chapter1"))
	current_node_index = int(parsed.get("node_index", 0))
	flags = parsed.get("flags", {}).duplicate(true)
	play_time_seconds = float(parsed.get("play_time", 0.0))
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
