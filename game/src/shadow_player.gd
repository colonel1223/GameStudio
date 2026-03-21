class_name ShadowPlayer
extends CharacterBody2D

signal state_changed(new_state: PlayerState)
signal shadow_stretch_started()
signal shadow_stretch_ended()
signal light_vulnerability_triggered(light_source: Node2D)
signal shadow_dissolved()
signal shadow_reformed()

@export_group("Movement")
@export var max_speed: float = 300.0
@export var acceleration: float = 1200.0
@export var friction: float = 800.0
@export var brush_stroke_smoothing: float = 0.15

@export_group("Shadow Abilities")
@export var stretch_multiplier: float = 2.5
@export var stretch_duration: float = 1.5
@export var stretch_cooldown: float = 3.0

@export_group("Light Vulnerability")
@export var dissolve_speed: float = 2.0
@export var light_detection_radius: float = 150.0
@export var vulnerability_grace_period: float = 0.5

@export_group("Visual Effects")
@export var ink_trail_particles: PackedScene
@export var shadow_material: Material

enum PlayerState {
	IDLE,
	MOVING,
	STRETCHING,
	DISSOLVING,
	VULNERABLE
}

var current_state: PlayerState = PlayerState.IDLE
var input_vector: Vector2 = Vector2.ZERO
var smooth_velocity: Vector2 = Vector2.ZERO
var stretch_timer: float = 0.0
var stretch_cooldown_timer: float = 0.0
var dissolve_progress: float = 0.0
var vulnerability_timer: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $ShadowSprite
@onready var light_detection_area: Area2D = $LightDetectionArea
@onready var ink_trail_spawner: Node2D = $InkTrailSpawner
@onready var stretch_tween: Tween
@onready var dissolve_tween: Tween

var original_scale: Vector2
var original_collision_shape: Shape2D
var ink_trail_timer: float = 0.0
var ink_trail_interval: float = 0.1
var light_sources_in_range: Array[Node2D] = []

func _ready() -> void:
	original_scale = sprite.scale
	original_collision_shape = collision_shape.shape
	
	# Setup light detection area
	var circle_shape := CircleShape2D.new()
	circle_shape.radius = light_detection_radius
	var area_collision := CollisionShape2D.new()
	area_collision.shape = circle_shape
	light_detection_area.add_child(area_collision)
	
	light_detection_area.area_entered.connect(_on_light_source_entered)
	light_detection_area.area_exited.connect(_on_light_source_exited)
	light_detection_area.body_entered.connect(_on_light_body_entered)
	light_detection_area.body_exited.connect(_on_light_body_exited)
	
	# Apply shadow material
	if shadow_material:
		sprite.material = shadow_material
	
	# Connect to SignalBus
	SignalBus.connect_shadow_player_signals(self)
	
	change_state(PlayerState.IDLE)

func _physics_process(delta: float) -> void:
	handle_timers(delta)
	handle_input()
	handle_movement(delta)
	handle_state_logic(delta)
	handle_ink_trail(delta)
	
	move_and_slide()

func handle_timers(delta: float) -> void:
	if stretch_timer > 0.0:
		stretch_timer -= delta
	if stretch_cooldown_timer > 0.0:
		stretch_cooldown_timer -= delta
	if vulnerability_timer > 0.0:
		vulnerability_timer -= delta
	ink_trail_timer += delta

func handle_input() -> void:
	if current_state == PlayerState.DISSOLVING:
		return
	
	input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	
	input_vector = input_vector.normalized()
	
	# Handle shadow stretch ability
	if Input.is_action_just_pressed("shadow_stretch") and can_stretch():
		start_shadow_stretch()

func handle_movement(delta: float) -> void:
	if current_state == PlayerState.DISSOLVING or current_state == PlayerState.STRETCHING:
		# Apply friction during special states
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		return
	
	if input_vector != Vector2.ZERO:
		# Smooth acceleration with brush-stroke feel
		var target_velocity = input_vector * max_speed
		smooth_velocity = smooth_velocity.lerp(target_velocity, brush_stroke_smoothing)
		velocity = velocity.move_toward(smooth_velocity, acceleration * delta)
		
		if current_state != PlayerState.MOVING:
			change_state(PlayerState.MOVING)
	else:
		# Apply friction
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		smooth_velocity = smooth_velocity.move_toward(Vector2.ZERO, friction * delta)
		
		if velocity.length() < 5.0 and current_state == PlayerState.MOVING:
			change_state(PlayerState.IDLE)

func handle_state_logic(delta: float) -> void:
	match current_state:
		PlayerState.STRETCHING:
			if stretch_timer <= 0.0:
				end_shadow_stretch()
		
		PlayerState.VULNERABLE:
			if vulnerability_timer <= 0.0 and light_sources_in_range.is_empty():
				change_state(PlayerState.IDLE)
		
		PlayerState.DISSOLVING:
			dissolve_progress += dissolve_speed * delta
			update_dissolve_effect()
			
			if dissolve_progress >= 1.0:
				complete_dissolution()

func handle_ink_trail(delta: float) -> void:
	if current_state == PlayerState.MOVING and ink_trail_timer >= ink_trail_interval:
		spawn_ink_trail_particle()
		ink_trail_timer = 0.0

