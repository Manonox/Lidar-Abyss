extends Node3D
class_name LidarManager


@export_node_path("Character") var character_node_path: NodePath

var _surface_vertices := PackedVector3Array()
var _surface_arrays := []
var _update_required := false

@onready var character: Character = get_node(character_node_path)
@onready var camera: Camera3D = %Camera
@onready var sub_viewport: SubViewport = %SubViewport
@onready var live_mesh_instance: MeshInstance3D = %LiveMeshInstance
@onready var cached_mesh_instance: MeshInstance3D = %CachedMeshInstance
@onready var live_mesh: ArrayMesh = live_mesh_instance.mesh
@onready var cached_mesh: ArrayMesh = cached_mesh_instance.mesh

func _ready() -> void:
	_surface_arrays.resize(Mesh.ARRAY_MAX)
	_surface_arrays[Mesh.ARRAY_VERTEX] = _surface_vertices
	RenderingServer.global_shader_parameter_set("lidar_stencil_texture", sub_viewport.get_texture())


func cast(caster: PhysicsBody3D, origin: Vector3, normal: Vector3, point_scale: float) -> void:
	var state := get_world_3d().direct_space_state
	var parameters := PhysicsRayQueryParameters3D.create(
		origin,
		origin + normal * 1024.0,
		0xFFFFFFFF,
		[caster.get_rid()]
	)
	
	var trace := state.intersect_ray(parameters)
	if trace.is_empty():
		return
	
	place_point(trace["position"], trace["normal"], point_scale)

func place_point(p: Vector3, n: Vector3, s: float) -> void:
	var v := Vector3(1.0, 1.0, 1.0)
	while v.length_squared() > 1.0 or v.is_zero_approx():
		v = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	v = v.normalized()
	var horizontal := n.cross(v).normalized()
	var vertical := horizontal.cross(n).normalized()
	
	var sqrt3f2 := sqrt(3.0) / 2.0
	#p = p + n * 0.0005
	var p1 := p + (vertical * 0.5 + sqrt3f2 * horizontal) * s
	var p2 := p + (vertical * 0.5 - sqrt3f2 * horizontal) * s
	var p3 := p - vertical * s
	_push_triangle(p1, p2, p3)


func _push_triangle(p1: Vector3, p2: Vector3, p3: Vector3) -> void:
	_surface_vertices.push_back(p1)
	_surface_vertices.push_back(p2)
	_surface_vertices.push_back(p3)
	_update_required = true
	
	if _surface_vertices.size() >= (2**16 - 1) * 3:
		cached_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _surface_arrays)
		_surface_vertices.clear()

func _physics_process(delta: float) -> void:
	if _surface_vertices.size() > 0 and _update_required:
		_update_required = false
		live_mesh.clear_surfaces()
		live_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _surface_arrays)
		# reshit (delete old surfaces)

func _process(delta: float) -> void:
	camera.global_transform = character.camera.global_transform
	camera.fov = character.camera.fov

	var size := get_window().size
	sub_viewport.size = size
	sub_viewport.size_2d_override = size
