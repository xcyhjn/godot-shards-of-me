extends Prop

## override 拾取物品
func handle_interact():
	"""
	{
		"id": "test_clue_" + str(Time.get_ticks_msec()), # 内部id
		"title": "测试线索", # 小标题
		"description": "这是一条测试用线索，用来检查线索书是否能正常新增和翻页。", # 下方描述
		"image": null # 图片地址
	}
	"""
	ClueManager.add_clue(ItemData.get_item_info("0"))
	queue_free()
		
