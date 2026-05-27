extends Control

@onready var btn_play = $MarginContainer/Control/VBoxContainer/PlayButton
@onready var btn_exit = $MarginContainer/Control/VBoxContainer/ExitButton
@onready var texture_rect = $TextureRect
@onready var color_rect = $ColorRect
@onready var title_vbox = $MarginContainer/Control/CenterContainer/TitleVBox
@onready var button_container = $MarginContainer/Control/VBoxContainer
@onready var version_container = $MarginContainer/Control/Version
@onready var credits_container = $MarginContainer/Control/Credits

# BGM
@export var menu_bgm : AudioStream

func _ready():
	# 等动画播完再启用按键
	btn_play.disabled = true
	btn_exit.disabled = true
	# 初始透明，准备渐入
	_set_alpha(texture_rect, 0.0)
	_set_alpha(color_rect, 0.0)
	_set_alpha(title_vbox, 0.0)
	_set_alpha(button_container, 0.0)
	_set_alpha(version_container, 0.0)
	_set_alpha(credits_container, 0.0)

	var tween = create_tween()
	tween.set_parallel(false)

	# 背景层淡入
	tween.tween_callback(func(): _fade_in(texture_rect, 0.8))
	tween.tween_callback(func(): _fade_in(color_rect, 0.8))
	tween.tween_interval(0.5)

	# 标题淡入
	tween.tween_callback(func(): _fade_in(title_vbox, 0.6))
	tween.tween_interval(0.4)

	# 按钮淡入
	tween.tween_callback(func(): _fade_in(button_container, 0.5))
	tween.tween_interval(0.3)

	# 角落信息淡入
	tween.tween_callback(func(): _fade_in(version_container, 0.4))
	tween.tween_callback(func(): _fade_in(credits_container, 0.4))
	tween.tween_interval(0.2)

	# 渐入完成后启动呼吸动画和聚焦
	tween.tween_callback(func():
		#_start_breathing_animation()
		btn_play.disabled = false
		btn_exit.disabled = false
		btn_play.grab_focus()
		# 最后始放bgm
		Audio.set_volume(0, 0.1)
		Audio.play_music(menu_bgm)
	)

	if OS.has_feature('web'):
		btn_exit.queue_free()


func _set_alpha(node: CanvasItem, alpha: float) -> void:
	var color = node.modulate
	color.a = alpha
	node.modulate = color


func _fade_in(node: CanvasItem, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration)


#func _start_breathing_animation() -> void:
	#var tween = create_tween()
	#tween.set_loops()
	#tween.set_trans(Tween.TRANS_SINE)
	#tween.set_ease(Tween.EASE_IN_OUT)
	#tween.tween_property(title_vbox, "scale", Vector2(1.1, 1.1), 2.0)
	#tween.tween_property(title_vbox, "scale", Vector2(1.0, 1.0), 2.0)


func _on_PlayButton_pressed() -> void:
	var params = {
		"show_progress_bar": true,
		#"a_number": 10,
		#"a_string": "Ciao!",
		#"an_array": [1, 2, 3, 4],
		#"a_dict": {
			#"name": "test",
			#"val": 15
		#},
	}
	Audio.stop_music()
	Chapter.new_game()
	# Data 内部会等待 Dialogic 就绪，所有持久化数据统一存放在 Dialogic 的 "process" slot
	if await Data.load_persistent_data():
		print("持久化数据加载成功！")
	else:
		print("持久化数据加载失败！")
	GGT.change_scene("res://scenes/gameplay/start.tscn", params)


func _on_ExitButton_pressed() -> void:
	var transitions = get_node_or_null("/root/GGT_Transitions")
	if transitions:
		transitions.fade_in({
			'show_progress_bar': false
		})
		await transitions.anim.animation_finished
		await get_tree().create_timer(0.3).timeout
	get_tree().quit()
