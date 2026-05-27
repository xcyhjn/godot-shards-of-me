extends Prop

## 玩家要传送到的下一个场景
@export var next_scene : String
## 传送SAN值消耗
@export var san_cost : int = 0
## 玩家在下个场景中的坐标
@export var next_pos : Vector2 = Vector2(627, 497)

## override 开门操作
func handle_interact():
	var params = {
		"player_pos": next_pos
	}
	print("开门：", next_scene)
	Chapter.change_scene(next_scene, san_cost, params)
