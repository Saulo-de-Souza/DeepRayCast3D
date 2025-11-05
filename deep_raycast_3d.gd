@tool
class_name DeepRayCast3D
extends Node3D


#region Private Properties =========================================================================
var RESOURCE_MATERIAL: StandardMaterial3D = preload("res://addons/deep_raycast_3d/resources/material.tres")
var _node_container: Node3D = null
var _mesh_instance: MeshInstance3D = null
var _mesh: CylinderMesh = null
var _direction: Vector3 = Vector3.ZERO
var _distance: float = 0.0
var _excludes: Array[RID] = []
var _material: StandardMaterial3D = RESOURCE_MATERIAL
var deep_results: Array[DeepRaycast3DResult] = []
#endregion Private Properties ======================================================================

signal cast_collider(results: Array[DeepRaycast3DResult])

#region Exports ====================================================================================
@export var enabled: bool = true
@export_range(0.01, 1.0, 0.01, "or_greater", "suffix:m") var margin: float = 0.01
@export_range(1, 32, 1) var max_results: int = 10
@export_color_no_alpha() var color: Color = Color.WHITE
@export_range(0.01, 1.0, 0.01) var opacity: float = 0.5
@export var activate_emission: bool = false
@export_range(0.0, 10.0, 0.01, "or_greater") var emission_energy: float = 2.0
@export_range(0.01, 0.5, 0.01, "suffix:m") var radius: float = 0.05
@export var collide_with_bodies: bool = true
@export var collide_with_areas: bool = false
@export var hit_back_faces: bool = true
@export var hit_from_inside: bool = true
@export var excludes: Array[Node3D] = []:
	set(value):
		excludes = value
		_excludes.clear()

		if Engine.is_editor_hint():
			return

		if excludes:
			for e in excludes:
				if e:
					_excludes.append(e.get_rid())
@export var to: Vector3 = Vector3.FORWARD * 10.0
@export_flags_3d_physics() var collision_mask = (1 << 0)
@export_flags_3d_render() var layers = (1 << 0):
	set(value):
		layers = value
		if is_instance_valid(_mesh_instance):
			_mesh_instance.layers = layers
#endregion Exports =================================================================================


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
	_mesh.height = _distance
	_mesh.material = _material

	_node_container = Node3D.new()
	add_child(_node_container)

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _mesh
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mesh_instance.rotation_degrees.x = -90
	_mesh_instance.position.z = _distance / -2
	_mesh_instance.layers = layers

	_node_container.add_child(_mesh_instance)
	

func _update_line() -> void:
	_distance = global_position.distance_to(to)
	_direction = global_position.direction_to(to)
	_mesh.height = _distance
	_mesh_instance.position.z = _distance / -2
	_node_container.global_transform.origin = global_position
	_node_container.look_at(global_position + _direction, Vector3.UP)
	_mesh.top_radius = radius
	_mesh.bottom_radius = radius

	_material.emission = color
	_material.albedo_color = color
	_material.albedo_color.a = opacity
	_material.emission_enabled = activate_emission
	_material.emission_energy_multiplier = emission_energy


func _update_raycast() -> void:
	if Engine.is_editor_hint():
		return
	if not enabled:
		return

	var space_state := get_world_3d().direct_space_state
	var from := global_position
	var to_dir := (to - global_position).normalized()
	var remaining_distance := global_position.distance_to(to)

	var local_excludes: Array = _excludes.duplicate()
	deep_results.clear()

	for i in range(max_results):
		if remaining_distance <= 0.0:
			break

		var to_point := from + to_dir * remaining_distance

		var params := PhysicsRayQueryParameters3D.new()
		params.from = from
		params.to = to_point
		params.collide_with_areas = collide_with_areas
		params.collide_with_bodies = collide_with_bodies
		params.collision_mask = collision_mask
		params.exclude = local_excludes
		params.hit_back_faces = hit_back_faces
		params.hit_from_inside = hit_from_inside

		var hit := space_state.intersect_ray(params)

		if hit.is_empty():
			break

		deep_results.append(DeepRaycast3DResult.new(hit.collider, hit.collider_id, hit.normal, hit.position, hit.face_index, hit.rid, hit.shape))

		local_excludes.append(hit["collider"].get_rid())

		from = hit["position"] + to_dir * margin
		remaining_distance = to.distance_to(from)

	if deep_results.size() > 0:
		cast_collider.emit(deep_results)
	

#endregion Private Methods =========================================================================


#region Lifecycles =================================================================================
func _ready() -> void:
	_material = RESOURCE_MATERIAL
	if excludes:
		for e in excludes:
			if e:
				_excludes.append(e.get_rid())
	_create_line()
	_update_line()
	_update_raycast()


func _physics_process(_delta: float) -> void:
	_update_line()
	_update_raycast()
#endregion Lifecycles ==============================================================================
