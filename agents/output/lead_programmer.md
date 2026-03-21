# Lead Programmer

# UMBRAL - Complete Godot 4 Project Architecture

## Project Folder Structure
```
res://
├── scenes/
│   ├── main/
│   │   ├── main.tscn
│   │   └── main.gd
│   ├── levels/
│   │   ├── level_01_separation.tscn
│   │   ├── level_02_garden.tscn
│   │   ├── level_03_corridor.tscn
│   │   └── level_04_reunion.tscn
│   ├── player/
│   │   ├── shadow.tscn
│   │   └── shadow.gd
│   ├── environment/
│   │   ├── light_source.tscn
│   │   ├── memory_fragment.tscn
│   │   ├── shadow_platform.tscn
│   │   └── audio_zone.tscn
│   └── ui/
│       ├── pause_menu.tscn
│       └── transition.tscn
├── scripts/
│   ├── core/
│   │   ├── game_manager.gd
│   │   ├── signal_bus.gd
│   │   ├── audio_manager.gd
│   │   └── scene_manager.gd
│   ├── player/
│   │   ├── shadow_state_machine.gd
│   │   ├── shadow_movement.gd
│   │   └── shadow_abilities.gd
│   ├── environment/
│   │   ├── light_manipulator.gd
│   │   ├── shadow_caster.gd
│   │   └── memory_system.gd
│   └── ui/
│       ├── transition_manager.gd
│       └── settings_manager.gd
├── assets/
│   ├── textures/
│   │   ├── paper/
│   │   ├── ink/
│   │   └── light/
│   ├── audio/
│   │   ├── sfx/
│   │   ├── music/
│   │   └── ambient/
│   ├── shaders/
│   │   ├── shadow_dissolve.gdshader
│   │   ├── ink_stain.gdshader
│   │   └── light_bloom.gdshader
│   └── fonts/
│       └── sumi_brush.ttf
├── data/
│   ├── level_data/
│   ├── memory_fragments/
│   └── save_system/
└── project.godot
```

## Core Systems Architecture

### AutoLoad Order (project.godot)
```ini
[autoload]

SignalBus="*res://scripts/core/signal_bus.gd"
GameManager="*res://scripts/core/game_manager.gd"
AudioManager="*res://scripts/core/audio_manager.gd"
SceneManager="*res://scripts/core/scene_manager.gd"
```

---

