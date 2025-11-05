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
@export_category("Process")
## Enables or disables raycast verification.
@export var enabled: bool = true

## The margin of verification between objects that will be traversed by the raycast.
@export_range(0.01, 1.0, 0.01, "or_greater", "suffix:m") var margin: float = 0.01

## The maximum number of objects that a raycast can pass through.
@export_range(1, 32, 1) var max_results: int = 10

@export_category("Emission")
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

@export_category("Interaction")
## Raycast destination. Example: a Marker3D or a Node3D.
@export var to: Node3D:
	set(value):
		to = value
		update_configuration_warnings()

## The list of object RIDs that will be excluded from collisions. Use CollisionObject3D.get_rid() to get the RID associated with a CollisionObject3D-derived node. Note: The returned array is copied and any changes to it will not update the original property value. To update the value you need to modify the returned array, and then assign it to the property again. 
@export var excludes: Array[Node3D] = []

@export_category("Physics")
## Enable or disable collision checking with bodies.
@export var collide_with_bodies: bool = true

## Enable or disable collision checking with 3D areas.
@export var collide_with_areas: bool = false

## If true, the query will hit back faces with concave polygon shapes with back face enabled or heightmap shapes.
@export var hit_back_faces: bool = true

## If true, the query will detect a hit when starting inside shapes. In this case the collision normal will be Vector3(0, 0, 0). Does not affect concave polygon shapes or heightmap shapes.
@export var hit_from_inside: bool = true

## The physics layers the query will detect (as a bitmask). By default, all collision layers are detected. See Collision layers and masks   in the documentation for more information.
@export_flags_3d_physics() var collision_mask = (1 << 0)

@export_category("Render")
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
	_mesh.rings = rings
	_mesh.radial_segments = segments
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
	
func _desative_raycast() -> void:
	if not get_parent() is Node3D or to == null or get_parent() == to:
		_mesh_instance.visible = false
	else:
		_mesh_instance.visible = true
		

func _update_line() -> void:
	if to == null:
		return
	
	if not get_parent() is Node3D:
		return
		
	if get_parent() == to:
		return
		
	_distance = global_position.distance_to(to.global_position)
	_direction = global_position.direction_to(to.global_position)
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
		
	if not get_parent() is Node3D:
		return
		
	if to == null:
		return
		
	if get_parent() == to:
		return
				
	var space_state := get_world_3d().direct_space_state
	var from := global_position
	var to_dir := (to.global_position - global_position).normalized()
	var remaining_distance := global_position.distance_to(to.global_position)

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
		remaining_distance = to.global_position.distance_to(from)

	if deep_results.size() > 0:
		cast_collider.emit(deep_results)
	

#endregion Private Methods =========================================================================


#region Lifecycles =================================================================================
func _get_configuration_warnings() -> PackedStringArray:
	var warnings = []
	if to == null:
		warnings.append("The TO property in the inspector cannot be null.")
		
	if not get_parent() is Node3D:
		warnings.append("The parent node of DeepRayCast3D must be a 3D node.")
		
	if get_parent() == to:
		warnings.append("The TO property cannot be the parent node of DeepRayCast3D.")
	return warnings
	
	
func _enter_tree() -> void:
	update_configuration_warnings()
	

func _ready() -> void:
	_material = RESOURCE_MATERIAL
	if excludes:
		for e in excludes:
			if e:
				_excludes.append(e.get_rid())
	_create_line()
	_update_line()
	_update_raycast()
	_desative_raycast()


func _physics_process(_delta: float) -> void:
	transform.origin = Vector3.ZERO
	_update_line()
	_update_raycast()
	_desative_raycast()
#endregion Lifecycles ==============================================================================
