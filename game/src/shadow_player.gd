## ============================================================================
## UMBRAL — shadow_player.gd (v2)
## Shadow Player Controller · Sprint 2: Full Integration
## ============================================================================
## Replaces Sprint 1 placeholder. Full CharacterBody2D controller with:
##   - Smooth 2D platformer movement (ground + air)
##   - State machine integration (via ShadowStateMachine)
##   - Light vulnerability system (queries UmbralLightSystem)
##   - Ability system hookup (ShadowAbilities child)
##   - Sumi-e visual feedback (shader parameter driving)
##   - Input buffering for responsive controls
## ============================================================================
extends CharacterBody2D

## ── Movement ─────────────────────────────────────────────────────────────────
@export_group("Movement")
@export var move_speed: float = 180.0
@export var acceleration: float = 1200.0
@export var friction: float = 1600.0
@export var air_friction: float = 400.0

@export_group("Jump")
@export var jump_force: float = -340.0
@export var gravity_scale: float = 1.0
@export var fall_gravity_multiplier: float = 1.5
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.1

@export_group("Light Vulnerability")
@export var light_check_interval: float = 0.1
@export var dissolve_speed: float = 0.8
@export var reform_speed: float = 0.5

## ── State ────────────────────────────────────────────────────────────────────
var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _light_check_timer: float = 0.0
var _current_light_intensity: float = 0.0
var _dissolve_amount: float = 0.0
var _facing_right: bool = true
var _can_move: bool = true
var _is_dead: bool = false

## ── Child Nodes ──────────────────────────────────────────────────────────────
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var _abilities: Node = null
var _state_machine: Node = null
var _light_system: Node = null

## ═══════════════════════════════════════════════════════════════════════════════
## LIFECYCLE
## ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	add_to_group("shadow_player")
	collision_layer = 0b0001   ## Layer 1: player
	collision_mask = 0b0111    ## Layers 1-3: ground, occluders, platforms
	
	## Find or create child systems
	_abilities = get_node_or_null("ShadowAbilities")
	_state_machine = get_node_or_null("ShadowStateMachine")
	_light_system = get_tree().get_first_node_in_group("light_system")
	
	## Wire up abilities
	if _abilities and _abilities.has_method("set_references"):
		_abilities.set_references(self)
	
	## Wire up state machine
	if _state_machine and _state_machine.has_method("set_references"):
		_state_machine.set_references(self, null, _abilities, null)
	
	## Create placeholder sprite if none exists
	if not sprite:
		_create_placeholder_sprite()
	
	## Create collision shape if none exists
	if not collision_shape:
		_create_default_collision()
	
	if SignalBus:
		SignalBus.shadow_spawned.emit(self)
	
	print("[Shadow] Player spawned at %s" % global_position)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	
	_apply_gravity(delta)
	
	if _can_move:
		_handle_movement(delta)
		_handle_jump(delta)
	
	_update_timers(delta)
	_check_light_vulnerability(delta)
	_update_visual(delta)
	
	move_and_slide()


## ═══════════════════════════════════════════════════════════════════════════════
## MOVEMENT
## ═══════════════════════════════════════════════════════════════════════════════

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var grav := _gravity * gravity_scale
		if velocity.y > 0:
			grav *= fall_gravity_multiplier
		velocity.y += grav * delta


func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")
	
	if abs(input_dir) > 0.1:
		velocity.x = move_toward(velocity.x, input_dir * move_speed, acceleration * delta)
		_facing_right = input_dir > 0
	else:
		var fric := friction if is_on_floor() else air_friction
		velocity.x = move_toward(velocity.x, 0, fric * delta)


func _handle_jump(delta: float) -> void:
	## Coyote time
	if is_on_floor():
		_coyote_timer = coyote_time
	
	## Jump buffer
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	
	## Execute jump
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_force
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		
		if SignalBus:
			SignalBus.sfx_request.emit("shadow_jump", global_position, 0.5)
	
	## Variable jump height — release early for short hop
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5


func _update_timers(delta: float) -> void:
	if _coyote_timer > 0.0:
		_coyote_timer -= delta
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta


## ═══════════════════════════════════════════════════════════════════════════════
## LIGHT VULNERABILITY
## ═══════════════════════════════════════════════════════════════════════════════

