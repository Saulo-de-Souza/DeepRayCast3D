class_name DeepRaycast3DResult extends RefCounted

var collider: Object
var collider_id: int
var normal: Vector3
var position: Vector3
var face_index: int
var rid: RID
var shape: int

func _init(_collider: Object, _collider_id: int, _normal: Vector3, _position: Vector3, _face_index: int, _rid: RID, _shape: int) -> void:
	collider = _collider
	collider_id = _collider_id
	normal = _normal
	position = _position
	face_index = _face_index
	rid = _rid
	shape = _shape
