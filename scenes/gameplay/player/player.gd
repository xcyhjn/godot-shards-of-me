extends CharacterBody2D
class_name PlayerCharacter

const SPEED = 300.0
const JUMP_VELOCITY = -800.0

@onready var Sprite: AnimatedSprite2D = $AnimatedSprite2D
var can_move: bool = true

func _ready() -> void:
	add_to_group("Player")
	%PlayerPhantomCamera2D.follow_target = self
	EventBus.player_control_lock.connect(func(stat : bool):
		set_control_locked(stat)
	)
	EventBus.player_change_pos.connect(func(pos : Vector2):
		global_position = pos
	)
	if Chapter.player_pos != Vector2.ZERO:
		global_position = Chapter.player_pos

func lock_control() -> void:
	set_control_locked(true)

func unlock_control() -> void:
	set_control_locked(false)

func set_control_locked(locked: bool) -> void:
	can_move = not locked
	if locked:
		velocity = Vector2.ZERO
		if Chapter.cur_scene.contains("inside"):
			Sprite.play("Ye_idle")
		else:
			Sprite.play("idle")

func _physics_process(delta: float) -> void:
	if not can_move:
		if Chapter.cur_scene.contains("inside"):
			Sprite.play("Ye_idle")
		else:
			Sprite.play("idle")
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		pass

	var dir := Input.get_vector("向左移动", "向右移动", "向内移动", "向外移动")
	if dir:
		Sprite.flip_h = true if dir.x < 0 else false
		if Chapter.cur_scene.contains("inside"):
			Sprite.play("Ye_walk")
		else:
			Sprite.play("move")
		velocity = dir * SPEED
	else:
		if Chapter.cur_scene.contains("inside"):
			Sprite.play("Ye_idle")
		else:
			Sprite.play("idle")
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)

	move_and_slide()