func spawn_ink_trail_particle() -> void:
	if ink_trail_particles and ink_trail_spawner:
		var particle_instance = ink_trail_particles.instantiate()
		get_parent().add_child(particle_instance)
		particle_instance.global_position = ink_trail_spawner.global_position
		
		# Add slight randomness for organic feel
		var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		particle_instance.global_position += offset

func can_stretch() -> bool:
	return (current_state == PlayerState.IDLE or current_state == PlayerState.MOVING) and \
		   stretch_cooldown_timer <= 0.0 and \
		   current_state != PlayerState.VULNERABLE

func start_shadow_stretch() -> void:
	change_state(PlayerState.STRETCHING)
	stretch_timer = stretch_duration
	stretch_cooldown_timer = stretch_cooldown
	
	# Create stretch animation
	if stretch_tween:
		stretch_tween.kill()
	stretch_tween = create_tween()
	stretch_tween.set_parallel(true)
	
	# Stretch sprite
	stretch_tween.tween_property(sprite, "scale", original_scale * stretch_multiplier, 0.3)
	stretch_tween.tween_property(sprite, "modulate:a", 0.7, 0.3)
	
	shadow_stretch_started.emit()
	SignalBus.shadow_stretch_activated.emit(self)

func end_shadow_stretch() -> void:
	if stretch_tween:
		stretch_tween.kill()
	stretch_tween = create_tween()
	stretch_tween.set_parallel(true)
	
	# Return to normal
	stretch_tween.tween_property(sprite, "scale", original_scale, 0.2)
	stretch_tween.tween_property(sprite, "modulate:a", 1.0, 0.2)
	
	shadow_stretch_ended.emit()
	SignalBus.shadow_stretch_deactivated.emit(self)
	
	# Return to appropriate state based on movement
	if input_vector != Vector2.ZERO:
		change_state(PlayerState.MOVING)
	else:
		change_state(PlayerState.IDLE)

func trigger_light_vulnerability(light_source: Node2D) -> void:
	if current_state == PlayerState.DISSOLVING:
		return
	
	light_vulnerability_triggered.emit(light_source)
	SignalBus.shadow_light_contact.emit(self, light_source)
	
	if current_state == PlayerState.STRETCHING:
		# Cancel stretch if hit by light
		end_shadow_stretch()
	
	vulnerability_timer = vulnerability_grace_period
	change_state(PlayerState.VULNERABLE)
	
	# Start dissolving if in direct light
	if is_in_direct_light():
		start_dissolution()

func start_dissolution() -> void:
	change_state(PlayerState.DISSOLVING)
	dissolve_progress = 0.0
	
	if dissolve_tween:
		dissolve_tween.kill()
	dissolve_tween = create_tween()
	
	SignalBus.shadow_dissolve_started.emit(self)

func update_dissolve_effect() -> void:
	# Update visual dissolution
	sprite.modulate.a = lerp(1.0, 0.0, dissolve_progress)
	
	# Shrink collision shape
	if collision_shape.shape is CircleShape2D:
		var circle = collision_shape.shape as CircleShape2D
		var original_radius = (original_collision_shape as CircleShape2D).radius
		circle.radius = lerp(original_radius, 0.0, dissolve_progress)

func complete_dissolution() -> void:
	shadow_dissolved.emit()
	SignalBus.shadow_fully_dissolved.emit(self)
	
	# Hide player but keep processing for reformation
	visible = false
	collision_shape.disabled = true
	
	# Start reformation timer or trigger game over
	await get_tree().create_timer(2.0).timeout
	attempt_reformation()

func attempt_reformation() -> void:
	if not is_in_direct_light():
		reform_shadow()
	else:
		# Try again later
		await get_tree().create_timer(1.0).timeout
		attempt_reformation()

func reform_shadow() -> void:
	visible = true
	collision_shape.disabled = false
	dissolve_progress = 0.0
	sprite.modulate.a = 1.0
	
	# Reset collision shape
	collision_shape.shape = original_collision_shape
	
	shadow_reformed.emit()
	SignalBus.shadow_reformed.emit(self)
	
	change_state(PlayerState.IDLE)

func is_in_direct_light() -> bool:
	return not light_sources_in_range.is_empty()

func change_state(new_state: PlayerState) -> void:
	if current_state == new_state:
		return
	
	var old_state = current_state
	current_state = new_state
	
	state_changed.emit(new_state)
	SignalBus.shadow_state_changed.emit(self, old_state, new_state)

func _on_light_source_entered(area: Area2D) -> void:
	if area.has_method("get_light_intensity"):
		light_sources_in_range.append(area)
		trigger_light_vulnerability(area)

func _on_light_source_exited(area: Area2D) -> void:
	if area in light_sources_in_range:
		light_sources_in_range.erase(area)

func _on_light_body_entered(body: Node2D) -> void:
	if body.has_method("get_light_intensity"):
		light_sources_in_range.append(body)
		trigger_light_vulnerability(body)

func _on_light_body_exited(body: Node2D) -> void:
	if body in light_sources_in_range:
		light_sources_in_range.erase(body)

func get_current_state() -> PlayerState:
	return current_state

func get_stretch_progress() -> float:
	if current_state != PlayerState.STRETCHING:
		return 0.0
	return 1.0 - (stretch_timer / stretch_duration)

func get_dissolve_progress() -> float:
	return dissolve_progress

func is_vulnerable() -> bool:
	return current_state == PlayerState.VULNERABLE or current_state == PlayerState.DISSOLVING