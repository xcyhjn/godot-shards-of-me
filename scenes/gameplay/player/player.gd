extends CharacterBody2D
class_name PlayerCharacter

const SPEED = 300.0
const JUMP_VELOCITY = -800.0

@onready var Sprite: AnimatedSprite2D = $AnimatedSprite2D
var can_move: bool = true

func _ready() -> void:
	add_to_group("Player")

func lock_control() -> void:
	set_control_locked(true)

func unlock_control() -> void:
	set_control_locked(false)

func set_control_locked(locked: bool) -> void:
	can_move = not locked
	if locked:
		velocity = Vector2.ZERO
		Sprite.play("idle")

func _physics_process(delta: float) -> void:
	if not can_move:
		Sprite.play("idle")
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		pass

	var dir := Input.get_vector("向左移动", "向右移动", "向内移动", "向外移动")
	if dir:
		Sprite.flip_h = true if dir.x < 0 else false
		Sprite.play("move")
		velocity = dir * SPEED
	else:
		Sprite.play("idle")
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)

	move_and_slide()
