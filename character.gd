extends CharacterBody3D
class_name Character


signal ray_requested

@export var movement_properties: MovementProperties
@export var lidar_properties: LidarProperties


@onready var camera: Camera3D = %Camera
@onready var interpolated: Node3D = %Interpolated

@onready var _interpolation_global_position: Vector3 = global_position
@onready var _rays_accumulator := 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_apply_friction(delta)
	_accelerate(delta)
	
	_interpolation_global_position = global_position
	move_and_slide()


func _process(delta: float) -> void:
	interpolated.position = lerp(
		_interpolation_global_position,
		global_position,
		Engine.get_physics_interpolation_fraction()
	)
	
	_shoot_rays(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		turn_camera(-event.relative * 0.002)


func turn_camera(motion: Vector2) -> void:
	rotation.y = rotation.y + motion.x
	interpolated.rotation.y = interpolated.rotation.y + motion.x
	camera.rotation.x = clampf(camera.rotation.x + motion.y, -PI / 2.0 * 0.99, PI / 2.0 * 0.99)


func _accelerate(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wishdir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var wishspeed := movement_properties.speed
	var acceleration := movement_properties.acceleration
	
	var velocity_y := velocity.y
	velocity.y = 0
	
	var speed := velocity.dot(wishdir)
	var maxgain := delta * wishspeed * acceleration
	var addspeed := minf((wishspeed - speed), maxgain)
	if addspeed > 0.0:
		velocity += addspeed * wishdir
	
	velocity.y = velocity_y

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = -0.1
	else:
		velocity.y -= movement_properties.gravity * delta


func _apply_friction(delta: float) -> void:
	var velocity_y := velocity.y
	velocity.y = 0
	
	var speed := velocity.length()
	if speed > 0.01:
		var drop := maxf(speed, movement_properties.stopspeed)
		var newspeed := speed - delta * movement_properties.friction * drop
		newspeed = maxf(newspeed, 0.0)
		velocity *= newspeed / speed
	else:
		velocity = Vector3()
	
	velocity.y = velocity_y


func _shoot_rays(delta: float) -> void:
	if Input.get_action_strength("shoot_rays") > 0.0:
		_rays_accumulator += Input.get_action_strength("shoot_rays") * lidar_properties.rate * delta
	while _rays_accumulator >= 1.0:
		_rays_accumulator -= 1.0
		ray_requested.emit(
			self,
			camera.global_position,
			_get_random_ray_direction(),
			lidar_properties.scale
		)


func _get_random_ray_direction() -> Vector3:
	var viewport_size := get_viewport().get_visible_rect().size
	var r := sqrt(randf_range(0.0, 1.0)) * viewport_size.y * 0.1
	var a := randf_range(0.0, TAU)
	var offset := Vector2(cos(a) * r, sin(a) * r)
	return camera.project_ray_normal(viewport_size / 2.0 + offset)
