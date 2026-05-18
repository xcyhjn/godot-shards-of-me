extends Node

const SCENE_LIMIT_LEFT := 0.0
const SCENE_LIMIT_TOP := 0.0
const SCENE_LIMIT_RIGHT := 1152.0
const SCENE_LIMIT_BOTTOM := 648.0
const VIEWPORT_SIZE := Vector2(1152.0, 648.0)
const INTRO_ZOOM := Vector2(1.5, 1.5)
const PLAYER_CLOSE_ZOOM := Vector2(1.8, 1.8)

@export_group("Cameras")
@export var pcam_player: PhantomCamera2D
@export var pcam_intro_pan: PhantomCamera2D
@export var pcam_player_zoom: PhantomCamera2D
@export var native_camera: Camera2D

@export_group("Targets")
@export var npc1: Node2D
@export var player: CharacterBody2D
@export var player_reveal_target: Node2D


func _enter_tree() -> void:
	_resolve_nodes()
	_prepare_first_frame_camera()


func _ready() -> void:
	_resolve_nodes()
	_prepare_first_frame_camera()
	start_intro_cutscene()


func start_intro_cutscene() -> void:
	if not _has_required_nodes():
		return

	player.set_physics_process(false)
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

	player.set_physics_process(true)


func _prepare_first_frame_camera() -> void:
	if not _has_required_nodes():
		return

	var start_position := _clamp_camera_center(npc1.global_position, INTRO_ZOOM)
	_apply_limits(pcam_player)
	_apply_limits(pcam_intro_pan)
	_apply_limits(pcam_player_zoom)

	pcam_player.priority = 1
	pcam_player.zoom = INTRO_ZOOM

	pcam_player_zoom.priority = 0
	pcam_player_zoom.zoom = INTRO_ZOOM

	pcam_intro_pan.priority = 30
	pcam_intro_pan.zoom = INTRO_ZOOM
	pcam_intro_pan.follow_offset = Vector2.ZERO
	pcam_intro_pan.global_position = start_position

	native_camera.make_current()
	native_camera.zoom = INTRO_ZOOM
	native_camera.global_position = start_position
	native_camera.limit_left = int(SCENE_LIMIT_LEFT)
	native_camera.limit_top = int(SCENE_LIMIT_TOP)
	native_camera.limit_right = int(SCENE_LIMIT_RIGHT)
	native_camera.limit_bottom = int(SCENE_LIMIT_BOTTOM)


func _apply_limits(pcam: PhantomCamera2D) -> void:
	if not pcam:
		return

	pcam.draw_limits = true
	pcam.limit_left = int(SCENE_LIMIT_LEFT)
	pcam.limit_top = int(SCENE_LIMIT_TOP)
	pcam.limit_right = int(SCENE_LIMIT_RIGHT)
	pcam.limit_bottom = int(SCENE_LIMIT_BOTTOM)


func _clamp_camera_center(target_position: Vector2, zoom: Vector2) -> Vector2:
	var half_view := Vector2(
		VIEWPORT_SIZE.x * 0.5 / zoom.x,
		VIEWPORT_SIZE.y * 0.5 / zoom.y
	)
	return Vector2(
		clampf(target_position.x, SCENE_LIMIT_LEFT + half_view.x, SCENE_LIMIT_RIGHT - half_view.x),
		clampf(target_position.y, SCENE_LIMIT_TOP + half_view.y, SCENE_LIMIT_BOTTOM - half_view.y)
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
		pcam_player = get_node_or_null("../Cameras/PCam_Player") as PhantomCamera2D
	if not is_instance_valid(pcam_intro_pan):
		pcam_intro_pan = get_node_or_null("../Cameras/PCam_IntroPan") as PhantomCamera2D
	if not is_instance_valid(pcam_player_zoom):
		pcam_player_zoom = get_node_or_null("../Cameras/PCam_PlayerZoom") as PhantomCamera2D
	if not is_instance_valid(native_camera):
		native_camera = get_node_or_null("../Sortables/Player/Camera2D") as Camera2D
	if not is_instance_valid(npc1):
		npc1 = get_node_or_null("../CameraTargets/NPC1") as Node2D
	if not is_instance_valid(player):
		player = get_node_or_null("../Sortables/Player") as CharacterBody2D
	if not is_instance_valid(player_reveal_target):
		player_reveal_target = get_node_or_null("../CameraTargets/PlayerReveal") as Node2D
