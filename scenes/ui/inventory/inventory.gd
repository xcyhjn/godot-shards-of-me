# inventory.gd
extends GridContainer

func _ready() -> void:
	EventBus.slot_add_item.connect(func(id): add_item(id))

func add_item(id: String = "0"):
	var item_info = ItemData.get_item_info(id)
	if item_info.is_empty():
		push_warning("Inventory: 无法添加物品，ID '%s' 不存在" % id)
		return

	var item_texture = load(item_info["texture_path"])
	if item_texture == null:
		push_warning("Inventory: 无法加载纹理 '%s'" % item_info["texture_path"])
		return

	item_info["TEXTURE"] = item_texture

	for slot in get_children():
		if slot is Slot and not slot.filled:
			slot.set_item(item_info)
			break
		
