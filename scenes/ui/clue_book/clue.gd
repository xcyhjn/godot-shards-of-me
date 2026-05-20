# clue.gd
extends Panel

@onready var clue_image: TextureRect = $ClueImage
@onready var info: Control = $Info
@onready var title_label: Label = $Info/Title
@onready var desc_label: Label = $Info/Description
@onready var action_menu: VBoxContainer = $ActionMenu
@onready var inspect_btn: Button = $ActionMenu/InspectBtn
@onready var slot_btn: Button = $ActionMenu/SlotBtn

var clue_data: Dictionary = {}

func _ready() -> void:
	action_menu.hide()

func set_clue(clue: Dictionary) -> void:
	clue_data = clue.duplicate()
	info.show()
	action_menu.hide()
	clue_image.texture = load(clue.get("texture_path", ""))
	title_label.text = clue.get("name", "")
	desc_label.text = clue.get("description", "")

func set_empty() -> void:
	clue_data = {}
	title_label.text = ""
	desc_label.text = ""
	clue_image.texture = null
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if clue_data.is_empty():
			return
		if action_menu.visible:
			action_menu.hide()
			info.show()
		else:
			action_menu.show()
			info.hide()

func _on_inspect_btn_pressed() -> void:
	print("仔细查看: ", clue_data)
	action_menu.hide()
	info.show()
	EventBus.clue_inspect_item.emit(clue_data.get("id", ""))
	

func _on_slot_btn_pressed() -> void:
	var item_id: String = clue_data.get("id", "")
	if item_id != "":
		action_menu.hide()
		set_empty()
		EventBus.slot_add_item.emit(item_id)
	else:
		push_warning("Clue: 该线索未关联 id，无法放入快捷栏")
