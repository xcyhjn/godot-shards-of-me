"""单例-游戏顶层系统"""
extends Node2D

const ItemFilePath : String = "res://resources/items.json"
const ItemTexurePath : String = "res://assets/images/items/"
const ChapterFilePath : String = "res://resources/chapters.json"
const PersistentDataPath : String = "user:/" # 少一个/，因为DataManager里会加上
const PersistentDataFileName : String = "persistent_data.json"

func wait(seconds: float) -> Signal:
	return get_tree().create_timer(seconds).timeout

func _ready() -> void:
	if Data.load_persistent_data(PersistentDataPath, PersistentDataFileName):
		print("持久化数据加载成功！")
	else:
		print("持久化数据加载失败！")

	if Chapter.load_chapter_data(ChapterFilePath):
		print("章节数据加载成功！")
	else:
		print("章节数据加载失败！")