# COMPLETE signal_bus.gd
```gdscript
extends Node
class_name SignalBusClass

# Core Game Flow Signals
signal game_started
signal game_paused(is_paused: bool)
signal game_over(victory: bool)
signal level_completed(level_name: String)
signal level_failed(reason: String)

# Player/Shadow Signals
signal shadow_spawned(shadow: CharacterBody2D)
signal shadow_died
signal shadow_state_changed(old_state: String, new_state: String)
signal shadow_ability_gained(ability_name: String)
signal shadow_ability_used(ability_name: String)
signal shadow_light_contact(intensity: float, source_position: Vector2)
signal shadow_safe_zone_entered
signal shadow_safe_zone_exited

# Light System Signals
signal light_source_activated(light_id: String, position: Vector2)
signal light_source_deactivated(light_id: String)
signal light_source_moved(light_id: String, from: Vector2, to: Vector2)
signal light_source_rotated(light_id: String, angle: float)
signal shadow_path_created(path_points: PackedVector2Array)
signal shadow_path_destroyed(path_id: String)

# Memory System Signals
signal memory_fragment_discovered(fragment_id: String, position: Vector2)
signal memory_fragment_collected(fragment_id: String, ability_unlocked: String)
signal memory_sequence_triggered(sequence_name: String)
signal memory_sequence_completed(sequence_name: String)
signal narrative_beat_triggered(beat_name: String)

# Environment Signals
signal platform_created(platform: Area2D, duration: float)
signal platform_destroyed(platform: Area2D)
signal puzzle_element_activated(element_id: String)
signal puzzle_solved(puzzle_id: String)
signal secret_area_unlocked(area_name: String)

# Audio Signals
signal audio_zone_entered(zone_name: String, ambient_type: String)
signal audio_zone_exited(zone_name: String)
signal music_layer_request(layer: String, intensity: float)
signal sfx_request(sound_name: String, position: Vector2, volume: float)
signal emotional_state_changed(new_state: String, transition_time: float)

# UI/Menu Signals
signal menu_opened(menu_type: String)
signal menu_closed(menu_type: String)
signal settings_changed(setting_name: String, value: Variant)
signal scene_transition_requested(scene_path: String, transition_type: String)
signal fade_requested(fade_in: bool, duration: float)

# Save/Load Signals
signal save_requested(save_slot: int)
signal load_requested(save_slot: int)
signal save_completed(success: bool, save_slot: int)
signal load_completed(success: bool, save_slot: int)
signal checkpoint_reached(checkpoint_id: String, data: Dictionary)

# Debug Signals (removed in release builds)
signal debug_info_requested(category: String)
signal debug_command_executed(command: String, params: Array)
signal performance_warning(warning_type: String, details: Dictionary)

# Validation and connection helpers
var _signal_connections: Dictionary = {}
var _debug_mode: bool = false

func _ready() -> void:
	_debug_mode = OS.is_debug_build()
	if _debug_mode:
		_setup_debug_logging()

func _setup_debug_logging() -> void:
	# Connect all signals to debug logger in debug builds
	var signal_list = get_signal_list()
	for signal_info in signal_list:
		var signal_name = signal_info["name"]
		if not signal_name.begins_with("_"):
			connect(signal_name, _debug_signal_fired.bind(signal_name))

func _debug_signal_fired(signal_name: String, args: Array = []) -> void:
	if _debug_mode:
		print("[SignalBus] %s fired with args: %s" % [signal_name, args])

# Safe connection helper with error handling
func safe_connect(source: Object, signal_name: String, target: Object, method_name: String, flags: int = 0) -> bool:
	if not is_instance_valid(source) or not is_instance_valid(target):
		push_error("SignalBus: Invalid object in connection attempt")
		return false
	
	if not source.has_signal(signal_name):
		push_error("SignalBus: Signal '%s' not found on source object" % signal_name)
		return false
	
	if not target.has_method(method_name):
		push_error("SignalBus: Method '%s' not found on target object" % method_name)
		return false
	
	var error = source.connect(signal_name, Callable(target, method_name), flags)
	if error != OK:
		push_error("SignalBus: Failed to connect signal '%s' to method '%s'" % [signal_name, method_name])
		return false
	
	# Track connection for debugging
	if _debug_mode:
		var connection_id = "%s::%s -> %s::%s" % [source.name, signal_name, target.name, method_name]
		_signal_connections[connection_id] = true
	
	return true

# Emit with validation
func safe_emit(signal_name: String, args: Array = []) -> bool:
	if not has_signal(signal_name):
		push_error("SignalBus: Attempting to emit non-existent signal '%s'" % signal_name)
		return false
	
	match args.size():
		0: emit_signal(signal_name)
		1: emit_signal(signal_name, args[0])
		2: emit_signal(signal_name, args[0], args[1])
		3: emit_signal(signal_name, args[0], args[1], args[2])
		4: emit_signal(signal_name, args[0], args[1], args[2], args[3])
		5: emit_signal(signal_name, args[0], args[1], args[2], args[3], args[4])
		_:
			push_error("SignalBus: Too many arguments for signal emission")
			return false
	
	return true

# Get connection count for monitoring
func get_connection_count(signal_name: String) -> int:
	if not has_signal(signal_name):
		return 0
	return get_signal_connection_list(signal_name).size()

# Cleanup on exit
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_signal_connections.clear()
```

---

