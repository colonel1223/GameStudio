## ============================================================================
## UMBRAL — memory_fragment.gd
## Memory Fragment Interaction System · Sprint 2
## ============================================================================
## Memory fragments are the narrative anchors of UMBRAL. When the shadow
## touches a dark stain on the world, a translucent memory materializes —
## a moment from the child's past rendered in sumi-e brush economy.
##
## Each fragment can unlock abilities and advance the narrative.
## ============================================================================
extends Area2D
class_name MemoryFragment

## ── Exported ─────────────────────────────────────────────────────────────────
@export var fragment_id: String = "memory_01"
@export var display_name: String = "The Last Night"
@export var act: int = 1                          ## Which narrative act
@export var level_id: String = "separation"

@export_group("Ability")
@export var unlocks_ability: String = ""          ## e.g. "stretch", "split"
@export var ability_description: String = ""

@export_group("Narrative")
@export var memory_type: MemoryType = MemoryType.STORY
@export var sequence_duration: float = 8.0        ## Seconds for memory playback
@export var dialogue_lines: Array[String] = []    ## Optional dialogue

@export_group("Visual")
@export var ink_stain_radius: float = 32.0        ## Discovery zone radius
@export var ghost_child_scene: PackedScene        ## Memory echo child model
@export var ambient_particles: bool = true
@export var pulse_rate: float = 2.0               ## Ink-drop expansion cycle

enum MemoryType {
	STORY,        ## Advances main narrative
	LORE,         ## World-building detail
	ABILITY,      ## Unlocks new shadow ability
	SECRET,       ## Hidden collectible
}

## ── State ────────────────────────────────────────────────────────────────────
var is_collected: bool = false
var is_playing: bool = false
var is_discovered: bool = false    ## Player has entered proximity
var _pulse_phase: float = 0.0
var _sequence_timer: float = 0.0
var _ghost_instance: Node2D = null
var _original_alpha: float = 0.0

## ── Child Nodes ──────────────────────────────────────────────────────────────
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var ink_stain_visual: Sprite2D = $InkStainVisual
@onready var proximity_area: Area2D = $ProximityArea
@onready var anim_player: AnimationPlayer = $AnimationPlayer

## ── Signals ──────────────────────────────────────────────────────────────────
signal memory_activated(fragment: MemoryFragment)
signal memory_completed(fragment: MemoryFragment)
signal ability_granted(ability_name: String)

## ═══════════════════════════════════════════════════════════════════════════════
## LIFECYCLE
## ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	## Check if already collected
	if GameManager and GameManager.memory_fragments.has(fragment_id):
		if GameManager.memory_fragments[fragment_id].get("collected", false):
			_set_collected_state()
			return
	
	## Setup collision
	collision_layer = 0b10000   ## Layer 5: memory fragments
	collision_mask = 0b0001     ## Layer 1: player
	monitoring = true
	monitorable = true
	
	## Connect detection
	body_entered.connect(_on_shadow_entered)
	
	## Setup proximity detection (larger radius for discovery)
	if proximity_area:
		var prox_shape := CircleShape2D.new()
		prox_shape.radius = ink_stain_radius * 3.0
		var prox_col := CollisionShape2D.new()
		prox_col.shape = prox_shape
		proximity_area.add_child(prox_col)
		proximity_area.body_entered.connect(_on_proximity_entered)
	
	## Initial visual state — dormant ink stain
	if ink_stain_visual:
		ink_stain_visual.modulate = Color(0.15, 0.15, 0.15, 0.4)
		_original_alpha = 0.4
	
	_pulse_phase = randf() * TAU
	add_to_group("memory_fragments")


func _process(delta: float) -> void:
	if is_collected:
		return
	
	## Ink-drop expansion pulse (per art doc: 2-second cycle)
	_pulse_phase += delta * (TAU / pulse_rate)
	var pulse := 1.0 + sin(_pulse_phase) * 0.12
	
	if ink_stain_visual and not is_playing:
		ink_stain_visual.scale = Vector2.ONE * pulse
		
		## Brighten when discovered (player nearby)
		if is_discovered:
			var target_alpha := lerpf(0.4, 0.75, (sin(_pulse_phase) + 1.0) / 2.0)
			ink_stain_visual.modulate.a = lerpf(ink_stain_visual.modulate.a, target_alpha, delta * 3.0)
	
	## Memory sequence playback
	if is_playing:
		_sequence_timer += delta
		_update_memory_sequence(delta)
		
		if _sequence_timer >= sequence_duration:
			_complete_memory_sequence()


## ═══════════════════════════════════════════════════════════════════════════════
## INTERACTION
## ═══════════════════════════════════════════════════════════════════════════════

func _on_proximity_entered(body: Node2D) -> void:
	if is_collected or is_discovered:
		return
	
	if body.is_in_group("shadow_player"):
		is_discovered = true
		
		## Audio: subtle ink settle sound
		if SignalBus:
			SignalBus.sfx_request.emit("ink_settle", global_position, 0.4)
			SignalBus.memory_fragment_discovered.emit(fragment_id, global_position)


func _on_shadow_entered(body: Node2D) -> void:
	if is_collected or is_playing:
		return
	
	if body.is_in_group("shadow_player"):
		_begin_memory_sequence(body)


