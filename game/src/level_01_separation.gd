## ============================================================================
## UMBRAL — level_01_separation.gd
## Level 1: The White Room · Sprint 2 Greybox
## ============================================================================
## "The shadow awakens alone in a white room. Learns basic movement
## and light manipulation. Discovers first memory fragment: child
## hiding under bed, afraid of footsteps in the hallway."
##   — Narrative Designer
##
## Layout: Single enclosed room with paper-white walls, one candle,
## a gap requiring shadow-stretch to cross, and one memory fragment.
## This is the first 3 minutes of the game.
## ============================================================================
extends Node2D

## ── Constants ────────────────────────────────────────────────────────────────
const TILE_SIZE := 32.0
const ROOM_WIDTH := 28    ## Tiles (896px)
const ROOM_HEIGHT := 16   ## Tiles (512px)
const PAPER_COLOR := Color(1.0, 0.996, 0.969, 1.0)    ## #FFFEF7 Washi White
const WALL_COLOR := Color(0.75, 0.74, 0.72, 1.0)
const SHADOW_SAFE := Color(0.12, 0.12, 0.12, 0.7)
const GAP_WIDTH := 5      ## Tiles — requires stretch to cross

## ── Child References ─────────────────────────────────────────────────────────
var _shadow_player: CharacterBody2D
var _candle: Node2D
var _memory_fragment: Node2D
var _light_system: Node2D

## ── Level State ──────────────────────────────────────────────────────────────
var _gap_crossed: bool = false
var _memory_collected: bool = false
var _candle_moved: bool = false

## ═══════════════════════════════════════════════════════════════════════════════
## LIFECYCLE
## ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	## Build the greybox level geometry
	_build_room()
	_build_floor_with_gap()
	_place_candle()
	_place_memory_fragment()
	_place_spawn_point()
	_setup_camera_limits()
	_setup_level_triggers()
	
	## Connect signals
	if SignalBus:
		SignalBus.memory_fragment_collected.connect(_on_memory_collected)
		SignalBus.light_source_moved.connect(_on_light_moved)
	
	## Fade in from ink
	if SignalBus:
		SignalBus.fade_requested.emit(true, 2.0)
	
	print("[Level 1] The White Room loaded — greybox")


## ═══════════════════════════════════════════════════════════════════════════════
## ROOM CONSTRUCTION
## ═══════════════════════════════════════════════════════════════════════════════

func _build_room() -> void:
	## Paper-white background
	var bg := ColorRect.new()
	bg.name = "PaperBackground"
	bg.color = PAPER_COLOR
	bg.position = Vector2.ZERO
	bg.size = Vector2(ROOM_WIDTH * TILE_SIZE, ROOM_HEIGHT * TILE_SIZE)
	bg.z_index = -10
	add_child(bg)
	
	## Walls (StaticBody2D with collision)
	_build_wall("WallTop", Vector2(0, -TILE_SIZE), Vector2(ROOM_WIDTH * TILE_SIZE, TILE_SIZE))
	_build_wall("WallBottom", Vector2(0, ROOM_HEIGHT * TILE_SIZE), Vector2(ROOM_WIDTH * TILE_SIZE, TILE_SIZE))
	_build_wall("WallLeft", Vector2(-TILE_SIZE, 0), Vector2(TILE_SIZE, ROOM_HEIGHT * TILE_SIZE))
	_build_wall("WallRight", Vector2(ROOM_WIDTH * TILE_SIZE, 0), Vector2(TILE_SIZE, ROOM_HEIGHT * TILE_SIZE))