# COMPLETE shadow_state_machine.gd
```gdscript
extends Node
class_name ShadowStateMachine

enum State {
	IDLE,
	MOVING,
	STRETCHING,
	SPLITTING,
	REFORMING,
	DISSOLVING,
	VULNERABLE,
	MEMORY_VIEWING,
	DISABLED
}

@export var initial_state: State = State.IDLE
@export var debug_state_changes: bool = false

var current_state: State
var previous_state: State
var state_time: float = 0.0
var state_history: Array[State] = []
var can_transition: bool = true

# State transition table - defines valid transitions
var valid_transitions: Dictionary = {
	State.IDLE: [State.MOVING, State.STRETCHING, State.SPLITTING, State.MEMORY_VIEWING, State.DISSOLVING],
	State.MOVING: [State.IDLE, State.STRETCHING, State.SPLITTING, State.VULNERABLE, State.DISSOLVING],
	State.STRETCHING: [State.IDLE, State.MOVING, State.REFORMING, State.DISSOLVING],
	State.SPLITTING: [State.REFORMING, State.DISSOLVING],
	State.REFORMING: [State.IDLE, State.MOVING],
	State.DISSOLVING: [State.REFORMING, State.DISABLED],
	State.VULNERABLE: [State.MOVING, State.DISSOLVING, State.REFORMING],
	State.MEMORY_VIEWING: [State.IDLE],
	State.DISABLED: [State.REFORMING]
}

# References
var shadow: CharacterBody2D
var movement_component: Node
var abilities_component: Node
var light_detector: Area2D

# State-specific timers
var stretch_duration: float = 2.0
var split_duration: float = 1.5
var reform_duration: float = 1.0
var dissolve_duration: float = 0.5
var vulnerability_grace_period: float = 0.3

# Signals
signal state_entered(state: State)
signal state_exited(state: State)
signal transition_denied(from_state: State, to_state: State)

func _ready() -> void:
	current_state = initial_state
	previous_state = initial_state
	state_history.append(current_state)
	
	# Connect to SignalBus
	SignalBus.shadow_light_contact.connect(_on_light_contact)
	SignalBus.memory_fragment_discovered.connect(_on_memory_discovered)
	
	# Start initial state
	call_deferred("_enter_state", current_state)

func _process(delta: float) -> void:
	state_time += delta
	_update_current_state(delta)

func _update_current_state(delta: float) -> void:
	match current_state:
		State.IDLE:
			_update_idle_state(delta)
		State.MOVING:
			_update_moving_state(delta)
		State.STRETCHING:
			_update_stretching_state(delta)
		State.SPLITTING:
			_update_splitting_state(delta)
		State.REFORMING:
			_update_reforming_state(delta)
		State.DISSOLVING:
			_update_dissolving_state(delta)
		State.VULNERABLE:
			_update_vulnerable_state(delta)
		State.MEMORY_VIEWING:
			_update_memory_viewing_state(delta)
		State.DISABLED:
			_update_disabled_state(delta)

# State update functions
func _update_idle_state(delta: float) -> void:
	if shadow and shadow.velocity.length() > 10.0:
		transition_to(State.MOVING)

func _update_moving_state(delta: float) -> void:
	if not shadow:
		return
	
	if shadow.velocity.length() < 5.0:
		transition_to(State.IDLE)

func _update_stretching_state(delta: float) -> void:
	if state_time >= stretch_duration:
		if abilities_component and abilities_component.stretch_target_reached():
			transition_to(State.IDLE)
		else:
			transition_to(State.REFORMING)

func _update_splitting_state(delta: float) -> void:
	if state_time >= split_duration:
		if abilities_component and abilities_component.split_complete():
			transition_to(State.IDLE)
		else:
			transition_to(State.REFORMING)

func _update_reforming_state(delta: float) -> void:
	if state_time >= reform_duration:
		transition_to(State.IDLE)

func _update_dissolving_state(delta: float) -> void:
	if state_time >= dissolve_duration:
		if abilities_component and abilities_component.get_integrity() <= 0.0:
			transition_to(State.DISABLED)
		else:
			transition_to(State.REFORMING)

func _update_vulnerable_state(delta: float) -> void:
	if state_time >= vulnerability_grace_period:
		if light_detector and not light_detector.is_in_light():
			transition_to(State.MOVING)
		else:
			transition_to(State.DISSOLVING)

func _update_memory_viewing_state(delta: float) -> void:
	# Memory viewing ends when memory sequence completes
	pass

func _update_disabled_state(delta: float) -> void:
	# Can only exit disabled state through external triggers
	pass

# Transition system
func transition_to(new_state: State) -> bool:
	if not can_transition:
		return false
	
	if not _is_valid_transition(current_state, new_state):
		transition_denied.emit(current_state, new_state)
		if debug_state_changes:
			print("Invalid transition from %s to %s" % [State.keys()[current_state], State.keys()[new_state]])
		return false
	
	_exit_state(current_state)
	previous_state = current_state
	current_state = new_state
	state_time = 0.0
	state_history.append(current_state)
	_enter_state(new_state)
	
	# Emit state change signal
	SignalBus.shadow_state_changed.emit(State.keys()[previous_state], State.keys()[current_state])
	
	if debug_state_changes:
		print("State transition: %s -> %s" % [State.keys()[previous_state], State.keys()[current_state]])
	
	return true

func force_transition_to(new_state: State) -> void:
	can_transition = true
	transition_to(new_state)

func _is_valid_transition(from_state: State, to_state: State) -> bool:
	return to_state in valid_transitions.get(from_state, [])

func _enter_state(state: State) -> void:
	state_entered.emit(state)
	
	match state:
		State.IDLE:
			_enter_idle_state()
		State.MOVING:
			_enter_moving_state()
		State.STRETCHING:
			_enter_stretching_state()
		State.SPLITTING:
			_enter_splitting_state()
		State.REFORMING:
			_enter_reforming_state()
		State.DISSOLVING:
			_enter_dissolving_state()
		State.VULNERABLE:
			_enter_vulnerable_state()
		State.MEMORY_VIEWING:
			_enter_memory_viewing_state()
		State.DISABLED:
			_enter_disabled_state()

func _exit_state(state: State) -> void:
	state_exited.emit(state)
	
	match state:
		State.IDLE:
			_exit_idle_state()
		State.MOVING:
			_exit_moving_state()
		State.STRETCHING:
			_exit_stretching_state()
		State.SPLITTING:
			_exit_splitting_state()
		State.REFORMING:
			_exit_reforming_state()
		State.DISSOLVING:
			_exit_dissolving_state()
		State.VULNERABLE:
			_exit_vulnerable_state()
		State.MEMORY_VIEWING:
			_exit_memory_viewing_state()
		State.DISABLED:
			_exit_disabled_state()

# State enter functions
func _enter_idle_state() -> void:
	if movement_component:
		movement_component.set_can_move(true)
	if abilities_component:
		abilities_component.set_can_use_abilities(true)

func _enter_moving_state() -> void:
	SignalBus.sfx_request.emit("shadow_movement", shadow.global_position if shadow else Vector2.ZERO, 0.7)

func _enter_stretching_state() -> void:
	if movement_component:
		movement_component.set_can_move(false)
	if abilities_component:
		abilities_component.start_stretch()
	SignalBus.sfx_request.emit("shadow_stretch", shadow.global_position if shadow else Vector2.ZERO, 0.8)

func _enter_splitting_state() -> void:
	if movement_component:
		movement_component.set_can_move(false)
	if abilities_component:
		abilities_component.start_split()
	SignalBus.sfx_request.emit("shadow_split", shadow.global_position if shadow else Vector2.ZERO, 0.9)

func _enter_reforming_state() -> void:
	if movement_component:
		movement_component.set_can_move(false)
	if abilities_component:
		abilities_component.start_reform()
	SignalBus.sfx_request.emit("shadow_reform", shadow.global_position if shadow else Vector2.ZERO, 0.8)

func _enter_dissolving_state() -> void:
	if movement_component:
		movement_component.set_can_move(false)
	if abilities_component:
		abilities_component.start_dissolve()
	SignalBus.sfx_request.emit("shadow_dissolve", shadow.global_position if shadow else Vector2.ZERO, 1.0)
	SignalBus.emotional_state_changed.emit("pain", 0.5)

func _enter_vulnerable_state() -> void:
	if abilities_component:
		abilities_component.set_vulnerability(true)
	SignalBus.emotional_state_changed.emit("fear", 0.3)

func _enter_memory_viewing_state() -> void:
	if movement_component:
		movement_component.set_can_move(false)
	if abilities_component:
		abilities_component.set_can_use_abilities(false)
	SignalBus.emotional_state_changed.emit("memory", 1.0)

func _enter_disabled_state() -> void:
	if movement_component:
		movement_component.set_can_move(false)
	if abilities_component:
		abilities_component.set_can_use_abilities(false)
	SignalBus.shadow_died.emit()

# State exit functions (most are empty but provided for completeness)
func _exit_idle_state() -> void:
	pass

func _exit_moving_state() -> void:
	pass

func _exit_stretching_state() -> void:
	if abilities_component:
		abilities_component.end_stretch()

func _exit_splitting_state() -> void:
	if abilities_component:
		abilities_component.end_split()

func _exit_reforming_state() -> void:
	if abilities_component:
		abilities_component.end_reform()

func _exit_dissolving_state() -> void:
	if abilities_component:
		abilities_component.end_dissolve()

func _exit_vulnerable_state() -> void:
	if abilities_component:
		abilities_component.set_vulnerability(false)

func _exit_memory_viewing_state() -> void:
	pass

func _exit_disabled_state() -> void:
	if abilities_component:
		abilities_component.restore_integrity(1.0)

# External event handlers
func _on_light_contact(intensity: float, source_position: Vector2) -> void:
	if current_state in [State.MOVING, State.IDLE]:
		if intensity > 0.7:
			transition_to(State.DISSOLVING)
		else:
			transition_to(State.VULNERABLE)

func _on_memory_discovered(fragment_id: String, position: Vector2) -> void:
	if current_state in [State.IDLE, State.MOVING]:
		transition_to(State.MEMORY_VIEWING)

# Ability triggers
func try_stretch() -> bool:
	return transition_to(State.STRETCHING)

func try_split() -> bool:
	return transition_to(State.SPLITTING)

func try_reform() -> bool:
	if current_state in [State.SPLITTING, State.STRETCHING, State.DISSOLVING]:
		return transition_to(State.REFORMING)
	return false

# Utility functions
func get_current_state_name() -> String:
	return State.keys()[current_state]

func get_previous_state_name() -> String:
	return State.keys()[previous_state]

func get_state_duration() -> float:
	return state_time

func is_in_state(state: State) -> bool:
	return current_state == state

func is_in_any_state(states: Array[State]) -> bool:
	return current_state in states

func can_move() -> bool:
	return current_state in [State.IDLE, State.MOVING]

func can_use_abilities() -> bool:
	return current_state in [State.IDLE, State.MOVING]

func set_references(shadow_ref: CharacterBody2D, movement_ref: Node, abilities_ref: Node, light_detector_ref: Area2D) -> void:
	shadow = shadow_ref
	movement_component = movement_ref
	abilities_component = abilities_ref
	light_detector = light_detector_ref

# Memory management
func clear_history() -> void:
	state_history.clear()
	state_history.append(current_state)

func get_state_history() -> Array[State]:
	return state_history.duplicate()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		state_history.clear()
```

