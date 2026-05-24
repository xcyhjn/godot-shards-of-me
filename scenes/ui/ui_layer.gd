extends CanvasLayer

@onready var san_label : Label = $San
@onready var pause_layer : CanvasLayer = $PauseLayer

func _rey() -> void:
	pause_layer.show()
	show()
	san_label.text = "SAN:" + str(Chapter.san)
	EventBus.san_update.connect(func(san): 
		san_label.text = "SAN:" + str(san)	
	)
