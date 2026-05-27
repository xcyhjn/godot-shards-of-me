extends CanvasLayer

@onready var pause_layer : CanvasLayer = $PauseLayer
@onready var item_layer : CanvasLayer = $ItemLayer
@onready var san_label : Label = $San

func _ready() -> void:
	item_layer.hide()
	pause_layer.show()
	show()
	san_label.text = "SAN:" + str(Chapter.san)
	EventBus.san_update.connect(func(san): 
		san_label.text = "SAN:" + str(san)	
	)
