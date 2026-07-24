extends Node

## 加载剧情 JSON 与章节清单

const STORY_DIR := "res://data/"
const CHAPTERS_MANIFEST := "res://data/chapters.json"


func load_chapter(chapter_id: String) -> Dictionary:
	var path := STORY_DIR + chapter_id + ".json"
	if not FileAccess.file_exists(path):
		push_error("剧情文件不存在: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("剧情 JSON 格式错误: %s" % path)
		return {}
	if not parsed.has("nodes") or typeof(parsed["nodes"]) != TYPE_ARRAY:
		push_error("剧情缺少 nodes 数组: %s" % path)
		return {}
	return parsed


func load_chapters_manifest() -> Array:
	if not FileAccess.file_exists(CHAPTERS_MANIFEST):
		return []
	var file := FileAccess.open(CHAPTERS_MANIFEST, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	return parsed.get("chapters", [])


func get_chapter_entry(chapter_id: String) -> Dictionary:
	for entry in load_chapters_manifest():
		if typeof(entry) == TYPE_DICTIONARY and str(entry.get("id", "")) == chapter_id:
			return entry
	return {}


func is_chapter_unlocked(chapter_id: String) -> bool:
	var entry := get_chapter_entry(chapter_id)
	if entry.is_empty():
		return true
	if not entry.has("requires"):
		return true
	return bool(GameState.get_flag(str(entry["requires"]), false))


func get_next_chapter(current_id: String) -> String:
	var chapters := load_chapters_manifest()
	for i in chapters.size():
		var entry: Dictionary = chapters[i]
		if str(entry.get("id", "")) == current_id and i + 1 < chapters.size():
			return str(chapters[i + 1].get("id", ""))
	return ""
