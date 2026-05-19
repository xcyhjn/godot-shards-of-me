extends PanelContainer
class_name Slot

@onready var texture_rect = $TextureRect
@onready var debug = %debug

## 格子是否被填满（有物品）
var filled: bool = false
## 当前格子的物品信息
var item_info: Dictionary = {}
## 面板样式（用于悬停效果）
var panel_style: StyleBoxFlat

func _ready():
	panel_style = get_theme_stylebox("panel").duplicate()
	add_theme_stylebox_override("panel", panel_style)
	# 预留 3px 边框空间，避免 hover 时 minimum_size 变化挤压邻居
	panel_style.content_margin_left = 3
	panel_style.content_margin_top = 3
	panel_style.content_margin_right = 3
	panel_style.content_margin_bottom = 3
	# 默认 border 透明，hover 时只切换颜色
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.6, 0.5, 0.9, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func set_item(data: Dictionary):
	item_info = data.duplicate()
	texture_rect.texture = data.get("TEXTURE", null)
	debug.text = data.get("name", "")
	filled = true

func clear_item():
	item_info = {}
	texture_rect.texture = null
	debug.text = ""
	filled = false

func _on_mouse_entered() -> void:
	panel_style.border_color = Color(0.6, 0.5, 0.9, 1)

func _on_mouse_exited() -> void:
	panel_style.border_color = Color(0.6, 0.5, 0.9, 0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if filled and not item_info.is_empty():
			print("选中物品: ", item_info)
			if item_info.get("type", -1) == ItemData.ItemType.CONSUMABLE:
				_use_consumable()

func _use_consumable() -> void:
	print("使用消耗品: ", item_info.get("name", ""))
	clear_item()

func _get_drag_data(at_position):
	if not filled:
		return null
	set_drag_preview(get_preview())
	return self

func _can_drop_data(_pos, data):
	return data is Slot and data != self

#func _drop_data(_pos, data):
	#var tmp = texture_rect.prop
	#texture_rect.prop = data.prop
	#data.prop = tmp

# 缩略图
func get_preview():
	var thumb = TextureRect.new()
	thumb.texture = texture_rect.texture
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.size = texture_rect.size
	var preview = Control.new()
	preview.add_child(thumb)
	return preview
