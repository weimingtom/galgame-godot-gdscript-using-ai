extends Control

## 三站位角色层，支持立绘图片与表情切换

const SLOT_POSITIONS := {
	"left": Vector2(180, 520),
	"center": Vector2(640, 520),
	"right": Vector2(1100, 520),
}
const PORTRAIT_SIZE := Vector2(280, 480)

var _characters: Dictionary = {}


func show_character(
	id: String,
	display_name: String,
	slot: String,
	color: String,
	highlight: bool = true,
	image_path: String = "",
	expression: String = "default",
) -> void:
	if not SLOT_POSITIONS.has(slot):
		slot = "center"
	var resolved_image := _resolve_image_path(id, image_path, expression)
	if _characters.has(id):
		var existing: Control = _characters[id]
		if resolved_image != "":
			_set_portrait_image(existing, resolved_image)
		_move_to_slot(existing, slot)
		_set_highlight(existing, highlight)
		return
	var panel := _create_character_panel(display_name, color, resolved_image)
	panel.set_meta("slot", slot)
	panel.set_meta("id", id)
	panel.set_meta("expression", expression)
	add_child(panel)
	_characters[id] = panel
	_move_to_slot(panel, slot)
	_set_highlight(panel, highlight)


func hide_character(id: String) -> void:
	if not _characters.has(id):
		return
	var panel: Control = _characters[id]
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(panel.queue_free)
	_characters.erase(id)


func hide_all() -> void:
	for id in _characters.keys().duplicate():
		hide_character(id)


func set_active(id: String) -> void:
	for char_id in _characters:
		_set_highlight(_characters[char_id], char_id == id)


func set_expression(id: String, expression: String) -> void:
	if not _characters.has(id):
		return
	var path := _resolve_image_path(id, "", expression)
	if path == "":
		return
	var panel: Control = _characters[id]
	panel.set_meta("expression", expression)
	_set_portrait_image(panel, path)


func _resolve_image_path(id: String, image_override: String, expression: String) -> String:
	if image_override != "" and ResourceLoader.exists(image_override):
		return image_override
	var expr := expression if expression != "" else "default"
	var path := "res://assets/characters/%s/%s.svg" % [id, expr]
	if ResourceLoader.exists(path):
		return path
	path = "res://assets/characters/%s/default.svg" % id
	if ResourceLoader.exists(path):
		return path
	return ""


func _create_character_panel(display_name: String, color_hex: String, image_path: String) -> Control:
	var root := Control.new()
	root.custom_minimum_size = PORTRAIT_SIZE
	root.pivot_offset = PORTRAIT_SIZE * 0.5
	var portrait := _build_portrait(image_path, color_hex)
	portrait.position = Vector2(0, 36)
	root.add_child(portrait)
	portrait.set_meta("portrait", true)
	var name_tag := Label.new()
	name_tag.text = display_name
	name_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_tag.add_theme_font_size_override("font_size", 18)
	name_tag.position = Vector2(0, 0)
	name_tag.size = Vector2(PORTRAIT_SIZE.x, 32)
	root.add_child(name_tag)
	root.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(root, "modulate:a", 1.0, 0.4)
	return root


func _build_portrait(image_path: String, color_hex: String) -> Control:
	if image_path != "":
		var tex_rect := TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(PORTRAIT_SIZE.x, PORTRAIT_SIZE.y - 36)
		tex_rect.size = tex_rect.custom_minimum_size
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture = load(image_path)
		return tex_rect
	var body := ColorRect.new()
	body.color = Color.from_string(color_hex, Color.WHITE)
	body.custom_minimum_size = Vector2(PORTRAIT_SIZE.x, PORTRAIT_SIZE.y - 36)
	body.size = body.custom_minimum_size
	return body


func _set_portrait_image(panel: Control, image_path: String) -> void:
	for child in panel.get_children():
		if child.get_meta("portrait", false):
			child.queue_free()
	var portrait := _build_portrait(image_path, "#cccccc")
	portrait.position = Vector2(0, 36)
	panel.add_child(portrait)
	portrait.set_meta("portrait", true)


func _move_to_slot(panel: Control, slot: String) -> void:
	var target: Vector2 = SLOT_POSITIONS[slot]
	panel.set_meta("slot", slot)
	var dest := target - Vector2(PORTRAIT_SIZE.x * 0.5, PORTRAIT_SIZE.y)
	var tween := create_tween()
	tween.tween_property(panel, "position", dest, 0.25)


func _set_highlight(panel: Control, active: bool) -> void:
	var tween := create_tween()
	if active:
		tween.tween_property(panel, "modulate", Color(1.1, 1.1, 1.1, 1.0), 0.2)
		tween.parallel().tween_property(panel, "scale", Vector2(1.04, 1.04), 0.2)
	else:
		tween.tween_property(panel, "modulate", Color(0.55, 0.55, 0.6, 0.88), 0.2)
		tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.2)
