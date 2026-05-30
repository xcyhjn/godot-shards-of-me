extends Node

const INTRO_ZOOM := Vector2(1.5, 1.5)
const PLAYER_CLOSE_ZOOM := Vector2(1.8, 1.8)

@export_group("Cameras")
@export var pcam_player: PhantomCamera2D
@export var pcam_intro_pan: PhantomCamera2D
@export var pcam_player_zoom: PhantomCamera2D
@export var native_camera: Camera2D

@export_group("Targets")
@export var npc1: Node2D
@export var player: PlayerCharacter
@export var player_reveal_target: Node2D


func _ready() -> void:
	_resolve_nodes()
	start_intro_cutscene()


func start_intro_cutscene() -> void:
	if not _has_required_nodes():
		return

	player.lock_control()
	await get_tree().create_timer(0.6).timeout

	var reveal_position := _clamp_camera_center(player_reveal_target.global_position, INTRO_ZOOM)
	var reveal_offset := reveal_position - npc1.global_position
	var pan_tween := create_tween()
	pan_tween.set_trans(Tween.TRANS_SINE)
	pan_tween.set_ease(Tween.EASE_IN_OUT)
	pan_tween.tween_property(pcam_intro_pan, "follow_offset", reveal_offset, 2.0)
	await pan_tween.finished

	pcam_player_zoom.zoom = INTRO_ZOOM
	pcam_player_zoom.priority = 40
	pcam_intro_pan.priority = 20
	await get_tree().process_frame

	var zoom_tween := create_tween()
	zoom_tween.set_trans(Tween.TRANS_SINE)
	zoom_tween.set_ease(Tween.EASE_IN_OUT)
	zoom_tween.tween_property(pcam_player_zoom, "zoom", PLAYER_CLOSE_ZOOM, 1.2)
	await zoom_tween.finished

	await get_tree().create_timer(0.2).timeout
	pcam_player.priority = 50
	pcam_player_zoom.priority = 10
	pcam_intro_pan.priority = 0
	await get_tree().create_timer(0.4).timeout

	player.unlock_control()


func _clamp_camera_center(target_position: Vector2, zoom: Vector2) -> Vector2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var half_view := Vector2(
		viewport_size.x * 0.5 / zoom.x,
		viewport_size.y * 0.5 / zoom.y
	)
	return Vector2(
		clampf(target_position.x, float(native_camera.limit_left) + half_view.x, float(native_camera.limit_right) - half_view.x),
		clampf(target_position.y, float(native_camera.limit_top) + half_view.y, float(native_camera.limit_bottom) - half_view.y)
	)


func _has_required_nodes() -> bool:
	return (
		is_instance_valid(pcam_player)
		and is_instance_valid(pcam_intro_pan)
		and is_instance_valid(pcam_player_zoom)
		and is_instance_valid(native_camera)
		and is_instance_valid(npc1)
		and is_instance_valid(player)
		and is_instance_valid(player_reveal_target)
	)


func _resolve_nodes() -> void:
	if not is_instance_valid(pcam_player):
		pcam_player = get_node_or_null("../Sortables/Player/PlayerPhantomCamera2D") as PhantomCamera2D
	if not is_instance_valid(pcam_intro_pan):
		pcam_intro_pan = get_node_or_null("../Cameras/PCam_IntroPan") as PhantomCamera2D
	if not is_instance_valid(pcam_player_zoom):
		pcam_player_zoom = get_node_or_null("../Cameras/PCam_PlayerZoom") as PhantomCamera2D
	if not is_instance_valid(native_camera):
		native_camera = get_node_or_null("../Camera2D") as Camera2D
	if not is_instance_valid(npc1):
		npc1 = get_node_or_null("../CameraTargets/NPC1") as Node2D
	if not is_instance_valid(player):
		player = get_node_or_null("../Sortables/Player") as PlayerCharacter
	if not is_instance_valid(player_reveal_target):
		player_reveal_target = get_node_or_null("../CameraTargets/PlayerReveal") as Node2D
