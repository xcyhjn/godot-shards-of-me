extends Prop

@export var item_id : String = "0"
@export var detection_range : int = 64

#func _ready() -> void:
	#sprite.texture = load(ItemData.get_texture(item_id))
	#print(collision.shape)

## override 拾取物品
func handle_interact():
	ClueManager.add_clue(ItemData.get_item_info(item_id))
	queue_free()
		