func _begin_memory_sequence(shadow: Node2D) -> void:
	is_playing = true
	_sequence_timer = 0.0
	
	## Lock player movement via state machine
	if SignalBus:
		SignalBus.memory_sequence_triggered.emit(fragment_id)
		SignalBus.sfx_request.emit("watercolor_bloom", global_position, 0.8)
		SignalBus.emotional_state_changed.emit("memory", 1.0)
	
	memory_activated.emit(self)
	
	## Spawn ghost child memory echo
	_spawn_ghost_child()
	
	## Play memory animation
	if anim_player and anim_player.has_animation("memory_reveal"):
		anim_player.play("memory_reveal")
	else:
		_default_reveal_animation()


func _spawn_ghost_child() -> void:
	if ghost_child_scene:
		_ghost_instance = ghost_child_scene.instantiate()
		_ghost_instance.global_position = global_position
		_ghost_instance.modulate = Color(1.0, 1.0, 1.0, 0.0)  ## Start invisible
		get_parent().add_child(_ghost_instance)
		
		## Fade in ghost child
		var tween := create_tween()
		tween.tween_property(_ghost_instance, "modulate:a", 0.7, 1.5)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_CUBIC)


func _update_memory_sequence(delta: float) -> void:
	var progress := _sequence_timer / sequence_duration
	
	## Update ghost child opacity based on sequence progress
	if _ghost_instance and is_instance_valid(_ghost_instance):
		## Solid in shadow, ghostly in light (per art doc)
		var light_system := get_node_or_null("/root/UmbralLightSystem")
		if light_system and light_system.has_method("get_light_intensity_at"):
			var light_at_ghost := light_system.get_light_intensity_at(_ghost_instance.global_position)
			var ghost_alpha := lerpf(0.8, 0.2, light_at_ghost)
			_ghost_instance.modulate.a = ghost_alpha
	
	## Dialogue progression
	if dialogue_lines.size() > 0:
		var line_index := mini(
			floori(progress * float(dialogue_lines.size())),
			dialogue_lines.size() - 1
		)
		## Could emit signal for subtitle display here
	
	## Visual effects during sequence
	if ink_stain_visual:
		## Ink blooms outward during memory
		var bloom_scale := 1.0 + progress * 0.5
		ink_stain_visual.scale = Vector2.ONE * bloom_scale
		ink_stain_visual.modulate.a = lerpf(0.8, 0.3, progress)


func _complete_memory_sequence() -> void:
	is_playing = false
	is_collected = true
	
	## Fade out ghost child
	if _ghost_instance and is_instance_valid(_ghost_instance):
		var tween := create_tween()
		tween.tween_property(_ghost_instance, "modulate:a", 0.0, 1.0)
		tween.tween_callback(_ghost_instance.queue_free)
	
	## Grant ability if applicable
	if not unlocks_ability.is_empty():
		if GameManager and GameManager.has_method("unlock_ability"):
			GameManager.unlock_ability(unlocks_ability)
		ability_granted.emit(unlocks_ability)
		
		if SignalBus:
			SignalBus.shadow_ability_gained.emit(unlocks_ability)
			SignalBus.sfx_request.emit("ability_unlock", global_position, 1.0)
	
	## Record collection
	if GameManager and GameManager.has_method("collect_memory"):
		GameManager.collect_memory(fragment_id, {
			"level": level_id,
			"act": act,
			"type": MemoryType.keys()[memory_type],
			"unlocks_ability": unlocks_ability,
		})
	
	## Notify systems
	if SignalBus:
		SignalBus.memory_fragment_collected.emit(fragment_id, unlocks_ability)
		SignalBus.memory_sequence_completed.emit(fragment_id)
		SignalBus.sfx_request.emit("page_turn", global_position, 0.6)
	
	memory_completed.emit(self)
	
	## Transition to collected visual state
	_set_collected_state()


func _set_collected_state() -> void:
	is_collected = true
	monitoring = false
	
	if ink_stain_visual:
		## Leave a permanent light gray stain (per art doc)
		var tween := create_tween()
		tween.tween_property(ink_stain_visual, "modulate",
			Color(0.96, 0.96, 0.96, 0.15), 2.0)
	
	if proximity_area:
		proximity_area.monitoring = false
	
	set_process(false)


func _default_reveal_animation() -> void:
	## Fallback reveal animation when no AnimationPlayer is configured
	if ink_stain_visual:
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(ink_stain_visual, "scale",
			Vector2.ONE * 1.8, 1.2)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(ink_stain_visual, "modulate:a",
			0.9, 0.8)\
			.set_ease(Tween.EASE_OUT)


## ═══════════════════════════════════════════════════════════════════════════════
## EDITOR HELPERS
## ═══════════════════════════════════════════════════════════════════════════════

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	
	if fragment_id.is_empty():
		warnings.append("Fragment ID is required for save/load tracking")
	
	if memory_type == MemoryType.ABILITY and unlocks_ability.is_empty():
		warnings.append("ABILITY type fragment has no ability assigned")
	
	if not has_node("CollisionShape2D"):
		warnings.append("Missing CollisionShape2D child node")
	
	return warnings

