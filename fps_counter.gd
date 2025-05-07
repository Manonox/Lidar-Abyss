extends Label


func _physics_process(delta):
	text = "FPS: " + str(floor(Engine.get_frames_per_second()))
