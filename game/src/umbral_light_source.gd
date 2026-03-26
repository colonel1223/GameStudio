## ============================================================================
## UMBRAL — umbral_light_source.gd
## Reusable Light Source Component · Sprint 2
## ============================================================================
## Attach to any Node2D to make it a manipulable light source.
## Supports: candle, window, mirror, surgical, prism
## Each type has unique visual and gameplay behavior.
## ============================================================================
extends Node2D
class_name UmbralLightSource

enum LightType {
	CANDLE,       ## Point light, warm, can be picked up/moved
	WINDOW,       ## Directional, fixed, shutters can be opened/closed
	MIRROR,       ## Reflects light from another source, rotatable
	SURGICAL,     ## Harsh clinical light, Act 3
	PRISM,        ## Splits light into spectrum, special puzzle element
}

## ── Exported Properties ──────────────────────────────────────────────────────
@export var light_type: LightType = LightType.CANDLE
@export var intensity: float = 1.0
@export var radius: float = 300.0
@export var color_temperature: float = 2700.0    ## Kelvin
@export var spread_angle: float = 360.0          ## Degrees
@export var direction: float = 0.0               ## Degrees
@export var manipulable: bool = true
@export var breathing: bool = true               ## 0.8s pulse per art doc
@export var flicker: bool = false                ## Random flicker (candles)

@export_group("Interaction")
@export var grab_radius: float = 48.0            ## How close player must be
@export var move_speed: float = 120.0            ## Movement when carried
@export var rotation_speed: float = 2.0          ## Rad/s when rotating

@export_group("Visual")
@export var glow_sprite: Texture2D               ## Optional glow texture
@export var particles_enabled: bool = true

## ── State ────────────────────────────────────────────────────────────────────
var light_id: String = ""                        ## Assigned by LightSystem
var is_grabbed: bool = false
var is_active: bool = true
var _breath_phase: float = 0.0
var _flicker_timer: float = 0.0
var _base_intensity: float = 1.0
var _light_system: Node = null

## ── Child Nodes ──────────────────────────────────────────────────────────────
@onready var interaction_area: Area2D = $InteractionArea
@onready var glow_visual: Sprite2D = $GlowVisual
@onready var particles: GPUParticles2D = $Particles

## ── Signals ──────────────────────────────────────────────────────────────────
signal grabbed(light_source: UmbralLightSource)
signal released(light_source: UmbralLightSource)
signal intensity_changed(new_intensity: float)

## ═══════════════════════════════════════════════════════════════════════════════
## LIFECYCLE
## ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_base_intensity = intensity
	_breath_phase = randf() * TAU
	
	## Register with lighting system
	_light_system = get_node_or_null("/root/UmbralLightSystem")
	if not _light_system:
		## Try finding it in the scene tree
		_light_system = get_tree().get_first_node_in_group("light_system")
	
	if _light_system and _light_system.has_method("register_light"):
		light_id = _light_system.register_light(self, {
			"intensity": intensity,
			"radius": radius,
			"angle": deg_to_rad(direction),
			"spread": deg_to_rad(spread_angle),
			"color_temp": color_temperature,
			"type": _get_type_string(),
			"manipulable": manipulable,
			"breathing": breathing,
		})
	
	## Setup interaction area
	if interaction_area:
		var shape := CircleShape2D.new()
		shape.radius = grab_radius
		var col := CollisionShape2D.new()
		col.shape = shape
		interaction_area.add_child(col)
		interaction_area.collision_layer = 0b1000   ## Layer 4: interactables
		interaction_area.collision_mask = 0b0001     ## Layer 1: player
	
	## Setup visuals per light type
	_setup_visuals()
	
	add_to_group("light_sources")


func _process(delta: float) -> void:
	if not is_active:
		return
	
	## Breathing effect
	if breathing:
		_breath_phase += delta * (TAU / 0.8)  ## 0.8s period per art doc
		var breath := 1.0 + sin(_breath_phase) * 0.15
		intensity = _base_intensity * breath
	
	## Candle flicker
	if flicker and light_type == LightType.CANDLE:
		_flicker_timer += delta
		if _flicker_timer > randf_range(0.05, 0.15):
			_flicker_timer = 0.0
			intensity *= randf_range(0.85, 1.05)
	
	## Update glow visual
	if glow_visual:
		var scale_factor := intensity / _base_intensity
		glow_visual.scale = Vector2.ONE * scale_factor
		glow_visual.modulate.a = clampf(intensity * 0.3, 0.0, 0.5)
	
	## Update light system
	if _light_system and not light_id.is_empty():
		if _light_system.has_method("set_light_intensity"):
			_light_system.set_light_intensity(light_id, intensity)
	
	## Handle grabbed state
	if is_grabbed:
		_process_grabbed(delta)


