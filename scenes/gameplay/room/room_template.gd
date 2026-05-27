class_name Room
extends Node

@onready var Player : CharacterBody2D = _find_player()
@onready var main_camera: Camera2D = _find_player_camera()

@export var bgm : AudioStream

func _ready() -> void:
	var params = GGT.get_current_scene_data().params
	var _pos : Vector2 = params.get("player_pos", Vector2.ZERO)
	if _pos != Vector2.ZERO:
		GameManager.change_player_pos(_pos)
	
	_stabilize_camera()

	if GGT.is_changing_scene():
		await GGT.scene_transition_finished

	if bgm:
		Audio.set_volume(0, 0.1)
		Audio.play_music(bgm)


func _find_player() -> CharacterBody2D:
	var direct_player := get_node_or_null("Player")
	if direct_player is CharacterBody2D:
		return direct_player as CharacterBody2D

	var sortable_player := get_node_or_null("Sortables/Player")
	if sortable_player is CharacterBody2D:
		return sortable_player as CharacterBody2D

	for node in get_tree().get_nodes_in_group("Player"):
		if node is CharacterBody2D and is_ancestor_of(node):
			return node as CharacterBody2D

	return null


func _find_player_camera() -> Camera2D:
	if not Player:
		return null
	var camera := Player.get_node_or_null("Camera2D")
	return camera as Camera2D if camera is Camera2D else null


## 在渲染前把原生相机对齐到优先级最高的 PhantomCamera2D，消除第 0 帧的默认值跳变。
func _stabilize_camera() -> void:
	if not is_instance_valid(main_camera):
		return

	var active_pcam: PhantomCamera2D = null
	var max_priority: int = -1
	for pcam in get_tree().get_nodes_in_group("PCam"):
		if pcam is PhantomCamera2D and pcam.priority > max_priority:
			max_priority = pcam.priority
			active_pcam = pcam

	if active_pcam and active_pcam.tween_resource:
		var original_duration: float = active_pcam.tween_resource.duration
		active_pcam.tween_resource.duration = 0.0
		main_camera.global_position = active_pcam.global_position
		await get_tree().process_frame
		active_pcam.tween_resource.duration = original_duration
