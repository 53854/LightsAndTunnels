@tool
extends Node3D

@export_range(3.0, 24.0, 0.5, "or_greater") var length: float = 8.0:
	set(value):
		length = max(value, 1.0)
		_update_geometry()

@export_range(2.0, 10.0, 0.25, "or_greater") var width: float = 3.0:
	set(value):
		width = max(value, 1.0)
		_update_geometry()

@export_range(1.0, 5.0, 0.1, "or_greater") var height: float = 1.6:
	set(value):
		height = max(value, 0.5)
		_update_geometry()

@export_range(0.05, 0.5, 0.01, "or_greater") var wall_thickness: float = 0.15:
	set(value):
		wall_thickness = clamp(value, 0.05, 1.0)
		_update_geometry()

@export_range(0.05, 0.5, 0.01, "or_greater") var floor_thickness: float = 0.12:
	set(value):
		floor_thickness = clamp(value, 0.05, 0.5)
		_update_geometry()

@export_range(0.02, 0.5, 0.01, "or_greater") var ceiling_thickness: float = 0.1:
	set(value):
		ceiling_thickness = clamp(value, 0.02, 0.5)
		_update_geometry()

@onready var _floor_mesh: MeshInstance3D = $Floor
@onready var _ceiling_mesh: MeshInstance3D = $Ceiling
@onready var _wall_left: MeshInstance3D = $WallLeft
@onready var _wall_right: MeshInstance3D = $WallRight
@onready var _floor_shape: CollisionShape3D = $"Collision/FloorShape"
@onready var _wall_left_shape: CollisionShape3D = $"Collision/WallLeftShape"
@onready var _wall_right_shape: CollisionShape3D = $"Collision/WallRightShape"
@onready var _ceiling_shape: CollisionShape3D = $"Collision/CeilingShape"
@onready var _entry_marker: Node3D = $Entry
@onready var _exit_marker: Node3D = $Exit
@onready var _light: OmniLight3D = $CorridorLight

var _left_wall_enabled: bool = true
@export var left_wall_enabled := true:
	set(value):
		if _left_wall_enabled == value:
			return
		_left_wall_enabled = value
		_apply_wall_visibility()
	get:
		return _left_wall_enabled

var _right_wall_enabled: bool = true
@export var right_wall_enabled := true:
	set(value):
		if _right_wall_enabled == value:
			return
		_right_wall_enabled = value
		_apply_wall_visibility()
	get:
		return _right_wall_enabled

func _ready() -> void:
	_update_geometry()

func _update_geometry() -> void:
	if not is_inside_tree():
		return

	var half_width := width * 0.5
	var half_length := length * 0.5

	_update_box(_floor_mesh, Vector3(width, floor_thickness, length), Vector3(0, -floor_thickness * 0.5, 0))
	_update_box(_ceiling_mesh, Vector3(width, ceiling_thickness, length), Vector3(0, height - ceiling_thickness * 0.5, 0))

	var wall_size := Vector3(wall_thickness, height, length)
	_update_box(_wall_left, wall_size, Vector3(-half_width + wall_thickness * 0.5, height * 0.5, 0))
	_update_box(_wall_right, wall_size, Vector3(half_width - wall_thickness * 0.5, height * 0.5, 0))

	_update_shape(_floor_shape, Vector3(width, floor_thickness, length), Vector3(0, -floor_thickness * 0.5, 0))
	_update_shape(_ceiling_shape, Vector3(width, ceiling_thickness, length), Vector3(0, height - ceiling_thickness * 0.5, 0))
	_update_shape(_wall_left_shape, wall_size, Vector3(-half_width + wall_thickness * 0.5, height * 0.5, 0))
	_update_shape(_wall_right_shape, wall_size, Vector3(half_width - wall_thickness * 0.5, height * 0.5, 0))

	if _entry_marker:
		_entry_marker.position = Vector3(0, 0, -half_length)
	if _exit_marker:
		_exit_marker.position = Vector3(0, 0, half_length)

	if _light:
		_light.position = Vector3(0, height - 0.2, 0)
		_light.omni_range = max(length, width) * 0.7

	_apply_wall_visibility()

func _update_box(mesh_instance: MeshInstance3D, size: Vector3, position: Vector3) -> void:
	if mesh_instance == null:
		return
	var box_mesh := mesh_instance.mesh
	if box_mesh is BoxMesh:
		box_mesh.size = size
	mesh_instance.position = position

func _update_shape(shape_node: CollisionShape3D, size: Vector3, position: Vector3) -> void:
	if shape_node == null:
		return
	var box_shape := shape_node.shape
	if box_shape is BoxShape3D:
		box_shape.size = size
	shape_node.position = position

func _apply_wall_visibility() -> void:
	_set_wall_enabled(_wall_left, _wall_left_shape, _left_wall_enabled)
	_set_wall_enabled(_wall_right, _wall_right_shape, _right_wall_enabled)

func _set_wall_enabled(mesh_instance: MeshInstance3D, shape_node: CollisionShape3D, enabled: bool) -> void:
	if mesh_instance:
		mesh_instance.visible = enabled
	if shape_node:
		shape_node.disabled = not enabled
