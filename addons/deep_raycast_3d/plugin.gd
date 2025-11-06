@tool
extends EditorPlugin

var script_main: Script = preload("res://addons/deep_raycast_3d/deep_raycast_3d.gd")
var script_result: Script = preload("res://addons/deep_raycast_3d/deep_raycast_3d_result.gd")
var icon = preload("res://addons/deep_raycast_3d/icon-16.png")

func _enable_plugin() -> void:
	add_custom_type("DeepRayCast3D", "Node", script_main, icon)
	add_custom_type("DeepRaycast3DResult", "RefCounted", script_result, icon)


func _disable_plugin() -> void:
	remove_custom_type("DeepRayCast3D")
	remove_custom_type("DeepRaycast3DResult")
