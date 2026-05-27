extends Prop

@export var item_id : String = "0"
@export var detection_range : int = 64

## override 拾取物品 → 进物品栏
func handle_interact():
	if item_id == "":
		push_warning("[item_template] item_id 为空")
		queue_free()
		return
	ClueManager.add_clue(item_id)
	queue_free()
