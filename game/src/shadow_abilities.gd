## ============================================================================
## UMBRAL — shadow_abilities.gd
## Shadow Ability System · Sprint 2: Vertical Slice
## ============================================================================
## Sprint 2 implements STRETCH — the first ability unlocked via memory
## fragment in Level 1 (The White Room). Shadow extends toward target,
## creating a traversable ink-brush bridge. Limited by integrity.
## ============================================================================
extends Node2D
class_name ShadowAbilities

@export_group("Stretch")
@export var max_stretch_distance: float = 280.0
@export var stretch_speed: float = 320.0
@export var stretch_retract_speed: float = 480.0
@export var stretch_width: float = 12.0
@export var stretch_cost_per_second: float = 0.15
@export var stretch_min_integrity: float = 0.2

@export_group("Integrity")
@export var max_integrity: float = 1.0
@export var integrity_regen_rate: float = 0.08
@export var integrity_regen_delay: float = 1.5

var _integrity: float = 1.0
var _is_stretching: bool = false
var _stretch_origin: Vector2 = Vector2.ZERO
var _stretch_target: Vector2 = Vector2.ZERO
var _stretch_current_length: float = 0.0
var _stretch_direction: Vector2 = Vector2.ZERO
var _can_use_abilities: bool = true
var _is_vulnerable: bool = false
var _regen_cooldown: float = 0.0

var _unlocked_abilities: Dictionary = {
	"stretch": false, "split": false, "reform": false,
}

var _stretch_visual: Line2D
var _stretch_collision: StaticBody2D
var _stretch_shape: CollisionShape2D
var _shadow_ref: CharacterBody2D

signal integrity_changed(new_value: float)
signal stretch_started(origin: Vector2, direction: Vector2)
signal stretch_ended(final_length: float)
signal stretch_target_reached
signal ability_unlocked(ability_name: String)

func _ready() -> void:
	_integrity = max_integrity
	_create_stretch_visual()
	_create_stretch_collision()
	if SignalBus:
		SignalBus.shadow_ability_gained.connect(_on_ability_gained)
	add_to_group("shadow_abilities")

func _process(delta: float) -> void:
	if _is_stretching:
		_update_stretch(delta)
	else:
		_regenerate_integrity(delta)
	_update_stretch_visual()

func _unhandled_input(event: InputEvent) -> void:
	if not _can_use_abilities: return
	if event.is_action_pressed("stretch") and _unlocked_abilities["stretch"]:
		_begin_stretch()
	elif event.is_action_released("stretch") and _is_stretching:
		_end_stretch()

## ── STRETCH ──────────────────────────────────────────────────────────────────

func _begin_stretch() -> void:
	if _integrity < stretch_min_integrity:
		if SignalBus:
			SignalBus.sfx_request.emit("shadow_strain", global_position, 0.5)
		return
	if not _shadow_ref:
		_shadow_ref = get_parent() as CharacterBody2D
	if not _shadow_ref: return
	_is_stretching = true
	_stretch_origin = _shadow_ref.global_position
	_stretch_current_length = 0.0
	var mouse_pos := get_global_mouse_position()
	_stretch_direction = (_stretch_origin.direction_to(mouse_pos)).normalized()
	_stretch_target = mouse_pos
	stretch_started.emit(_stretch_origin, _stretch_direction)
	if SignalBus:
		SignalBus.shadow_ability_used.emit("stretch")
		SignalBus.sfx_request.emit("shadow_stretch", global_position, 0.8)

func _update_stretch(delta: float) -> void:
	_integrity -= stretch_cost_per_second * delta
	_integrity = maxf(_integrity, 0.0)
	integrity_changed.emit(_integrity)
	_regen_cooldown = integrity_regen_delay
	if _integrity <= 0.0:
		_end_stretch()
		return
	var mouse_pos := get_global_mouse_position()
	_stretch_direction = (_stretch_origin.direction_to(mouse_pos)).normalized()
	var target_length := minf(
		_stretch_origin.distance_to(mouse_pos), max_stretch_distance)
	_stretch_current_length = move_toward(
		_stretch_current_length, target_length, stretch_speed * delta)
	_update_stretch_collision()
	if _stretch_current_length >= max_stretch_distance - 4.0:
		stretch_target_reached.emit()

func _end_stretch() -> void:
	_is_stretching = false
	var final_length := _stretch_current_length
	_stretch_current_length = 0.0
	_clear_stretch_collision()
	stretch_ended.emit(final_length)
	if SignalBus:
		SignalBus.sfx_request.emit("shadow_retract", global_position, 0.6)

func stretch_target_reached_check() -> bool:
	return _stretch_current_length >= max_stretch_distance * 0.95

