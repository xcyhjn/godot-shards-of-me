# inventory.gd
# 物品栏的"渲染层"：数据源是 ClueManager.inventory（id 数组）。
# 本节点只负责把 id 翻译成 UI；增删/转移逻辑全部走 ClueManager。
extends GridContainer

func _ready() -> void:
	EventBus.inventory_update.connect(refresh)
	EventBus.slot_add_item.connect(_on_slot_add_item)
	# 初次进场也渲染一次（存档加载发出的 inventory_update 可能早于本节点 _ready）
	refresh()

## 兼容老入口：clue 上点"拿到手上"会发 slot_add_item(id)
func _on_slot_add_item(id : String) -> void:
	if ClueManager.get_clues().has(id):
		ClueManager.move_clues_to_inventory(id)
	else:
		ClueManager.add_to_inventory(id)

## 全量重绘：从 ClueManager 拉 id 列表，按顺序铺满 slot
func refresh() -> void:
	var ids : Array[String] = ClueManager.get_inventory()
	var idx : int = 0
	for container in get_children():
		var slot : Slot = container.get_node_or_null("Slot") as Slot
		if slot == null:
			continue
		if idx < ids.size():
			slot.set_item_id(ids[idx])
		else:
			slot.clear_item()
		idx += 1
