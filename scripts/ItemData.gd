extends Node

static var content: Dictionary

enum ItemType {
	ITEM,        # 道具
	CLUE,        # 线索
	CONSUMABLE,  # 消耗品
}

static func _static_init():
	_load_database()

static func _load_database():
	var file = FileAccess.open(GameManager.ItemFilePath, FileAccess.READ)
	if file:
		content = JSON.parse_string(file.get_as_text())
		file.close()
	else:
		push_error("ItemData: 无法打开数据库文件")
		content = {}

## 获取物品完整信息，返回 Dictionary
static func get_item_info(id: String = "0") -> Dictionary:
	if not content.has(id):
		push_warning("ItemData: 物品 ID '%s' 不存在" % id)
		return {}

	var data = content[id]
	var type_name = ItemType.keys()[data["type"]] if data["type"] < ItemType.size() else "UNKNOWN"

	return {
		"id": id,
		"name": data.get("name", ""),
		"type": data.get("type", 0),
		# "type_name": type_name,
		"description": data.get("description", ""),
		"texture": data.get("texture", ""),
		"texture_path": GameManager.ItemTexurePath + data.get("texture", "")
	}

static func get_texture(id: String = "0") -> String:
	var res : String = content.get(id, {}).get("texture", "")
	if res.is_empty():
		return ""
	else:
		return GameManager.ItemTexurePath + res

static func get_item_name(id: String = "0") -> String:
	return content.get(id, {}).get("name", "")

static func get_desc(id: String = "0") -> String:
	return content.get(id, {}).get("description", "")

static func get_item_type(id: String = "0") -> int:
	return content.get(id, {}).get("type", 0)
