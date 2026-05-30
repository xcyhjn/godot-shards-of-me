extends Node

# 里世界场景只有玩家镜头，因此这里做一件事：
# 在场景刚创建时就把真实 Camera2D 强制对齐到玩家 PhantomCamera 的输出，
# 避免第一可见帧先落到 0,0，再飞回玩家身上。
@onready var player_camera: PhantomCamera2D = $"../Sortables/Player/PlayerPhantomCamera2D"
@onready var native_camera: Camera2D = $"../Camera2D"


func _ready() -> void:
	if not player_camera.is_node_ready():
		await player_camera.ready

	# 先刷新玩家 PhantomCamera 的输出位置。
	player_camera.teleport_position()

	# 再等一帧，让 PhantomCameraHost 完成接管并产出稳定 transform。
	await get_tree().process_frame

	# 在过渡层还没揭开前，直接把真实 Camera2D 对齐到玩家镜头。
	native_camera.global_position = player_camera.get_transform_output().origin
	native_camera.zoom = player_camera.zoom
