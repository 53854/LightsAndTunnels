@tool
extends Node2D

var polygon: PackedVector2Array

# Configuration
@export var extrusion_length: float = 1000.0
@export var gap_offset: float = 10.0 # Pixel distance "behind" the wall to start the shadow

func _process(delta):
	queue_redraw()

func _draw():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# If no player (e.g. editor), maybe verify with a dummy point or do nothing
		# In editor, just return to avoid errors
		if Engine.is_editor_hint():
			pass 
		return

	var input_pos = player.global_position
	# For each edge in the polygon
	# The polygon is local, so we might need to transform points to global or player to local.
	# Easier to work in local space: transform player pos to local.
	var local_player_pos = to_local(input_pos)
	
	if polygon.size() < 3:
		return
		
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	var color = Color(0, 0, 0, 1)
	
	for i in range(polygon.size()):
		var p1 = polygon[i]
		var p2 = polygon[(i + 1) % polygon.size()]
		
		# Vectors from player to points
		var v1 = (p1 - local_player_pos)
		var v2 = (p2 - local_player_pos)
		
		# Edge normal (simplistic check for facing)
		# Actually, for Teleglitch style, allow all extrusions, z-sorting handles overlap?
		# Or just draw all of them. The "infinite black" implies we want to only see what's *inside* the cone?
		# No, the request says "Black geometry extruded away... Any area not within... must be rendered as pure black".
		# Masking everything not in view is harder (needs light2d/shadow2d or stencils).
		# User specifically asked for "Black geometry 'extruded' away...". This is "Reverse Shadows" or "Sight Cones".
		# If we just draw black polygons extruding outwards, we cover the areas behind walls.
		# This effectively creates the view cone if the background is black?
		# User request: "Infinite Black: Any area not within the player's calculated viewcone must be rendered as pure black."
		# If we have a floor, and we cover the "unseen" parts with black polys, that works.
		
		# Gap Logic:
		# "Do not start the black extrusion immediately at the top of the wall. There must be a calculated offset/gap"
		# The wall top is at p1, p2.
		# We want the shadow to start "further away" from the player than p1, p2.
		
		var dist1 = v1.length()
		var dist2 = v2.length()
		
		# Avoid divide by zero
		if dist1 < 0.1 or dist2 < 0.1:
			continue
			
		# Extrusion dirs
		var dir1 = v1.normalized()
		var dir2 = v2.normalized()
		
		# Calculate start points (Gap)
		# We push the start point along the view ray by 'gap_offset'
		var start1 = p1 + (dir1 * gap_offset)
		var start2 = p2 + (dir2 * gap_offset)
		
		# Calculate end points
		var end1 = p1 + (dir1 * extrusion_length)
		var end2 = p2 + (dir2 * extrusion_length)
		
		# Draw the quad
		var quad = PackedVector2Array([start1, end1, end2, start2])
		draw_polygon(quad, PackedColorArray([color, color, color, color]))
		
		# Also need to handle the "corner" gaps if the polygon is convex/concave?
		# With this simple edge extrusion, there might be cracks between quads if calculation varies?
		# We can check later. For now this implements the core "Gap" + "Extrusion" logic.
