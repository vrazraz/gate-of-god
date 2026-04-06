extends Node
## Generates a procedural map for a single act using path-first generation.
## Creates multiple paths from start to boss, ensuring full connectivity:
## every node is reachable and every path leads to the boss (no dead ends).

signal map_generated(map_data: Dictionary)

const MAP_WIDTH: int = 7
const MAP_HEIGHT: int = 15
const NUM_PATHS: int = 6

enum NodeType {
	COMBAT,
	ELITE,
	LIBRARY,
	REST,
	SHOP,
	EVENT,
	BOSS,
}

const NODE_WEIGHTS := {
	NodeType.COMBAT: 0.45,
	NodeType.EVENT: 0.22,
	NodeType.ELITE: 0.08,
	NodeType.REST: 0.12,
	NodeType.SHOP: 0.05,
	NodeType.LIBRARY: 0.08,
}


func generate_map(act: int = 1) -> Dictionary:
	# Phase 1: Generate path trajectories (no crossing, full connectivity)
	var trajectories := _generate_trajectories()

	# Phase 2: Collect unique nodes and edges from all trajectories
	var nodes_dict: Dictionary = {}  # "row_col" -> node data
	var paths: Array = []
	var path_set: Dictionary = {}  # dedup edges: "r_c_r_c" -> true

	for traj in trajectories:
		for row in range(MAP_HEIGHT):
			var col: int = traj[row]
			var key := "%d_%d" % [row, col]
			if key not in nodes_dict:
				nodes_dict[key] = {
					"row": row, "col": col,
					"type": NodeType.COMBAT, "visited": false,
				}
			# Add edge to the next row
			if row < MAP_HEIGHT - 1:
				var next_col: int = traj[row + 1]
				var edge_key := "%d_%d_%d_%d" % [row, col, row + 1, next_col]
				if edge_key not in path_set:
					path_set[edge_key] = true
					paths.append({
						"from": {"row": row, "col": col},
						"to": {"row": row + 1, "col": next_col},
					})

	# Phase 3: Assign node types with constraints
	_assign_node_types(nodes_dict)

	# Phase 4: Convert to 2D array format (rows x nodes, sorted by col)
	var nodes: Array = []
	for row in range(MAP_HEIGHT):
		var row_nodes: Array = []
		for col in range(MAP_WIDTH):
			var key := "%d_%d" % [row, col]
			if key in nodes_dict:
				row_nodes.append(nodes_dict[key])
		nodes.append(row_nodes)

	var map_data := {
		"act": act,
		"nodes": nodes,
		"paths": paths,
		"width": MAP_WIDTH,
		"height": MAP_HEIGHT,
	}

	map_generated.emit(map_data)
	return map_data


func _generate_trajectories() -> Array:
	## Generate NUM_PATHS paths from row 0 to the boss row.
	## Each path shifts -1/0/+1 column per row.
	## Paths maintain left-to-right order (no crossing).
	## All paths converge to the center column at the boss row.
	var trajectories: Array = []

	# Pick starting columns; ensure at least 3 unique for visual spread
	var start_cols: Array = []
	while true:
		start_cols.clear()
		for _i in range(NUM_PATHS):
			start_cols.append(randi_range(0, MAP_WIDTH - 1))
		start_cols.sort()
		var unique := {}
		for c in start_cols:
			unique[c] = true
		if unique.size() >= 3:
			break

	for i in range(NUM_PATHS):
		trajectories.append([start_cols[i]])

	# Build row-by-row
	for row in range(1, MAP_HEIGHT):
		if row == MAP_HEIGHT - 1:
			# Boss row: all paths converge to center
			for i in range(NUM_PATHS):
				trajectories[i].append(MAP_WIDTH / 2)
		else:
			for i in range(NUM_PATHS):
				var prev_col: int = trajectories[i][row - 1]
				var shift := randi_range(-1, 1)
				var new_col := clampi(prev_col + shift, 0, MAP_WIDTH - 1)
				# No-crossing: must be >= left neighbor's column at this row
				if i > 0:
					new_col = maxi(new_col, trajectories[i - 1][row])
				new_col = mini(new_col, MAP_WIDTH - 1)
				trajectories[i].append(new_col)

	return trajectories


func _assign_node_types(nodes_dict: Dictionary) -> void:
	# First pass: assign types based on row constraints
	for key in nodes_dict:
		var node: Dictionary = nodes_dict[key]
		var row: int = node["row"]
		if row == 0:
			node["type"] = NodeType.COMBAT
		elif row == MAP_HEIGHT - 1:
			node["type"] = NodeType.BOSS
		else:
			node["type"] = _weighted_random_type(row)

	# Second pass: guarantee at least one REST on key rows
	_ensure_type_on_row(nodes_dict, MAP_HEIGHT - 2, NodeType.REST)
	_ensure_type_on_row(nodes_dict, 8, NodeType.REST)


func _ensure_type_on_row(nodes_dict: Dictionary, target_row: int, target_type: int) -> void:
	var row_nodes: Array = []
	for key in nodes_dict:
		if nodes_dict[key]["row"] == target_row:
			row_nodes.append(nodes_dict[key])
	# Already has the target type?
	for node in row_nodes:
		if node["type"] == target_type:
			return
	# Force one random node on this row
	if not row_nodes.is_empty():
		row_nodes[randi_range(0, row_nodes.size() - 1)]["type"] = target_type


func _weighted_random_type(row: int) -> int:
	var weights := NODE_WEIGHTS.duplicate()
	# No elites in first 2 rows
	if row <= 2:
		weights.erase(NodeType.ELITE)
	# No rest in first 3 rows
	if row <= 3:
		weights.erase(NodeType.REST)
	# No shops in first row or near boss
	if row <= 1 or row >= MAP_HEIGHT - 3:
		weights.erase(NodeType.SHOP)

	var total := 0.0
	for weight in weights.values():
		total += weight
	var roll := randf() * total
	var cumulative := 0.0
	for node_type in weights:
		cumulative += weights[node_type]
		if roll <= cumulative:
			return node_type
	return NodeType.COMBAT