func _check_light_vulnerability(delta: float) -> void:
	_light_check_timer += delta
	if _light_check_timer < light_check_interval:
		return
	_light_check_timer = 0.0
	
	## Query light system for intensity at our position
	if not _light_system:
		_light_system = get_tree().get_first_node_in_group("light_system")
	
	if _light_system and _light_system.has_method("get_light_intensity_at"):
		_current_light_intensity = _light_system.get_light_intensity_at(global_position)
	else:
		_current_light_intensity = 0.0
	
	## Update dissolve based on light exposure
	if _current_light_intensity > 0.5:
		## In dangerous light — dissolve
		_dissolve_amount = minf(_dissolve_amount + dissolve_speed * light_check_interval, 1.0)
		
		if SignalBus and _dissolve_amount > 0.3:
			SignalBus.shadow_light_contact.emit(_current_light_intensity, global_position)
		
		## Drain ability integrity too
		if _abilities and _abilities.has_method("drain_integrity"):
			_abilities.drain_integrity(dissolve_speed * light_check_interval * 0.3)
		
		if _dissolve_amount >= 1.0:
			_die()
	elif _current_light_intensity > 0.15:
		## In moderate light — slow dissolve
		_dissolve_amount = minf(_dissolve_amount + dissolve_speed * 0.3 * light_check_interval, 0.6)
	else:
		## In shadow — safe, reform
		_dissolve_amount = maxf(_dissolve_amount - reform_speed * light_check_interval, 0.0)


## ═══════════════════════════════════════════════════════════════════════════════
## VISUAL
## ═══════════════════════════════════════════════════════════════════════════════

func _update_visual(delta: float) -> void:
	## Flip sprite
	if sprite:
		sprite.flip_h = not _facing_right
	
	## Drive shader parameters if material exists
	if sprite and sprite.material is ShaderMaterial:
		var mat := sprite.material as ShaderMaterial
		mat.set_shader_parameter("dissolve_amount", _dissolve_amount)
		mat.set_shader_parameter("shadow_integrity",
			_abilities.get_integrity() if _abilities else 1.0)
		mat.set_shader_parameter("light_intensity", _current_light_intensity)
		
		## Light direction for directional dissolve
		if _light_system and _light_system.has_method("get_all_light_positions"):
			var lights: Array = _light_system.get_all_light_positions()
			if lights.size() > 0:
				var nearest: Vector2 = lights[0]
				var min_dist := global_position.distance_to(nearest)
				for lp in lights:
					var d := global_position.distance_to(lp)
					if d < min_dist:
						min_dist = d
						nearest = lp
				var dir := (nearest - global_position).normalized()
				mat.set_shader_parameter("light_direction", dir)


func _create_placeholder_sprite() -> void:
	sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	
	## Create a simple black rectangle texture as placeholder
	var img := Image.create(24, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.04, 0.04, 0.04, 0.92))
	var tex := ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.offset = Vector2(0, -16)
	
	add_child(sprite)


func _create_default_collision() -> void:
	collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var shape := CapsuleShape2D.new()
	shape.radius = 10.0
	shape.height = 28.0
	collision_shape.shape = shape
	collision_shape.position = Vector2(0, -14)
	add_child(collision_shape)


## ═══════════════════════════════════════════════════════════════════════════════
## STATE CONTROL
## ═══════════════════════════════════════════════════════════════════════════════

func set_can_move(value: bool) -> void:
	_can_move = value
	if not value:
		velocity = Vector2.ZERO


func _die() -> void:
	if _is_dead: return
	_is_dead = true
	_can_move = false
	
	if SignalBus:
		SignalBus.shadow_died.emit()
		SignalBus.sfx_request.emit("shadow_dissolve", global_position, 1.0)
	
	## Respawn after delay
	get_tree().create_timer(1.5).timeout.connect(_respawn)


func _respawn() -> void:
	_is_dead = false
	_can_move = true
	_dissolve_amount = 0.0
	
	## Find spawn point in level
	var spawn := get_tree().get_first_node_in_group("spawn_points")
	if not spawn:
		spawn = get_parent().get_node_or_null("SpawnPoint")
	
	if spawn:
		global_position = spawn.global_position
	
	velocity = Vector2.ZERO
	
	if _abilities and _abilities.has_method("restore_integrity"):
		_abilities.restore_integrity(1.0)

