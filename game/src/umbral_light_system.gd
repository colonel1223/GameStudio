## ============================================================================
## UMBRAL — umbral_light_system.gd
## Custom 2D Lighting & Shadow Casting Engine · Sprint 1 Completion
## ============================================================================
## The beating heart of UMBRAL. This system manages all light sources,
## computes shadow geometry in real-time, creates traversable shadow
## platforms, and determines shadow vulnerability zones.
##
## Architecture:
##   UmbralLightSystem (autoload-ready singleton)
##     ├── Registers/tracks all UmbralLightSource nodes
##     ├── Computes shadow polygons via raycasting
##     ├── Creates/destroys Area2D shadow platforms
##     └── Feeds vulnerability data to ShadowStateMachine
## ============================================================================
extends Node2D
class_name UmbralLightSystem

## ── Configuration ────────────────────────────────────────────────────────────
@export_group("Shadow Casting")
@export var ray_count: int = 64                 ## Rays per light source
@export var max_shadow_distance: float = 800.0  ## Max shadow projection length
@export var shadow_update_rate: float = 0.033   ## ~30Hz shadow geometry updates
@export var platform_min_width: float = 24.0    ## Minimum traversable platform width

@export_group("Visual")
@export var shadow_color: Color = Color(0.04, 0.04, 0.04, 0.92)
@export var light_falloff_curve: Curve          ## Custom falloff for ink aesthetic
@export var shadow_edge_softness: float = 2.0   ## Edge blur in pixels

@export_group("Performance")
@export var max_active_lights: int = 4          ## Hard cap for performance
@export var culling_margin: float = 200.0       ## Off-screen culling buffer

## ── State ────────────────────────────────────────────────────────────────────
var _registered_lights: Dictionary = {}         ## id → UmbralLightSource
var _active_lights: Array[StringName] = []      ## Currently casting lights
var _shadow_polygons: Dictionary = {}           ## light_id → PackedVector2Array
var _shadow_platforms: Dictionary = {}          ## platform_id → Area2D
var _occluders: Array[Node2D] = []              ## Objects that cast shadows
var _update_timer: float = 0.0
var _light_id_counter: int = 0
var _shadow_canvas: RID                         ## CanvasItem for shadow rendering
var _vulnerability_map: Dictionary = {}         ## grid cell → light_intensity

## ── Signals ──────────────────────────────────────────────────────────────────
signal shadow_platform_created(platform: Area2D, source_light_id: String)
signal shadow_platform_destroyed(platform_id: String)
signal light_registered(light_id: String)
signal light_removed(light_id: String)
signal vulnerability_zone_updated(position: Vector2, intensity: float)

## ═══════════════════════════════════════════════════════════════════════════════
## LIFECYCLE
## ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_shadow_canvas = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(_shadow_canvas, get_canvas_item())
	RenderingServer.canvas_item_set_z_index(_shadow_canvas, -1)  ## Behind player
	
	## Connect to SignalBus
	if SignalBus:
		SignalBus.light_source_activated.connect(_on_light_activated)
		SignalBus.light_source_deactivated.connect(_on_light_deactivated)
		SignalBus.light_source_moved.connect(_on_light_moved)
		SignalBus.light_source_rotated.connect(_on_light_rotated)
	
	set_process(true)
	print("[LightSystem] Initialized — %d ray resolution, %d max lights" % [ray_count, max_active_lights])


func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= shadow_update_rate:
		_update_timer = 0.0
		_update_shadow_geometry()
		_update_vulnerability_map()
		_update_shadow_platforms()
	
	## Always redraw for visual smoothness
	queue_redraw()


func _draw() -> void:
	_render_shadows()


func _exit_tree() -> void:
	RenderingServer.free_rid(_shadow_canvas)
	_cleanup_all_platforms()


## ═══════════════════════════════════════════════════════════════════════════════
## LIGHT REGISTRATION
## ═══════════════════════════════════════════════════════════════════════════════