func _exit_tree() -> void:
	if _light_system and not light_id.is_empty():
		if _light_system.has_method("unregister_light"):
			_light_system.unregister_light(light_id)


## ═══════════════════════════════════════════════════════════════════════════════
## INTERACTION
## ═══════════════════════════════════════════════════════════════════════════════

func grab() -> void:
	if not manipulable or is_grabbed:
		return
	
	is_grabbed = true
	grabbed.emit(self)
	
	if SignalBus:
		SignalBus.sfx_request.emit("light_grab", global_position, 0.6)


func release() -> void:
	if not is_grabbed:
		return
	
	is_grabbed = false
	released.emit(self)
	
	if SignalBus:
		SignalBus.sfx_request.emit("light_release", global_position, 0.5)


func rotate_source(angle_delta: float) -> void:
	if not manipulable:
		return
	
	direction += rad_to_deg(angle_delta)
	direction = fmod(direction, 360.0)
	
	if _light_system and not light_id.is_empty():
		if _light_system.has_method("rotate_light"):
			_light_system.rotate_light(light_id, angle_delta)


func activate() -> void:
	is_active = true
	visible = true
	if SignalBus:
		SignalBus.light_source_activated.emit(light_id, global_position)


func deactivate() -> void:
	is_active = false
	if glow_visual:
		glow_visual.modulate.a = 0.0
	if SignalBus:
		SignalBus.light_source_deactivated.emit(light_id)


func _process_grabbed(delta: float) -> void:
	## Move toward mouse/input position when grabbed
	var target := get_global_mouse_position()
	var move_dir := (target - global_position)
	
	if move_dir.length() > 4.0:
		global_position += move_dir.normalized() * move_speed * delta
		
		if _light_system and not light_id.is_empty():
			if _light_system.has_method("move_light"):
				_light_system.move_light(light_id, global_position)


## ═══════════════════════════════════════════════════════════════════════════════
## VISUAL SETUP
## ═══════════════════════════════════════════════════════════════════════════════

func _setup_visuals() -> void:
	match light_type:
		LightType.CANDLE:
			_setup_candle()
		LightType.WINDOW:
			_setup_window()
		LightType.MIRROR:
			_setup_mirror()
		LightType.SURGICAL:
			_setup_surgical()
		LightType.PRISM:
			_setup_prism()


func _setup_candle() -> void:
	color_temperature = 2700.0
	breathing = true
	flicker = true
	spread_angle = 360.0


func _setup_window() -> void:
	color_temperature = 5500.0
	breathing = false
	flicker = false
	manipulable = false  ## Windows can't be moved, only shuttered
	spread_angle = 120.0


func _setup_mirror() -> void:
	color_temperature = 0.0  ## Inherits from source
	breathing = false
	flicker = false
	spread_angle = 30.0     ## Focused reflection


func _setup_surgical() -> void:
	color_temperature = 6500.0  ## Clinical harsh white
	breathing = false
	flicker = false
	intensity = 1.8             ## Extra bright — dangerous
	spread_angle = 90.0


func _setup_prism() -> void:
	color_temperature = 0.0
	breathing = false
	flicker = false
	spread_angle = 60.0


## ═══════════════════════════════════════════════════════════════════════════════
## UTILITIES
## ═══════════════════════════════════════════════════════════════════════════════

func _get_type_string() -> String:
	match light_type:
		LightType.CANDLE: return "point"
		LightType.WINDOW: return "directional"
		LightType.MIRROR: return "spot"
		LightType.SURGICAL: return "spot"
		LightType.PRISM: return "spot"
	return "point"


func get_danger_level() -> float:
	## How dangerous this light is to the shadow
	match light_type:
		LightType.CANDLE: return intensity * 0.6
		LightType.WINDOW: return intensity * 0.8
		LightType.MIRROR: return intensity * 0.5
		LightType.SURGICAL: return intensity * 1.5
		LightType.PRISM: return intensity * 0.3
	return intensity


func is_player_in_range() -> bool:
	if not interaction_area:
		return false
	return interaction_area.has_overlapping_bodies()

