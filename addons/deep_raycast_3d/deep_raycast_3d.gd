@tool
@icon("res://addons/deep_raycast_3d/icon-16.png")
class_name DeepRayCast3D
extends Node

#region Private Properties =========================================================================
var _RESOURCE_MATERIAL: StandardMaterial3D = preload("res://addons/deep_raycast_3d/resources/material.tres")
var _node_container: Node3D
var _mesh_instance: MeshInstance3D
var _mesh: CylinderMesh
var _direction: Vector3 = Vector3.ZERO
var _distance: float = 0.0
var _excludes: Array[RID] = []
var _material: StandardMaterial3D = _RESOURCE_MATERIAL.duplicate()
var _deep_results: Array[DeepRaycast3DResult] = []
var _params: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
var _warnings: PackedStringArray = []
#endregion =========================================================================================

signal cast_collider(results: Array[DeepRaycast3DResult])

#region Exports ====================================================================================
@export_subgroup("Process")
## Enables or disables raycast verification.
@export var enabled: bool = true
## The margin of verification between objects that will be traversed by the raycast.
@export_range(0.01, 1.0, 0.01, "or_greater", "suffix:m") var margin: float = 0.01
## The maximum number of objects that a raycast can pass through.
@export_range(1, 32, 1) var max_results: int = 10

@export_subgroup("Emission")
## Enable or disable streaming in Raycast.
@export var activate_emission: bool = true
## The raycast emission level.
@export_range(0.0, 10.0, 0.01, "or_greater") var emission_energy: float = 10.0
## Number of rings in the raycast rendering.
@export_range(3, 10, 1) var rings: int = 4:
	set(value):
		rings = value
		if is_instance_valid(_mesh):
			_mesh.rings = rings
## Number of segments in the raycast rendering.
@export_range(4, 64, 4) var segments: int = 64:
	set(value):
		segments = value
		if is_instance_valid(_mesh):
			_mesh.radial_segments = segments

@export_subgroup("Interaction")
## When enabled, the ray will automatically face forward based on the parent's orientation.
@export var auto_forward: bool = true:
	set(value):
		auto_forward = value
		update_configuration_warnings()
## Distance of the ray when auto_forward is enabled.
@export_range(0.1, 100.0, 0.1, "suffix:m") var forward_distance: float = 10.0
## Target node when auto_forward is disabled (manual mode).
@export var to: Node3D:
	set(value):
		to = value
		update_configuration_warnings()
## Ignore parent node from collision checks.
@export var exclude_parent: bool = true:
	set(value):
		exclude_parent = value
		if get_parent():
			if exclude_parent:
				add_exclude(get_parent())
			else:
				remove_exclude(get_parent())
## Manual exclusion list.
@export var excludes: Array[Node3D] = []

@export_subgroup("Physics")
## Enable or disable collision checking with bodies.
@export var collide_with_bodies: bool = true
## Enable or disable collision checking with 3D areas.
@export var collide_with_areas: bool = false
## If true, the query will hit back faces with concave polygon shapes with back face enabled or heightmap shapes.
@export var hit_back_faces: bool = true
## If true, the query will detect a hit when starting inside shapes. In this case the collision normal will be Vector3(0, 0, 0).
@export var hit_from_inside: bool = true
## The physics layers the query will detect (as a bitmask).
@export_flags_3d_physics() var collision_mask = (1 << 0)

@export_subgroup("Render")
## Enables or disables raycast viewing.
@export var raycast_visible: bool = true:
	set(value):
		raycast_visible = value
		if is_instance_valid(_node_container):
			_node_container.visible = raycast_visible
## Raycast display color in 3D space.
@export_color_no_alpha() var color: Color = Color.RED
## The raycast radius.
@export_range(0.01, 0.5, 0.01, "suffix:m") var radius: float = 0.02
## The opacity of the raycast displayed in 3D space.
@export_range(0.01, 1.0, 0.01) var opacity: float = 0.7
## The render layers the query will detect (as a bitmask).
@export_flags_3d_render() var layers = (1 << 0):
	set(value):
		layers = value
		if is_instance_valid(_mesh_instance):
			_mesh_instance.layers = layers

@export_subgroup("Transform")
## Position offset for the laser relative to the parent node.
@export var position_offset: Vector3 = Vector3.ZERO:
	set(value):
		position_offset = value
		if is_instance_valid(_node_container):
			_update_line()
#endregion =========================================================================================


#region Public Methods =============================================================================
func get_collider_count() -> int:
	return _deep_results.size()

func get_collider(index: int) -> PhysicsBody3D:
	return _deep_results[index].collider

func get_normal(index: int) -> Vector3:
	return _deep_results[index].normal

func get_position(index: int) -> Vector3:
	return _deep_results[index].position


## Add a CollisionObject3D or Area3D to be excluded from raycast detection.
func add_exclude(_exclude: Variant) -> void:
	if _exclude == null or not _exclude.has_method("get_rid"):
		return
	if _excludes.has(_exclude.get_rid()):
		return
	_excludes.append(_exclude.get_rid())
	if is_instance_valid(_params):
		_params.exclude = _excludes


## Remove a previously excluded object from the raycast.
func remove_exclude(_exclude: Variant) -> void:
	if _exclude and _exclude.has_method("get_rid"):
		if _excludes.has(_exclude.get_rid()):
			_excludes.erase(_exclude.get_rid())
		if is_instance_valid(_params):
			_params.exclude = _excludes