func register_light(light_node: Node2D, params: Dictionary = {}) -> String:
	_light_id_counter += 1
	var light_id := "light_%d" % _light_id_counter
	
	_registered_lights[light_id] = {
		"node": light_node,
		"position": light_node.global_position,
		"intensity": params.get("intensity", 1.0),
		"radius": params.get("radius", 400.0),
		"angle": params.get("angle", 0.0),         ## Direction in radians
		"spread": params.get("spread", TAU),        ## Full circle by default
		"color_temp": params.get("color_temp", 2700.0),  ## Warm candlelight
		"type": params.get("type", "point"),        ## point, directional, spot
		"active": true,
		"manipulable": params.get("manipulable", true),
		"breathing": params.get("breathing", true), ## 0.8s pulse per art doc
		"breath_phase": randf() * TAU,              ## Random start phase
	}
	
	_active_lights.append(light_id)
	_enforce_light_limit()
	
	light_registered.emit(light_id)
	if SignalBus:
		SignalBus.light_source_activated.emit(light_id, light_node.global_position)
	
	return light_id


func unregister_light(light_id: String) -> void:
	if not _registered_lights.has(light_id):
		return
	
	_registered_lights.erase(light_id)
	_active_lights.erase(light_id)
	
	## Clean up associated shadow platforms
	_remove_platforms_for_light(light_id)
	
	## Clean up shadow polygon
	_shadow_polygons.erase(light_id)
	
	light_removed.emit(light_id)
	if SignalBus:
		SignalBus.light_source_deactivated.emit(light_id)


func register_occluder(occluder: Node2D) -> void:
	if occluder not in _occluders:
		_occluders.append(occluder)


func unregister_occluder(occluder: Node2D) -> void:
	_occluders.erase(occluder)


## ═══════════════════════════════════════════════════════════════════════════════
## SHADOW GEOMETRY COMPUTATION
## ═══════════════════════════════════════════════════════════════════════════════

func _update_shadow_geometry() -> void:
	var viewport_rect := get_viewport_rect()
	var camera := get_viewport().get_camera_2d()
	var camera_pos := camera.global_position if camera else Vector2.ZERO
	var visible_rect := Rect2(
		camera_pos - viewport_rect.size / 2.0 - Vector2(culling_margin, culling_margin),
		viewport_rect.size + Vector2(culling_margin * 2.0, culling_margin * 2.0)
	)
	
	for light_id in _active_lights:
		var light_data: Dictionary = _registered_lights.get(light_id, {})
		if light_data.is_empty():
			continue
		
		var light_node: Node2D = light_data["node"]
		if not is_instance_valid(light_node):
			call_deferred("unregister_light", light_id)
			continue
		
		## Update position from node
		light_data["position"] = light_node.global_position
		
		## Cull off-screen lights
		if not visible_rect.has_point(light_data["position"]):
			_shadow_polygons.erase(light_id)
			continue
		
		## Apply breathing effect (per art doc: 0.8s pulse, 15% variance)
		if light_data["breathing"]:
			light_data["breath_phase"] += shadow_update_rate * (TAU / 0.8)
			var breath := 1.0 + sin(light_data["breath_phase"]) * 0.15
			light_data["_current_radius"] = light_data["radius"] * breath
		else:
			light_data["_current_radius"] = light_data["radius"]
		
		## Cast rays and compute shadow polygon
		var shadow_poly := _cast_shadow_rays(light_data)
		if shadow_poly.size() >= 3:
			_shadow_polygons[light_id] = shadow_poly


func _cast_shadow_rays(light_data: Dictionary) -> PackedVector2Array:
	var origin: Vector2 = light_data["position"]
	var radius: float = light_data.get("_current_radius", light_data["radius"])
	var spread: float = light_data["spread"]
	var base_angle: float = light_data["angle"]
	var light_type: String = light_data["type"]
	
	var shadow_points := PackedVector2Array()
	var space_state := get_world_2d().direct_space_state
	
	if not space_state:
		return shadow_points
	
	## Determine ray range based on light type
	var start_angle: float
	var end_angle: float
	
	match light_type:
		"point":
			start_angle = 0.0
			end_angle = TAU
		"spot":
			start_angle = base_angle - spread / 2.0
			end_angle = base_angle + spread / 2.0
		"directional":
			start_angle = base_angle - spread / 2.0
			end_angle = base_angle + spread / 2.0
		_:
			start_angle = 0.0
			end_angle = TAU
	
	var angle_step := (end_angle - start_angle) / float(ray_count)
	
	for i in range(ray_count + 1):
		var angle := start_angle + angle_step * float(i)
		var direction := Vector2(cos(angle), sin(angle))
		var end_point := origin + direction * radius
		
		## Raycast for occluders
		var query := PhysicsRayQueryParameters2D.create(origin, end_point)
		query.collision_mask = 0b0010  ## Layer 2: shadow occluders
		query.hit_from_inside = false
		
		var result := space_state.intersect_ray(query)
		
		if result:
			## Hit an occluder — shadow starts here
			var hit_point: Vector2 = result["position"]
			var hit_normal: Vector2 = result["normal"]
			
			## Project shadow beyond the occluder
			var shadow_dir := (hit_point - origin).normalized()
			var shadow_end := hit_point + shadow_dir * max_shadow_distance
			
			shadow_points.append(hit_point)
			shadow_points.append(shadow_end)
		else:
			## No hit — light reaches full radius (lit zone, no shadow)
			shadow_points.append(end_point)
	
	return shadow_points