func _build_wall(wall_name: String, pos: Vector2, wall_size: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.name = wall_name
	wall.position = pos + wall_size / 2.0
	wall.collision_layer = 0b0011  ## Layers 1+2: ground + occluder
	
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = wall_size
	col.shape = shape
	wall.add_child(col)
	
	## Visual
	var visual := ColorRect.new()
	visual.size = wall_size
	visual.position = -wall_size / 2.0
	visual.color = WALL_COLOR
	wall.add_child(visual)
	
	add_child(wall)


func _build_floor_with_gap() -> void:
	## Floor is at y = ROOM_HEIGHT * TILE_SIZE - 2 tiles from bottom
	var floor_y := (ROOM_HEIGHT - 2) * TILE_SIZE
	
	## Left platform (spawn side)
	var left_width := 10 * TILE_SIZE  ## 10 tiles wide
	_build_platform("FloorLeft", Vector2(0, floor_y), Vector2(left_width, TILE_SIZE * 2))
	
	## GAP — 5 tiles wide, requires stretch ability to cross
	## Gap starts at x = left_width, ends at left_width + GAP_WIDTH * TILE_SIZE
	
	## Right platform (memory fragment side)
	var gap_end := left_width + GAP_WIDTH * TILE_SIZE
	var right_width := ROOM_WIDTH * TILE_SIZE - gap_end
	_build_platform("FloorRight", Vector2(gap_end, floor_y), Vector2(right_width, TILE_SIZE * 2))
	
	## Small ledge in the middle of the gap (stepping stone)
	var ledge_x := left_width + 2.5 * TILE_SIZE - 16
	_build_platform("GapLedge", Vector2(ledge_x, floor_y + TILE_SIZE * 0.5), Vector2(TILE_SIZE, TILE_SIZE * 0.5))
	
	## Shadow-safe zone under left platform
	var safe_zone := ColorRect.new()
	safe_zone.name = "SafeZoneIndicator"
	safe_zone.color = SHADOW_SAFE
	safe_zone.position = Vector2(TILE_SIZE, floor_y - TILE_SIZE * 3)
	safe_zone.size = Vector2(TILE_SIZE * 3, TILE_SIZE * 3)
	safe_zone.z_index = -5
	add_child(safe_zone)


func _build_platform(plat_name: String, pos: Vector2, plat_size: Vector2) -> void:
	var platform := StaticBody2D.new()
	platform.name = plat_name
	platform.position = pos + plat_size / 2.0
	platform.collision_layer = 0b0011
	
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = plat_size
	col.shape = shape
	platform.add_child(col)
	
	## Visual — slightly darker than paper
	var visual := ColorRect.new()
	visual.size = plat_size
	visual.position = -plat_size / 2.0
	visual.color = Color(0.92, 0.91, 0.89, 1.0)
	platform.add_child(visual)
	
	add_child(platform)


## ═══════════════════════════════════════════════════════════════════════════════
## INTERACTIVE ELEMENTS
## ═══════════════════════════════════════════════════════════════════════════════

func _place_candle() -> void:
	## Candle sits on left platform, can be picked up and moved
	var candle_pos := Vector2(6 * TILE_SIZE, (ROOM_HEIGHT - 4) * TILE_SIZE)
	
	## Check if UmbralLightSource class exists, otherwise create simple placeholder
	_candle = Node2D.new()
	_candle.name = "Candle"
	_candle.position = candle_pos
	
	## Visual placeholder (warm orange rectangle)
	var candle_visual := ColorRect.new()
	candle_visual.size = Vector2(8, 20)
	candle_visual.position = Vector2(-4, -20)
	candle_visual.color = Color(0.85, 0.55, 0.25, 1.0)  ## Burnt Umber
	_candle.add_child(candle_visual)
	
	## Flame visual
	var flame := ColorRect.new()
	flame.size = Vector2(6, 10)
	flame.position = Vector2(-3, -30)
	flame.color = Color(1.0, 0.8, 0.3, 0.9)
	_candle.add_child(flame)
	
	## Interaction area
	var interact := Area2D.new()
	interact.collision_layer = 0b1000
	interact.collision_mask = 0b0001
	var icol := CollisionShape2D.new()
	var ishape := CircleShape2D.new()
	ishape.radius = 48.0
	icol.shape = ishape
	interact.add_child(icol)
	_candle.add_child(interact)
	
	add_child(_candle)


func _place_memory_fragment() -> void:
	## Memory fragment on the RIGHT side of the gap (requires crossing)
	var frag_x := (ROOM_WIDTH - 4) * TILE_SIZE
	var frag_y := (ROOM_HEIGHT - 4) * TILE_SIZE
	
	_memory_fragment = Area2D.new()
	_memory_fragment.name = "MemoryFragment_LastNight"
	_memory_fragment.position = Vector2(frag_x, frag_y)
	_memory_fragment.collision_layer = 0b10000
	_memory_fragment.collision_mask = 0b0001
	_memory_fragment.monitoring = true
	
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 28.0
	col.shape = shape
	_memory_fragment.add_child(col)
	
	## Visual: dark ink stain on paper
	var stain := ColorRect.new()
	stain.size = Vector2(24, 24)
	stain.position = Vector2(-12, -12)
	stain.color = Color(0.08, 0.08, 0.08, 0.5)
	_memory_fragment.add_child(stain)
	
	## Pulse animation via script
	var pulse_script := "
extends Area2D
var _phase: float = 0.0
func _process(delta):
	_phase += delta * PI
	var s = 1.0 + sin(_phase) * 0.12
	scale = Vector2(s, s)
	var c = $ColorRect
	if c: c.modulate.a = 0.4 + sin(_phase * 0.5) * 0.2
"
	## We can't easily attach inline GDScript in code, so just add to group
	_memory_fragment.add_to_group("memory_fragments")
	
	## Connect body entered
	_memory_fragment.body_entered.connect(_on_fragment_body_entered)
	
	add_child(_memory_fragment)


func _place_spawn_point() -> void:
	## Shadow spawns in the dark corner of the left side
	var spawn := Marker2D.new()
	spawn.name = "SpawnPoint"
	spawn.position = Vector2(3 * TILE_SIZE, (ROOM_HEIGHT - 3) * TILE_SIZE)
	add_child(spawn)


## ═══════════════════════════════════════════════════════════════════════════════
## CAMERA
## ═══════════════════════════════════════════════════════════════════════════════

func _setup_camera_limits() -> void:
	## Camera follows player with limits at room bounds
	var camera := Camera2D.new()
	camera.name = "LevelCamera"
	camera.limit_left = -int(TILE_SIZE)
	camera.limit_top = -int(TILE_SIZE)
	camera.limit_right = int((ROOM_WIDTH + 1) * TILE_SIZE)
	camera.limit_bottom = int((ROOM_HEIGHT + 1) * TILE_SIZE)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 4.0
	camera.zoom = Vector2(2.0, 2.0)  ## Closer view for intimate feel
	add_child(camera)


## ═══════════════════════════════════════════════════════════════════════════════
## LEVEL TRIGGERS
## ═══════════════════════════════════════════════════════════════════════════════

func _setup_level_triggers() -> void:
	## Gap crossing trigger — Area2D at bottom of gap
	var gap_trigger := Area2D.new()
	gap_trigger.name = "GapBottomTrigger"
	var gap_x := 10 * TILE_SIZE + GAP_WIDTH * TILE_SIZE / 2.0
	var gap_y := ROOM_HEIGHT * TILE_SIZE - TILE_SIZE
	gap_trigger.position = Vector2(gap_x, gap_y)
	gap_trigger.collision_layer = 0
	gap_trigger.collision_mask = 0b0001
	gap_trigger.monitoring = true
	
	var gcol := CollisionShape2D.new()
	var gshape := RectangleShape2D.new()
	gshape.size = Vector2(GAP_WIDTH * TILE_SIZE, TILE_SIZE)
	gcol.shape = gshape
	gap_trigger.add_child(gcol)
	
	gap_trigger.body_entered.connect(_on_gap_fallen)
	add_child(gap_trigger)
	
	## Level exit (right side)
	var exit := Area2D.new()
	exit.name = "LevelExit"
	exit.position = Vector2(ROOM_WIDTH * TILE_SIZE - TILE_SIZE, (ROOM_HEIGHT - 3) * TILE_SIZE)
	exit.collision_layer = 0
	exit.collision_mask = 0b0001
	exit.monitoring = true
	
	var ecol := CollisionShape2D.new()
	var eshape := RectangleShape2D.new()
	eshape.size = Vector2(TILE_SIZE, TILE_SIZE * 3)
	ecol.shape = eshape
	exit.add_child(ecol)
	
	exit.body_entered.connect(_on_level_exit)
	add_child(exit)


## ═══════════════════════════════════════════════════════════════════════════════
## EVENTS
## ═══════════════════════════════════════════════════════════════════════════════

func _on_fragment_body_entered(body: Node2D) -> void:
	if body.is_in_group("shadow_player") and not _memory_collected:
		_memory_collected = true
		
		## This fragment unlocks the stretch ability
		if GameManager:
			GameManager.collect_memory("memory_last_night", {
				"level": "separation",
				"act": 1,
				"unlocks_ability": "stretch",
			})
		
		## Visual: stain fades to light gray
		var stain := _memory_fragment.get_node_or_null("ColorRect")
		if stain:
			var tween := create_tween()
			tween.tween_property(stain, "color", Color(0.95, 0.95, 0.93, 0.15), 2.0)
		
		print("[Level 1] Memory collected: The Last Night → Stretch unlocked")


func _on_light_moved(_id: String, _from: Vector2, _to: Vector2) -> void:
	_candle_moved = true


func _on_gap_fallen(body: Node2D) -> void:
	if body.is_in_group("shadow_player"):
		## Respawn at spawn point
		var spawn := get_node_or_null("SpawnPoint")
		if spawn and body is CharacterBody2D:
			body.global_position = spawn.global_position
			body.velocity = Vector2.ZERO
		
		if SignalBus:
			SignalBus.sfx_request.emit("shadow_dissolve", body.global_position, 0.8)
			SignalBus.shadow_died.emit()


func _on_level_exit(body: Node2D) -> void:
	if body.is_in_group("shadow_player") and _memory_collected:
		if SignalBus:
			SignalBus.level_completed.emit("separation")
		print("[Level 1] COMPLETE — proceeding to Memory Garden")

