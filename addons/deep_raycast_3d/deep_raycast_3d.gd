@tool
class_name DeepRayCast3D
extends Node3D
# TODO: Alterar TO para um Vector3

#region Private Properties =========================================================================
var _RESOURCE_MATERIAL: StandardMaterial3D = preload("res://addons/deep_raycast_3d/resources/material.tres")
var _node_container: Node3D = null
var _mesh_instance: MeshInstance3D = null
var _mesh: CylinderMesh = null
var _direction: Vector3 = Vector3.ZERO
var _distance: float = 0.0
var _excludes: Array[RID] = []
var _material: StandardMaterial3D = _RESOURCE_MATERIAL
var _deep_results: Array[DeepRaycast3DResult] = []
var _params: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
var _warnings = []
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

## Ignore the parent node.
@export var exclude_parent: bool = true:
	set(value):
		exclude_parent = value
		if get_parent():
			if exclude_parent == true:
				add_exclude(get_parent())
			else:
				remove_exclude(get_parent())


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


#region Public Methods =============================================================================
		
## Add an area or a 3D body to be excluded from raycast detections.			
func add_exclude(_exclude: Variant) -> void:
	if _exclude == null:
		return
	if not _exclude.has_method("get_rid"):
		return
		
	if _excludes.has(_exclude.get_rid()):
		return
	if _exclude.has_method("get_rid"):
		_excludes.append(_exclude.get_rid())

	if is_instance_valid(_params):
		_params.exclude = _excludes


## Removes an area or a 3D body so that it is not excluded from raycast detections.	
func remove_exclude(_exclude: Variant) -> void:
	if _exclude.has_method("get_rid"):
		if _excludes.has(_exclude.get_rid()):
			_excludes.erase(_exclude.get_rid())
	
	if is_instance_valid(_params):
		_params.exclude = _excludes
#endregion Public Methods ==========================================================================


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
	_deep_results.clear()

	for i in range(max_results):
		if remaining_distance <= 0.0:
			break

		var to_point := from + to_dir * remaining_distance

		_params = PhysicsRayQueryParameters3D.new()
		_params.from = from
		_params.to = to_point
		_params.collide_with_areas = collide_with_areas
		_params.collide_with_bodies = collide_with_bodies
		_params.collision_mask = collision_mask
		_params.exclude = local_excludes
		_params.hit_back_faces = hit_back_faces
		_params.hit_from_inside = hit_from_inside

		var hit := space_state.intersect_ray(_params)

		if hit.is_empty():
			break

		_deep_results.append(DeepRaycast3DResult.new(hit.collider, hit.collider_id, hit.normal, hit.position, hit.face_index, hit.rid, hit.shape))

		local_excludes.append(hit["collider"].get_rid())

		from = hit["position"] + to_dir * margin
		remaining_distance = to.global_position.distance_to(from)

	if _deep_results.size() > 0:
		cast_collider.emit(_deep_results)
	

#endregion Private Methods =========================================================================


#region Lifecycles =================================================================================
func _get_configuration_warnings() -> PackedStringArray:
	_warnings = []
	if to == null:
		_warnings.append("The TO property in the inspector cannot be null.")
		
	if not get_parent() is Node3D:
		_warnings.append("The parent node of DeepRayCast3D must be a 3D node.")
		
	if get_parent() == to:
		_warnings.append("The TO property cannot be the parent node of DeepRayCast3D.")
	return _warnings
	
	
func _enter_tree() -> void:
	update_configuration_warnings()
	

func _ready() -> void:
	_material = _RESOURCE_MATERIAL

	for e in excludes:
		if e:
			_excludes.append(e.get_rid())
	if exclude_parent == true:
		add_exclude(get_parent())
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