## ═══════════════════════════════════════════════════════════════════════════════
## SHADOW PLATFORM CREATION (Area2D generation)
## ═══════════════════════════════════════════════════════════════════════════════

func _update_shadow_platforms() -> void:
	## Identify horizontal shadow surfaces suitable for platforms
	for light_id in _shadow_polygons:
		var poly: PackedVector2Array = _shadow_polygons[light_id]
		var platforms := _extract_platform_surfaces(poly, light_id)
		
		for platform_data in platforms:
			var pid: String = platform_data["id"]
			
			if _shadow_platforms.has(pid):
				## Update existing platform position
				var existing: Area2D = _shadow_platforms[pid]
				if is_instance_valid(existing):
					existing.global_position = platform_data["position"]
			else:
				## Create new platform
				_create_shadow_platform(platform_data)


func _extract_platform_surfaces(poly: PackedVector2Array, light_id: String) -> Array[Dictionary]:
	var surfaces: Array[Dictionary] = []
	
	if poly.size() < 4:
		return surfaces
	
	## Scan for roughly horizontal shadow edges
	for i in range(0, poly.size() - 1, 2):
		var p1: Vector2 = poly[i]
		var p2: Vector2 = poly[mini(i + 1, poly.size() - 1)]
		
		var edge := p2 - p1
		var width := edge.length()
		
		if width < platform_min_width:
			continue
		
		## Check if roughly horizontal (within 15° of horizontal)
		var angle := abs(edge.angle())
		if angle > PI * 0.08 and angle < PI * 0.92:
			continue
		
		var center := (p1 + p2) / 2.0
		var pid := "%s_plat_%d" % [light_id, i]
		
		surfaces.append({
			"id": pid,
			"light_id": light_id,
			"position": center,
			"width": width,
			"start": p1,
			"end": p2,
		})
	
	return surfaces


func _create_shadow_platform(data: Dictionary) -> Area2D:
	var platform := Area2D.new()
	platform.name = "ShadowPlatform_%s" % data["id"]
	platform.global_position = data["position"]
	platform.collision_layer = 0b0100    ## Layer 3: shadow platforms
	platform.collision_mask = 0b0001     ## Layer 1: player
	platform.monitorable = true
	platform.monitoring = false
	
	## Create collision shape
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(data["width"], 8.0)  ## Thin platform
	shape.shape = rect
	platform.add_child(shape)
	
	## Visual representation
	var visual := ColorRect.new()
	visual.size = Vector2(data["width"], 6.0)
	visual.position = -visual.size / 2.0
	visual.color = shadow_color
	visual.z_index = -2
	platform.add_child(visual)
	
	## Add to scene
	add_child(platform)
	_shadow_platforms[data["id"]] = platform
	
	shadow_platform_created.emit(platform, data["light_id"])
	if SignalBus:
		SignalBus.platform_created.emit(platform, -1.0)
	
	return platform


func _remove_platforms_for_light(light_id: String) -> void:
	var to_remove: Array[String] = []
	for pid in _shadow_platforms:
		if pid.begins_with(light_id):
			to_remove.append(pid)
	
	for pid in to_remove:
		_destroy_platform(pid)


func _destroy_platform(platform_id: String) -> void:
	if _shadow_platforms.has(platform_id):
		var platform: Area2D = _shadow_platforms[platform_id]
		if is_instance_valid(platform):
			platform.queue_free()
		_shadow_platforms.erase(platform_id)
		shadow_platform_destroyed.emit(platform_id)
		if SignalBus:
			SignalBus.platform_destroyed.emit(null)


