extends Node

var collected_clues : Array[Dictionary] = []

func clear_clues() -> void:
	print("已清除！")
	collected_clues.clear()
	EventBus.clue_update_book.emit()

func add_clue(clue : Dictionary) -> void:
	print("尝试添加线索")
	# 防止重复添加
	var new_id : String = clue.get("id", "")
	for existing_clue in collected_clues:
		if existing_clue.get("id", "") == new_id:
			return

	collected_clues.append(clue)

	EventBus.clue_add_item.emit(clue)
	EventBus.clue_update_book.emit()

	
func get_collected_clues() -> Array [Dictionary]:
	return collected_clues