---

# COMPLETE game_manager.gd
```gdscript
extends Node
class_name GameManagerClass

enum GameState {
	LOADING,
	MAIN_MENU,
	PLAYING,
	PAUSED,
	LEVEL_TRANSITION,
	GAME_OVER,
	SETTINGS
}

enum Difficulty {
	STORY,      # Focus on narrative, forgiving mechanics
	BALANCED,   # Standard experience
	SHADOW      # Challenging, minimal guidance
}

@export var target_fps: int = 60
@export var auto_save_interval: float = 30.0
@export var level_transition_duration: float = 2.0

# Game State
var current_game_state: GameState = GameState.LOADING
var current_difficulty: Difficulty = Difficulty.BALANCED
var current_level: String = ""
var game_time: float = 0.0
var level_time: float = 0.0
var paused_time: float = 0.0

# Level Management
var level_order: Array[String] = [
	"level_01_separation",
	"level_02_garden", 
	"level_03_corridor",
	"level_04_reunion"
]
var current_level_index: int = 0
var levels_completed: Array[String] = []
var level_stats: Dictionary = {}

# Player Progress
var shadow_abilities: Array[String] = []
var memory_fragments_collected: Array[String] = []
var secrets_discovered: Array[String] = []
var death_count: int = 0
var completion_percentage: float = 0.0

# Performance Monitoring
var frame_time_history: Array[float] = []
var max_frame_history: int = 60
var performance_warnings: int = 0

# Settings
var settings: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"ambient_volume": 0.6,
	"fullscreen": false,
	"vsync": true,
	"shadow_quality": 2,  # 0=low, 1=medium, 2=high
	"particle_density": 1.0,
	"ink_effects": true,
	"accessibility_mode": false,
	"input_buffer_ms": 100
}

# Save Data Structure
var save_data: Dictionary = {
	"version": "1.0",
	"timestamp": 0,
	"game_time": 0.0,
	"current_level": "",
	"difficulty": Difficulty.BALANCED,
	"shadow_abilities": [],
	"memory_fragments": [],
	"secrets_discovered": [],
	"level_stats": {},
	"settings": {},
	"completion_percentage": 0.0
}

# Timers
var auto_save_timer: Timer
var performance_monitor_timer: Timer

# Signals - connected in _ready()
signal game_state_changed(old_state: GameState, new_state: GameState)
signal level_progress_updated(percentage: float)
signal ability_unlocked(ability_name: String)
signal achievement_unlocked(achievement_id: String)

func _ready() -> void:
	_setup_timers()
	_connect_signals()
	_initialize_settings()
	_setup_performance_monitoring()
	
	# Start game
	change_game_state(GameState.MAIN_MENU)
	
	print("UMBRAL Game Manager initialized")

func _process(delta: float) -> void:
	if current_game_state == GameState.PLAYING:
		game_time += delta
		level_time += delta
	
	_update_performance_monitoring(delta)

func _setup_timers() -> void:
	# Auto-save timer
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = auto_save_interval
	auto_save_timer.autostart = false
	auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	add_child(auto_save_timer)
	
	# Performance monitoring timer
	performance_monitor_timer = Timer.new()
	performance_monitor_timer.wait_time = 1.0  # Check every second
	performance_monitor_timer.autostart = true
	performance_monitor_timer.timeout.connect(_on_performance_monitor_timeout)
	add_child(performance_monitor_timer)

func _connect_signals() -> void:
	# Core game flow
	SignalBus.level_completed.connect(_on_level_completed)
	SignalBus.level_failed.connect(_on_level_failed)
	SignalBus.shadow_died.connect(_on_shadow_died)
	SignalBus.game_paused.connect(_on_game_paused)
	
	# Progress tracking
	SignalBus.shadow_ability_gained.connect(_on_ability_gained)
	SignalBus.memory_fragment_collected.connect(_on_memory_collected)
	SignalBus.secret_area_unlocked.connect(_on_secret_discovered)
	SignalBus.checkpoint_reached.connect(_on_checkpoint_reached)
	
	# Scene management
	SignalBus.scene_transition_requested.connect(_on_scene_transition_requested)
	SignalBus.save_requested.connect(_on_save_requested)
	SignalBus.load_requested.connect(_on_load_requested)
	
	# Settings
	SignalBus.settings_changed.connect(_on_settings_changed)

func _initialize_settings() -> void:
	# Load settings from file or use defaults
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		for key in settings.keys():
			settings[key] = config.get_value("settings", key, settings[key])
	
	_apply_settings()

func _apply_settings() -> void:
	# Audio
	AudioServer.set_bus_volume_db(0, linear_to_db(settings.master_volume))
	AudioServer.set_bus_volume_db(1, linear_to_db(settings.music_volume))
	AudioServer.set_bus_volume_db(2, linear_to_db(settings.sfx_volume))
	AudioServer.set_bus_volume_db(3, linear_to_db(settings.ambient_volume))
	
	# Display
	if settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED
	)
	
	# Performance
	Engine.max_fps = target_fps if not settings.vsync else 0

# Game State Management
func change_game_state(new_state: GameState) -> void:
	var old_state = current_game_state
	current_game_state = new_state
	
	_handle_state_transition(old_state, new_state)
	game_state_changed.emit(old_state, new_state)
	
	print("Game State: %s -> %s" % [GameState.keys()[old_state], GameState.keys()[new_state]])

func _handle_state_transition(old_state: GameState, new_state: GameState) -> void:
	match new_state:
		GameState.LOADING:
			_enter_loading_state()
		GameState.MAIN_MENU:
			_enter_main_menu_state()
		GameState.PLAYING:
			_enter_playing_state()
		GameState.PAUSED:
			_enter_paused_state()
		GameState.LEVEL_TRANSITION:
			_enter_level_transition_state()
		GameState.GAME_OVER:
			_enter_game_over_state()
		GameState.SETTINGS:
			_enter_settings_state()

func _enter_loading_state() -> void:
	get_tree().paused = false

func _enter_main_menu_state() -> void:
	get_tree().paused = false
	auto_save_timer.stop()
	SceneManager.load_scene("res://scenes/main/main.tscn")

func _enter_playing_state() -> void:
	get_tree().paused = false
	auto_save_timer.start()
	level_time = 