func _cleanup_all_platforms() -> void:
	for pid in _shadow_platforms.keys():
		_destroy_platform(pid)


## ═══════════════════════════════════════════════════════════════════════════════
## VULNERABILITY MAP
## ═══════════════════════════════════════════════════════════════════════════════

const VULN_CELL_SIZE := 32.0  ## Grid resolution for vulnerability sampling

func _update_vulnerability_map() -> void:
	_vulnerability_map.clear()
	
	for light_id in _active_lights:
		var data: Dictionary = _registered_lights.get(light_id, {})
		if data.is_empty():
			continue
		
		var pos: Vector2 = data["position"]
		var radius: float = data.get("_current_radius", data["radius"])
		var intensity: float = data["intensity"]
		
		## Sample grid cells within light radius
		var cells_radius := ceili(radius / VULN_CELL_SIZE)
		var center_cell := Vector2i(
			floori(pos.x / VULN_CELL_SIZE),
			floori(pos.y / VULN_CELL_SIZE)
		)
		
		for cx in range(-cells_radius, cells_radius + 1):
			for cy in range(-cells_radius, cells_radius + 1):
				var cell := center_cell + Vector2i(cx, cy)
				var cell_center := Vector2(
					float(cell.x) * VULN_CELL_SIZE + VULN_CELL_SIZE / 2.0,
					float(cell.y) * VULN_CELL_SIZE + VULN_CELL_SIZE / 2.0
				)
				
				var dist := pos.distance_to(cell_center)
				if dist > radius:
					continue
				
				## Inverse-square falloff with custom curve
				var falloff: float
				if light_falloff_curve:
					falloff = light_falloff_curve.sample(dist / radius)
				else:
					falloff = 1.0 - (dist / radius) * (dist / radius)
				
				var cell_intensity := intensity * maxf(falloff, 0.0)
				
				## Accumulate intensity (multiple lights stack)
				var cell_key := "%d,%d" % [cell.x, cell.y]
				_vulnerability_map[cell_key] = _vulnerability_map.get(cell_key, 0.0) + cell_intensity


## Query vulnerability at a world position
func get_light_intensity_at(world_pos: Vector2) -> float:
	var cell := Vector2i(
		floori(world_pos.x / VULN_CELL_SIZE),
		floori(world_pos.y / VULN_CELL_SIZE)
	)
	var key := "%d,%d" % [cell.x, cell.y]
	return _vulnerability_map.get(key, 0.0)


## Check if a position is in shadow (safe for the player)
func is_in_shadow(world_pos: Vector2) -> bool:
	return get_light_intensity_at(world_pos) < 0.15


## Check if a position is dangerously lit
func is_in_light(world_pos: Vector2) -> bool:
	return get_light_intensity_at(world_pos) > 0.5


## ═══════════════════════════════════════════════════════════════════════════════
## RENDERING
## ═══════════════════════════════════════════════════════════════════════════════

func _render_shadows() -> void:
	## Draw shadow polygons with ink aesthetic
	for light_id in _shadow_polygons:
		var poly: PackedVector2Array = _shadow_polygons[light_id]
		if poly.size() < 3:
			continue
		
		## Convert to triangulated polygon for rendering
		var indices := Geometry2D.triangulate_polygon(poly)
		if indices.is_empty():
			## Fallback: draw as polyline
			draw_polyline(poly, shadow_color, 3.0, true)
			continue
		
		## Draw filled shadow
		draw_colored_polygon(poly, shadow_color)
		
		## Draw shadow edges with brush stroke effect
		for i in range(poly.size()):
			var p1 := poly[i]
			var p2 := poly[(i + 1) % poly.size()]
			var edge_color := Color(shadow_color, shadow_color.a * 0.6)
			draw_line(p1, p2, edge_color, shadow_edge_softness, true)
	
	## Draw light source glow effects
	for light_id in _active_lights:
		var data: Dictionary = _registered_lights.get(light_id, {})
		if data.is_empty():
			continue
		
		var pos: Vector2 = to_local(data["position"])
		var radius: float = data.get("_current_radius", data["radius"])
		var temp: float = data["color_temp"]
		
		## Color temperature to RGB (simplified)
		var glow_color := _temp_to_color(temp)
		glow_color.a = 0.08  ## Subtle watercolor bloom
		
		## Concentric glow rings (watercolor diffusion per art doc)
		for ring in range(4):
			var ring_radius := radius * (0.3 + float(ring) * 0.25)
			var ring_alpha := glow_color.a * (1.0 - float(ring) / 4.0)
			draw_circle(pos, ring_radius, Color(glow_color, ring_alpha))


