@tool
extends Polygon2D

# We extend Polygon2D so we get the editor drawing tools for free!
# The 'polygon' property is now the built-in one.

@export var texture_wall: Texture2D:
	set(value):
		texture_wall = value
		if is_inside_tree():
			_update_room()

@export var wall_thickness: float = 16.0:
	set(value):
		wall_thickness = value
		if is_inside_tree():
			_update_room()

var _last_polygon: PackedVector2Array

func _ready():
	# Ensure texture_repeat is on for the floor (self)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_update_room()
	_last_polygon = polygon.duplicate()

func _process(_delta):
	# In the editor, check if polygon changed to update the walls
	if Engine.is_editor_hint():
		if polygon != _last_polygon:
			_last_polygon = polygon.duplicate()
			_update_room()

func _update_room():
	if polygon.size() < 3:
		return

	# Remove the old "FloorPoly" if it exists from previous version
	var old_floor = get_node_or_null("FloorPoly")
	if old_floor:
		old_floor.queue_free()

	# 1. Update Self (Floor)
	# self.polygon is already set by editor
	# self.texture is used for the floor
	# We might want to ensure properties
	
	# 2. Update Wall Collision
	var sb = get_node_or_null("WallCollision")
	if not sb:
		sb = StaticBody2D.new()
		sb.name = "WallCollision"
		add_child(sb)
		if Engine.is_editor_hint():
			sb.owner = get_tree().edited_scene_root
			
	# Find or create collision polygon
	var col = sb.get_node_or_null("CollisionPolygon2D")
	if not col:
		col = CollisionPolygon2D.new()
		col.name = "CollisionPolygon2D"
		sb.add_child(col)
		if Engine.is_editor_hint():
			col.owner = get_tree().edited_scene_root
			
	col.polygon = polygon
	col.build_mode = CollisionPolygon2D.BUILD_SEGMENTS

	# 3. Update Wall Visuals
	var l = get_node_or_null("WallVisuals")
	if not l:
		l = Line2D.new()
		l.name = "WallVisuals"
		add_child(l)
		if Engine.is_editor_hint():
			l.owner = get_tree().edited_scene_root
			
	l.points = polygon
	if polygon.size() > 0:
		l.add_point(polygon[0])
	l.width = wall_thickness
	l.texture = texture_wall
	l.texture_mode = Line2D.LINE_TEXTURE_TILE
	l.default_color = Color.WHITE

	# 4. Update Shadow Extruder
	var extruder = get_node_or_null("ShadowExtruder")
	if not extruder:
		var script = load("res://scripts/ShadowExtruder.gd")
		if script:
			extruder = Node2D.new()
			extruder.set_script(script)
			extruder.name = "ShadowExtruder"
			add_child(extruder)
			if Engine.is_editor_hint():
				extruder.owner = get_tree().edited_scene_root
	
	if extruder:
		extruder.polygon = polygon
		extruder.queue_redraw()

	# 5. Update Light Occluders (New!)
	# We need to generate occluder segments for the walls so PointLight2D casts shadows.
	# Since PointLight2D is inside the room, we need the occluders to be the WALLS.
	# We can generate a Closed OccluderPolygon2D for each "thick" wall segment.
	
	# 5. Update Light Occluders
	# We auto-generate these so they match the walls perfectly.
	# We check for various names to clean up old/renamed containers.
	for child_name in ["WallOccluders", "Light_Occlussion", "LightOccluders"]:
		var old = get_node_or_null(child_name)
		if old:
			old.queue_free()
	
	var occluder_parent = Node2D.new()
	occluder_parent.name = "WallOccluders"
	add_child(occluder_parent)
	if Engine.is_editor_hint():
		occluder_parent.owner = get_tree().edited_scene_root

	for i in range(polygon.size()):
		var p1 = polygon[i]
		var p2 = polygon[(i + 1) % polygon.size()]
		
		# Generate a rectangle segment for the wall
		var diff = p2 - p1
		# Normal vector pointing "outwards" relative to the edge direction
		var normal = Vector2(-diff.y, diff.x).normalized()
		
		# We make the occluder width match the wall thickness
		var offset = normal * (wall_thickness / 2.0)
		
		var poly = PackedVector2Array([
			p1 - offset,
			p2 - offset,
			p2 + offset,
			p1 + offset
		])
		
		var occluder = LightOccluder2D.new()
		occluder.name = "Occluder_" + str(i)
		var occ_poly = OccluderPolygon2D.new()
		occ_poly.polygon = poly
		occ_poly.closed = true
		# CULL_DISABLED means it blocks light from both sides (solid wall)
		occ_poly.cull_mode = OccluderPolygon2D.CULL_DISABLED
		occluder.occluder = occ_poly
		
		occluder_parent.add_child(occluder)
		if Engine.is_editor_hint():
			occluder.owner = get_tree().edited_scene_root
