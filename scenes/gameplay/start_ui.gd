extends CanvasLayer

@onready var DoorHint : Panel = $DoorHint

func _on_door_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		DoorHint.fade_in()

func _on_door_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		DoorHint.fade_out()

func _ready() -> void:
	$Label.text = "SAN:" + str(Chapter.san)
	EventBus.san_update.connect(func(san): 
		$Label.text = "SAN:" + str(san)	
	)
