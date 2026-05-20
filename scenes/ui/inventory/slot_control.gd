extends Control

@onready var slot : Slot = $Slot
@onready var action_menu : VBoxContainer = $ActionMenu

func _ready() -> void:
	action_menu.hide()
	# top_level 节点不会跟随父节点位置，需要每帧同步全局位置
	action_menu.set_as_top_level(true)

func _process(_delta: float) -> void:
	if action_menu.visible:
		# 跟随 Container 的全局位置，菜单浮在 Slot 左侧
		action_menu.global_position = slot.global_position + Vector2(-88, 0)

func _on_slot_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if slot.filled:
			if action_menu.visible:
				action_menu.hide()
			else:
				action_menu.global_position = slot.global_position + Vector2(-88, 0)
				action_menu.show()

func _on_use_btn_pressed() -> void:
	action_menu.hide()
	
func _on_clue_book_btn_pressed() -> void:
	action_menu.hide()
	slot.clear_item()
	ClueManager.add_clue(slot.item_info)
