## ============================================================================
## UMBRAL — scene_manager.gd
## Scene Transition Manager · Sprint 1 Completion
## ============================================================================
## Handles all scene transitions with UMBRAL's signature ink-bleed
## wipe effect. Manages loading screens, fade in/out, and ensures
## smooth transitions between levels, menus, and memory sequences.
## ============================================================================
extends CanvasLayer

## ── Configuration ────────────────────────────────────────────────────────────
@export var default_transition_duration: float = 0.8
@export var ink_bleed_color: Color = Color(0.04, 0.04, 0.04, 1.0)
@export var paper_white: Color = Color(1.0, 0.996, 0.969, 1.0)

## ── State ────────────────────────────────────────────────────────────────────
var is_transitioning: bool = false
var _current_scene_path: String = ""
var _queued_scene: String = ""

## ── Child Nodes ──────────────────────────────────────────────────────────────
var _overlay: ColorRect
var _tween: Tween

## ═══════════════════════════════════════════════════════════════════════════════
## LIFECYCLE
## ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	layer = 100  ## Always on top
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	## Create fullscreen overlay for transitions
	_overlay = ColorRect.new()
	_overlay.name = "TransitionOverlay"
	_overlay.color = Color(ink_bleed_color, 0.0)  ## Start transparent
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.z_index = 100
	add_child(_overlay)
	
	## Connect signals
	if SignalBus:
		SignalBus.scene_transition_requested.connect(_on_transition_requested)
		SignalBus.fade_requested.connect(_on_fade_requested)
	
	print("[SceneManager] Ready — ink-bleed transitions loaded")


## ═══════════════════════════════════════════════════════════════════════════════
## PUBLIC API
## ═══════════════════════════════════════════════════════════════════════════════

## Transition to a new scene with ink-bleed effect
func transition_to(scene_path: String, transition_type: String = "ink_bleed", duration: float = -1.0) -> void:
	if is_transitioning:
		push_warning("[SceneManager] Transition already in progress")
		return
	
	if duration < 0.0:
		duration = default_transition_duration
	
	is_transitioning = true
	_queued_scene = scene_path
	
	match transition_type:
		"ink_bleed":
			await _ink_bleed_out(duration)
		"fade":
			await _fade_out(duration)
		"cut":
			pass  ## Instant
		_:
			await _fade_out(duration)
	
	## Load the new scene
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("[SceneManager] Failed to load scene: %s" % scene_path)
		is_transitioning = false
		return
	
	_current_scene_path = scene_path
	
	## Wait a frame for scene to initialize
	await get_tree().process_frame
	
	match transition_type:
		"ink_bleed":
			await _ink_bleed_in(duration * 1.5)  ## Slower reveal
		"fade":
			await _fade_in(duration)
		"cut":
			_overlay.color.a = 0.0
		_:
			await _fade_in(duration)
	
	is_transitioning = false


## Simple fade to/from black
func fade_out(duration: float = 0.8) -> void:
	await _fade_out(duration)


func fade_in(duration: float = 1.2) -> void:
	await _fade_in(duration)


## Load a scene without transition (for preloading)
func load_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
	_current_scene_path = scene_path


## ═══════════════════════════════════════════════════════════════════════════════
## TRANSITION EFFECTS
## ═══════════════════════════════════════════════════════════════════════════════

func _fade_out(duration: float) -> void:
	_kill_tween()
	_overlay.color = Color(ink_bleed_color, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	_tween = create_tween()
	_tween.tween_property(_overlay, "color:a", 1.0, duration)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_CUBIC)
	
	await _tween.finished


func _fade_in(duration: float) -> void:
	_kill_tween()
	_overlay.color = Color(ink_bleed_color, 1.0)
	
	_tween = create_tween()
	_tween.tween_property(_overlay, "color:a", 0.0, duration)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_CUBIC)
	
	await _tween.finished
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ink_bleed_out(duration: float) -> void:
	## Ink bleeds from edges toward center (per art doc: 0.8s wipe)
	_kill_tween()
	_overlay.color = Color(ink_bleed_color, 0.0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_QUAD)
	
	## Alpha ramps up with slight overshoot for ink weight
	_tween.tween_property(_overlay, "color:a", 1.0, duration)
	
	await _tween.finished


func _ink_bleed_in(duration: float) -> void:
	## Paper reveals itself — white emerges from black ink
	_kill_tween()
	_overlay.color = Color(ink_bleed_color, 1.0)
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	
	## Transition through paper white before clearing
	_tween.tween_property(_overlay, "color", Color(paper_white, 0.8), duration * 0.4)
	_tween.tween_property(_overlay, "color:a", 0.0, duration * 0.6)
	
	await _tween.finished
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


## ═══════════════════════════════════════════════════════════════════════════════
## SIGNAL HANDLERS
## ═══════════════════════════════════════════════════════════════════════════════

func _on_transition_requested(scene_path: String, transition_type: String) -> void:
	transition_to(scene_path, transition_type)


func _on_fade_requested(fade_in_flag: bool, duration: float) -> void:
	if fade_in_flag:
		fade_in(duration)
	else:
		fade_out(duration)


## ═══════════════════════════════════════════════════════════════════════════════
## UTILITIES
## ═══════════════════════════════════════════════════════════════════════════════

func _kill_tween() -> void:
	if _tween and _tween.is_running():
		_tween.kill()


func get_current_scene_path() -> String:
	return _current_scene_path

