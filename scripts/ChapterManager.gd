# ChapterManager.gd
extends Node

## 章节管理器：持久化"章节运行时变量 + 当前场景 + 玩家位置 + SAN"，
## 并对外提供章节场景切换入口 [method change_scene]。
## 章节内的判定/分支由各章节脚本自己写，本管理器不再维护流程图。
class_name ChapterManager

## 嵌套字典，存各章节内的运行时变量。
## e.g. chapter_data["chapter0"]["door_opened"] = true
var chapter_data: Dictionary = {}

## 当前玩家所在的章节场景（相对 [member GameManager.ChapterScenePath]，不带 .tscn 后缀）
## e.g. "chapter0/chapter0_classroom"
## 完整路径 = GameManager.ChapterScenePath + cur_scene + ".tscn"
var cur_scene: String = ""

## 玩家在 cur_scene 中的位置（保存时由 GameManager 实时收集，读档时回填给玩家）
var player_pos: Vector2 = Vector2.ZERO

## 角色精神值。与章节流程解耦，但仍由本管理器持久化
## （ui_layer / screen_crack / change_scene 都在使用 Chapter.san）
var san: int = 100:
	set(value):
		san = clampi(value, 0, 100)
		EventBus.san_update.emit(san)

func _ready() -> void:
	add_to_group("Persist") # 加入持久化分组，由 DataManager 统一调度 save/load

## 重置为新游戏初始状态。仅清字段 + 设默认起点，不做场景跳转。
## 跳转由调用方（如 menu.gd）使用 [method change_scene] 完成。
func new_game() -> void:
	chapter_data.clear()
	cur_scene = "chapter0/classroom"
	player_pos = Vector2.ZERO
	san = 100

# ============================================================
# 场景切换
# ============================================================
## 切到下一个章节场景。 [br]
## [param scene_name]: 相对 [member GameManager.ChapterScenePath] 的路径，
## 不带 .tscn 后缀。e.g. "chapter0/chapter0_hallway" [br]
## [param san_cost]: 切场景的精神消耗（默认 10，传 0 跳过） [br]
## [param params]: 透传给 [method GGT.change_scene] 的参数字典
func change_scene(scene_name: String, san_cost: int = 10, params: Dictionary = {}) -> void:
	if scene_name == "":
		push_error("[Chapter.change_scene] 场景名为空")
		return
	var full_path : String = GameManager.ChapterScenePath + scene_name + ".tscn"
	if not ResourceLoader.exists(full_path):
		push_error("[Chapter.change_scene] 场景不存在: ", full_path)
		return

	Audio.stop_music()
	if san_cost != 0:
		san -= san_cost

	cur_scene = scene_name
	GGT.change_scene(full_path, params)

# ============================================================
# 持久化协议（DataManager）
# ============================================================
func save_data() -> Dictionary:
	return {
		"chapter_data": chapter_data,
		"cur_scene": cur_scene,
		"player_pos": GameManager.get_player_pos(),
		"san": san,
	}

func load_data(data: Dictionary) -> void:
	chapter_data = data.get("chapter_data", {})
	cur_scene = data.get("cur_scene", "")
	player_pos = data.get("player_pos", Vector2.ZERO)
	san = data.get("san", 100)
	# 玩家节点若已加载会立即瞬移；若未加载则信号 emit 落空，
	# 玩家自己的 _ready 末尾应再从 Chapter.player_pos 拉一次以兜底
	GameManager.change_player_pos(player_pos)