#endregion =========================================================================================


#region Private Methods ============================================================================
func _create_line() -> void:
	# Creates the visual representation of the ray (a thin cylinder)
	_material.emission = color
	_material.albedo_color = color
	_material.albedo_color.a = opacity
	_material.emission_enabled = activate_emission
	_material.emission_energy_multiplier = emission_energy

	_mesh = CylinderMesh.new()
	_mesh.top_radius = radius
	_mesh.bottom_radius = radius
	_mesh.rings = rings
	_mesh.radial_segments = segments
	_mesh.height = _distance
	_mesh.material = _material

	_node_container = Node3D.new()
	_node_container.visible = raycast_visible
	add_child(_node_container)

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _mesh
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh_instance.rotation_degrees.x = -90
	_mesh_instance.position.z = _distance / -2
	_mesh_instance.layers = layers

	_node_container.add_child(_mesh_instance)


func _verify_mesh() -> void:
	# Hide mesh if parent or target is invalid
	if not get_parent() is Node3D:
		_mesh_instance.visible = false
		return
	if not auto_forward and (to == null or get_parent() == to):
		_mesh_instance.visible = false
	else:
		_mesh_instance.visible = true


func _update_line() -> void:
	# Update the mesh line orientation and size in real-time
	if not get_parent() is Node3D:
		return

	var parent: Node3D = get_parent()
	var start_position: Vector3 = parent.to_global(position_offset)
	var target_position: Vector3

	if auto_forward:
		# Always points forward relative to parent's local -Z axis
		target_position = start_position + (parent.global_transform.basis.z * -forward_distance)
	else:
		if to == null or get_parent() == to:
			return
		target_position = to.global_position

	_distance = start_position.distance_to(target_position)
	_direction = start_position.direction_to(target_position)

	_mesh.height = _distance
	_mesh_instance.position.z = _distance / -2
	_node_container.global_transform.origin = start_position
	_node_container.look_at(start_position + _direction, Vector3.UP)
	_mesh.top_radius = radius
	_mesh.bottom_radius = radius

	_material.emission = color
	_material.albedo_color = color
	_material.albedo_color.a = opacity
	_material.emission_enabled = activate_emission
	_material.emission_energy_multiplier = emission_energy

	_node_container.visible = raycast_visible


func _update_raycast() -> void:
	# Handles the actual physics raycasting and collision detection
	if Engine.is_editor_hint():
		return
	_deep_results.clear()
	if not enabled or not get_parent() is Node3D:
		return

	var parent: Node3D = get_parent()
	var from: Vector3 = parent.to_global(position_offset)
	var target_position: Vector3

	if auto_forward:
		target_position = from + (parent.global_transform.basis.z * -forward_distance)
	else:
		if to == null or get_parent() == to:
			return
		target_position = to.global_position

	var to_dir: Vector3 = (target_position - from).normalized()
	var remaining_distance: float = from.distance_to(target_position)

	var space_state: PhysicsDirectSpaceState3D = parent.get_world_3d().direct_space_state
	var local_excludes: Array[RID] = _excludes.duplicate()
	_deep_results.clear()

	for i in range(max_results):
		if remaining_distance <= 0.0:
			break

		var to_point: Vector3 = from + to_dir * remaining_distance

		_params = PhysicsRayQueryParameters3D.new()
		_params.from = from
		_params.to = to_point
		_params.collide_with_areas = collide_with_areas
		_params.collide_with_bodies = collide_with_bodies
		_params.collision_mask = collision_mask
		_params.exclude = local_excludes
		_params.hit_back_faces = hit_back_faces
		_params.hit_from_inside = hit_from_inside

		var hit: Dictionary = space_state.intersect_ray(_params)
		if hit.is_empty():
			break

		_deep_results.append(
			DeepRaycast3DResult.new(
				hit.collider,
				hit.collider_id,
				hit.normal,
				hit.position,
				hit.face_index,
				hit.rid,
				hit.shape
			)
		)

		local_excludes.append(hit["collider"].get_rid())
		from = hit["position"] + to_dir * margin
		remaining_distance = target_position.distance_to(from)

	if _deep_results.size() > 0:
		cast_collider.emit(_deep_results)
#endregion =========================================================================================


#region Lifecycles =================================================================================
func _get_configuration_warnings() -> PackedStringArray:
	_warnings.clear()

	if not get_parent() is Node3D:
		_warnings.append("The parent of DeepRayCast3D must be a 3D node.")

	if not auto_forward:
		if to == null:
			_warnings.append("The TO property cannot be null when Auto Forward is disabled.")
		elif get_parent() == to:
			_warnings.append("The TO property cannot be the same as the parent node.")

	return _warnings


func _enter_tree() -> void:
	update_configuration_warnings()


func _ready() -> void:
	_material = _RESOURCE_MATERIAL.duplicate()

	for e in excludes:
		if e:
			_excludes.append(e.get_rid())

	if exclude_parent:
		add_exclude(get_parent())

	_create_line()
	_update_line()
	_verify_mesh()


func _physics_process(_delta: float) -> void:
	_update_line()
	_update_raycast()
	_verify_mesh()
#endregion =========================================================================================
