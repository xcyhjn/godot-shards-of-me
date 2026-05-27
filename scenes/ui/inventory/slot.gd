extends PanelContainer
class_name Slot

@onready var texture_rect = $TextureRect

## 当前格子的物品 id（"" 表示空）
var item_id : String = ""
## 面板样式（用于悬停效果）
var panel_style: StyleBoxFlat

## 是否被填满（兼容旧调用方）
var filled : bool:
	get: return item_id != ""

func _ready():
	panel_style = get_theme_stylebox("panel").duplicate()
	add_theme_stylebox_override("panel", panel_style)
	# 预留 3px 边框空间，避免 hover 时 minimum_size 变化挤压邻居
	panel_style.content_margin_left = 3
	panel_style.content_margin_top = 3
	panel_style.content_margin_right = 3
	panel_style.content_margin_bottom = 3
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.6, 0.5, 0.9, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

## 用 id 设置格子内容；id 为空字符串时清空
func set_item_id(id: String) -> void:
	item_id = id
	if id == "":
		texture_rect.texture = null
		return
	var tex_path : String = ItemData.get_texture(id)
	texture_rect.texture = load(tex_path) if tex_path != "" else null

func clear_item() -> void:
	set_item_id("")

func _on_mouse_entered() -> void:
	panel_style.border_color = Color(0.6, 0.5, 0.9, 1)

func _on_mouse_exited() -> void:
	panel_style.border_color = Color(0.6, 0.5, 0.9, 0)

func _get_drag_data(_at_position):
	if item_id == "":
		return null
	set_drag_preview(get_preview())
	return self

func _can_drop_data(_pos, data):
	return data is Slot and data != self

# 缩略图
func get_preview():
	var thumb = TextureRect.new()
	thumb.texture = texture_rect.texture
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.size = texture_rect.size
	var preview = Control.new()
	preview.add_child(thumb)
	return preview
