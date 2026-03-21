extends CharacterBody2D

@export var speed: float = 300.0
@export var acceleration: float = 2000.0
@export var friction: float = 1800.0

var shadow_opacity: float = 1.0
var trail_timer: float = 0.0

func _physics_process(delta: float) -> void:
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")
	input_dir = input_dir.normalized()
	
	if input_dir.length() > 0:
		velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
	
	trail_timer += delta
	if velocity.length() > 50 and trail_timer > 0.05:
		trail_timer = 0.0
		_spawn_ink_trail()

func _spawn_ink_trail() -> void:
	var trail = ColorRect.new()
	trail.size = Vector2(4, 4)
	trail.position = global_position - Vector2(2, 2)
	trail.color = Color(0.039, 0.039, 0.039, 0.12)
	trail.z_index = -1
	get_parent().add_child(trail)
	var tween = create_tween()
	tween.tween_property(trail, "color:a", 0.0, 4.0)
	tween.tween_callback(trail.queue_free)
