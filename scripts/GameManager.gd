"""单例-游戏顶层系统"""
extends Node2D

const ItemFilePath : String = "res://resources/items.json"
const ItemTexurePath : String = "res://assets/images/items/"
const ChapterFilePath : String = "res://resources/chapters.json"

func wait(seconds: float) -> Signal:
	return get_tree().create_timer(seconds).timeout

func lock_player_control(stat : bool = true) -> void:
	EventBus.player_control_lock.emit(stat)

func _ready() -> void:
	# Data 内部会等待 Dialogic 就绪，所有持久化数据统一存放在 Dialogic 的 "process" slot
	if await Data.load_persistent_data():
		print("持久化数据加载成功！")
	else:
		print("持久化数据加载失败！")

	if Chapter.load_chapter_data(ChapterFilePath):
		print("章节数据加载成功！")
	else:
		print("章节数据加载失败！")
