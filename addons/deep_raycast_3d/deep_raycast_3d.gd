@tool
@icon("res://addons/deep_raycast_3d/icon.svg")

## DeepRayCast3D is a powerful plugin for Godot Engine 4x that allows performing deep raycasts, passing through multiple objects in a straight line and registering all collisions along the way.
##
## It’s ideal for shooting systems, obstacle detection, chain interactions, laser effects, and more.
##
## It can detect [b]multiple[/b] objects aligned along a beam by automatically excluding each hit collider before continuing the scan beyond it.  
##
## In addition to its physical functionality, the node can display a [b]visual 3D beam[/b] with customizable color, opacity, emission, and geometry, useful for debugging or visual effects.
##
## When [b]auto_forward[/b] is enabled, the beam is projected automatically along the parent’s forward direction (-Z axis).  
##
## When disabled, you can target another [b]Node3D[/b] via the [b]to_path[/b] property.
class_name DeepRayCast3D extends Node3D

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

## Emitted whenever the deep raycast detects one or more collisions. The `results` parameter contains an array of `DeepRayCast3DResult` objects — one for each detected hit.
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
@export var target: PhysicsBody3D:
	set(value):
		target = value

		if is_inside_tree():
			_verify_mesh()
			
		update_configuration_warnings()
## Offset Positition in target.
@export var target_offset_position: Vector3 = Vector3.ZERO
## Ignore parent node from collision checks.
@export var exclude_parent: bool = true:
	set(value):
		exclude_parent = value
		if not is_node_ready(): return
		if is_instance_valid(owner):
			if owner is PhysicsBody3D:
				if exclude_parent:
					add_exclude(owner)
				else:
					remove_exclude(owner)
			for child in owner.get_children():
				if child is PhysicsBody3D:
					if exclude_parent:
						add_exclude(child)
					else:
						remove_exclude(child)

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
#endregion =========================================================================================


#region Public Methods =============================================================================
## Returns the number of colliders detected in the last deep raycast execution.
func get_collider_count() -> int:
	return _deep_results.size()

## Returns the physics body corresponding to the given hit index from the last deep raycast result. The index must be between `0` and `get_collider_count() - 1`.
func get_collider(index: int) -> PhysicsBody3D:
	return _deep_results[index].collider

## Returns the surface normal vector of the collision at the given hit index. This vector represents the perpendicular direction to the impacted surface.
func get_normal(index: int) -> Vector3:
	return _deep_results[index].normal

## Returns the global position of the collision point for the specified hit index.
func get_hit_position(index: int) -> Vector3:
	return _deep_results[index].position

## Add a CollisionObject3D or Area3D to be excluded from raycast detection.
func add_exclude(_exclude: PhysicsBody3D) -> void:
	if _exclude == null or not _exclude.has_method("get_rid"):
		return
	if _excludes.has(_exclude.get_rid()):
		return
	_excludes.append(_exclude.get_rid())
	if is_instance_valid(_params):
		_params.exclude = _excludes

## Remove a previously excluded object from the raycast.
func remove_exclude(_exclude: PhysicsBody3D) -> void:
	if _exclude and _exclude.has_method("get_rid"):
		if _excludes.has(_exclude.get_rid()):
			_excludes.erase(_exclude.get_rid())
		if is_instance_valid(_params):
			_params.exclude = _excludes

## Clears the exclusion list, allowing all bodies to be detected again.
func clear_exclude() -> void:
	_excludes.clear()
	_params.exclude = _excludes
#endregion =========================================================================================


#region Private Methods ============================================================================
func _create_line() -> void:
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
	if not raycast_visible:
		_mesh_instance.visible = false
		return

	if not auto_forward:
		if target == null:
			_mesh_instance.visible = false
			return

	_mesh_instance.visible = true


func _update_line() -> void:
	var start_position: Vector3 = global_transform.origin
	var base_direction: Vector3

	if auto_forward:
		base_direction = - global_transform.basis.z
	else:
		if target == null:
			return
		base_direction = start_position.direction_to(
			target.global_position + target_offset_position
		)

	_direction = base_direction.normalized()
	_distance = forward_distance if auto_forward else start_position.distance_to(
		target.global_position + target_offset_position
	)

	_mesh.height = _distance
	_mesh_instance.position.z = _distance / -2
	_node_container.global_transform.origin = start_position

	var up := Vector3.UP
	if abs(_direction.dot(up)) > 0.999:
		up = Vector3.FORWARD
	_node_container.look_at(start_position + _direction, up)

	_mesh.top_radius = radius
	_mesh.bottom_radius = radius

	_material.emission = color
	_material.albedo_color = color
	_material.albedo_color.a = opacity
	_material.emission_enabled = activate_emission
	_material.emission_energy_multiplier = emission_energy

	_node_container.visible = raycast_visible


func _update_raycast() -> void:
	if Engine.is_editor_hint():
		return
	_deep_results.clear()
	if not enabled:
		return

	var from: Vector3 = global_transform.origin
	var target_position: Vector3

	if auto_forward:
		target_position = from + (-global_transform.basis.z * forward_distance)
	else:
		if target == null:
			return
		target_position = target.global_position + target_offset_position

	var to_dir: Vector3 = (target_position - from).normalized()
	var remaining_distance: float = from.distance_to(target_position)
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var local_excludes: Array[RID] = _excludes.duplicate()

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

		local_excludes.append(hit.collider.get_rid())
		from = hit.position + to_dir * margin
		remaining_distance = target_position.distance_to(from)

	if _deep_results.size() > 0:
		cast_collider.emit(_deep_results)
#endregion =========================================================================================


#region Lifecycles =================================================================================
func _get_configuration_warnings() -> PackedStringArray:
	_warnings.clear()

	if not auto_forward and target == null:
		_warnings.append("The target property cannot be null when Auto Forward is disabled.")

	return _warnings


func _enter_tree() -> void:
	update_configuration_warnings()


func _ready() -> void:
	_material = _RESOURCE_MATERIAL.duplicate()

	if is_instance_valid(owner):
		if owner is PhysicsBody3D:
			if exclude_parent:
				add_exclude(owner)
			else:
				remove_exclude(owner)
		for child in owner.get_children():
			if child is PhysicsBody3D:
				if exclude_parent:
					add_exclude(child)
				else:
					remove_exclude(child)

	_create_line()
	_update_line()
	_verify_mesh()


func _physics_process(_delta: float) -> void:
	_update_line()
	_update_raycast()
	_verify_mesh()
#endregion =========================================================================================
