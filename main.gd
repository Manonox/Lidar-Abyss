extends Node


@onready var mouse_tut: CenterContainer = $MouseTut

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"quit"):
		get_tree().quit()
	if event.is_action_pressed(&"shoot_rays"):
		mouse_tut.visible = false
