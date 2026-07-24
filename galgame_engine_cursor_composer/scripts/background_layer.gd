extends Control

@onready var _color_rect: ColorRect = %ColorRect
@onready var _texture_rect: TextureRect = %TextureRect


func apply(node: Dictionary) -> void:
	if node.has("color"):
		_color_rect.color = Color.from_string(str(node["color"]), Color("#1a1a2e"))
	if node.has("image"):
		var path := str(node["image"])
		if ResourceLoader.exists(path):
			_texture_rect.texture = load(path)
			_texture_rect.visible = true
		else:
			push_warning("背景图片不存在: %s" % path)
			_texture_rect.visible = false
	else:
		_texture_rect.visible = false
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(0.75, 0.75, 0.75, 1.0), 0.12)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