func _temp_to_color(kelvin: float) -> Color:
	## Simplified color temperature conversion
	if kelvin <= 2700.0:
		return Color(1.0, 0.65, 0.3)   ## Warm candle (Burnt Umber range)
	elif kelvin <= 4000.0:
		return Color(1.0, 0.82, 0.6)   ## Warm white
	elif kelvin <= 5500.0:
		return Color(0.9, 0.9, 0.95)   ## Neutral daylight
	else:
		return Color(0.8, 0.85, 1.0)   ## Cool clinical (Vermillion zone)


## ═══════════════════════════════════════════════════════════════════════════════
## LIGHT MANIPULATION (Player interaction)
## ═══════════════════════════════════════════════════════════════════════════════

func move_light(light_id: String, new_position: Vector2) -> void:
	if not _registered_lights.has(light_id):
		return
	
	var old_pos: Vector2 = _registered_lights[light_id]["position"]
	_registered_lights[light_id]["node"].global_position = new_position
	_registered_lights[light_id]["position"] = new_position
	
	if SignalBus:
		SignalBus.light_source_moved.emit(light_id, old_pos, new_position)


func rotate_light(light_id: String, angle_delta: float) -> void:
	if not _registered_lights.has(light_id):
		return
	
	_registered_lights[light_id]["angle"] += angle_delta
	
	if SignalBus:
		SignalBus.light_source_rotated.emit(
			light_id,
			_registered_lights[light_id]["angle"]
		)


func set_light_intensity(light_id: String, intensity: float) -> void:
	if _registered_lights.has(light_id):
		_registered_lights[light_id]["intensity"] = clampf(intensity, 0.0, 2.0)


func is_light_manipulable(light_id: String) -> bool:
	return _registered_lights.get(light_id, {}).get("manipulable", false)


func get_nearest_manipulable_light(world_pos: Vector2, max_dist: float = 120.0) -> String:
	var nearest_id := ""
	var nearest_dist := max_dist
	
	for light_id in _active_lights:
		var data: Dictionary = _registered_lights.get(light_id, {})
		if not data.get("manipulable", false):
			continue
		
		var dist := world_pos.distance_to(data["position"])
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_id = light_id
	
	return nearest_id


## ═══════════════════════════════════════════════════════════════════════════════
## UTILITIES
## ═══════════════════════════════════════════════════════════════════════════════

func _enforce_light_limit() -> void:
	## If too many active lights, deactivate furthest from camera
	while _active_lights.size() > max_active_lights:
		var camera := get_viewport().get_camera_2d()
		if not camera:
			_active_lights.pop_back()
			continue
		
		var cam_pos := camera.global_position
		var farthest_id := ""
		var farthest_dist := 0.0
		
		for lid in _active_lights:
			var data: Dictionary = _registered_lights.get(lid, {})
			var dist := cam_pos.distance_to(data.get("position", Vector2.ZERO))
			if dist > farthest_dist:
				farthest_dist = dist
				farthest_id = lid
		
		if not farthest_id.is_empty():
			_active_lights.erase(farthest_id)


func get_active_light_count() -> int:
	return _active_lights.size()


func get_all_light_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for lid in _active_lights:
		var data: Dictionary = _registered_lights.get(lid, {})
		positions.append(data.get("position", Vector2.ZERO))
	return positions


func _on_light_activated(id: String, pos: Vector2) -> void:
	if _registered_lights.has(id):
		_registered_lights[id]["active"] = true
		if id not in _active_lights:
			_active_lights.append(id)


func _on_light_deactivated(id: String) -> void:
	if _registered_lights.has(id):
		_registered_lights[id]["active"] = false
		_active_lights.erase(id)


func _on_light_moved(id: String, _from: Vector2, to: Vector2) -> void:
	if _registered_lights.has(id):
		_registered_lights[id]["position"] = to


func _on_light_rotated(id: String, angle: float) -> void:
	if _registered_lights.has(id):
		_registered_lights[id]["angle"] = angle

