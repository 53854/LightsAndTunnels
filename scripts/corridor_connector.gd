@tool
extends EditorScript

func _run() -> void:
	var root = get_scene()
	if not root:
		return
		
	var corridors_node = root.get_node_or_null("Corridors")
	if not corridors_node:
		print("Corridors node not found")
		return
		
	var children = corridors_node.get_children()
	# Sort by Z to process in order (simplistic approach)
	children.sort_custom(func(a, b): return a.global_position.z < b.global_position.z)
	
	for i in range(children.size() - 1):
		var current = children[i]
		var next = children[i+1]
		
		# Simple distance check
		var dist = current.global_position.distance_to(next.global_position)
		
		# Assuming standard length of 8 for now, logic would need to be smarter for real usage
		# This is a template for the user.
		print("Checking %s -> %s: Dist %f" % [current.name, next.name, dist])