## ── STRETCH VISUAL (sumi-e brush bridge) ─────────────────────────────────────

func _create_stretch_visual() -> void:
	_stretch_visual = Line2D.new()
	_stretch_visual.name = "StretchVisual"
	_stretch_visual.width = stretch_width
	_stretch_visual.default_color = Color(0.04, 0.04, 0.04, 0.85)
	_stretch_visual.joint_mode = Line2D.LINE_JOINT_ROUND
	_stretch_visual.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_stretch_visual.end_cap_mode = Line2D.LINE_CAP_ROUND
	_stretch_visual.antialiased = true
	_stretch_visual.z_index = -1
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.3, 0.9))
	curve.add_point(Vector2(0.7, 0.6))
	curve.add_point(Vector2(1.0, 0.15))
	_stretch_visual.width_curve = curve
	add_child(_stretch_visual)

func _update_stretch_visual() -> void:
	_stretch_visual.clear_points()
	if not _is_stretching or _stretch_current_length < 2.0: return
	var local_origin := to_local(_stretch_origin)
	var end_point := local_origin + _stretch_direction * _stretch_current_length
	var num_segments := maxi(ceili(_stretch_current_length / 40.0), 3)
	for i in range(num_segments + 1):
		var t := float(i) / float(num_segments)
		var point := local_origin.lerp(end_point, t)
		var wobble := sin(t * PI * 3.0 + Time.get_ticks_msec() * 0.003) * 2.0 * t
		point += _stretch_direction.orthogonal() * wobble
		_stretch_visual.add_point(point)
	_stretch_visual.default_color.a = lerpf(0.3, 0.85, _integrity)

## ── STRETCH COLLISION ────────────────────────────────────────────────────────

func _create_stretch_collision() -> void:
	_stretch_collision = StaticBody2D.new()
	_stretch_collision.name = "StretchBridge"
	_stretch_collision.collision_layer = 0b0100
	_stretch_collision.collision_mask = 0
	_stretch_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1, stretch_width * 0.6)
	_stretch_shape.shape = rect
	_stretch_shape.disabled = true
	_stretch_collision.add_child(_stretch_shape)
	add_child(_stretch_collision)

func _update_stretch_collision() -> void:
	if _stretch_current_length < 24.0:
		_stretch_shape.disabled = true
		return
	_stretch_shape.disabled = false
	var midpoint := _stretch_origin + _stretch_direction * (_stretch_current_length / 2.0)
	_stretch_collision.global_position = midpoint
	_stretch_collision.rotation = _stretch_direction.angle()
	var rect := _stretch_shape.shape as RectangleShape2D
	rect.size = Vector2(_stretch_current_length, stretch_width * 0.6)

func _clear_stretch_collision() -> void:
	_stretch_shape.disabled = true

## ── INTEGRITY ────────────────────────────────────────────────────────────────

func _regenerate_integrity(delta: float) -> void:
	if _regen_cooldown > 0.0:
		_regen_cooldown -= delta
		return
	if _integrity < max_integrity:
		_integrity = minf(_integrity + integrity_regen_rate * delta, max_integrity)
		integrity_changed.emit(_integrity)

func get_integrity() -> float: return _integrity

func restore_integrity(amount: float) -> void:
	_integrity = minf(_integrity + amount, max_integrity)
	integrity_changed.emit(_integrity)

func drain_integrity(amount: float) -> void:
	_integrity = maxf(_integrity - amount, 0.0)
	integrity_changed.emit(_integrity)
	_regen_cooldown = integrity_regen_delay

func start_dissolve() -> void:
	_can_use_abilities = false
	if _is_stretching: _end_stretch()

func end_dissolve() -> void: pass
func start_reform() -> void: _can_use_abilities = false
func end_reform() -> void: _can_use_abilities = true
func start_stretch() -> void: _begin_stretch()
func end_stretch() -> void:
	if _is_stretching: _end_stretch()
func start_split() -> void: pass
func end_split() -> void: pass
func split_complete() -> bool: return false

func set_vulnerability(value: bool) -> void: _is_vulnerable = value
func set_can_use_abilities(value: bool) -> void:
	_can_use_abilities = value
	if not value and _is_stretching: _end_stretch()

func _on_ability_gained(ability_name: String) -> void:
	if _unlocked_abilities.has(ability_name):
		_unlocked_abilities[ability_name] = true
		ability_unlocked.emit(ability_name)

func has_ability(ability_name: String) -> bool:
	return _unlocked_abilities.get(ability_name, false)

func set_references(shadow: CharacterBody2D) -> void:
	_shadow_ref = shadow

