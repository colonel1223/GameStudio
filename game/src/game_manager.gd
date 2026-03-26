## ============================================================================
## UMBRAL — game_manager.gd
## GameManager Autoload · Sprint 1 Completion
## ============================================================================
## Manages game state, progression, save/load, settings, and performance.
## AutoLoad order: SignalBus → GameManager → AudioManager → SceneManager
## ============================================================================
extends Node

enum GameState {
	BOOT,
	LOADING,
	MAIN_MENU,
	PLAYING,
	PAUSED,
	LEVEL_TRANSITION,
	MEMORY_SEQUENCE,
	GAME_OVER,
	CREDITS
}

enum Difficulty {
	STORY,      ## Forgiving — narrative focus, extended grace periods
	BALANCED,   ## Standard — the intended experience
	SHADOW      ## Punishing — minimal guidance, tighter windows
}

## ── Constants ────────────────────────────────────────────────────────────────
const SAVE_DIR := "user://saves/"
const SAVE_FILE := "umbral_save_%d.tres"
const SETTINGS_FILE := "user://settings.cfg"
const MAX_SAVE_SLOTS := 3
const AUTO_SAVE_INTERVAL := 45.0
const PERF_SAMPLE_SIZE := 120
const VERSION := "0.1.0"

## ── Exported ─────────────────────────────────────────────────────────────────
@export var target_fps: int = 60
@export var debug_overlay: bool = false

## ── State ────────────────────────────────────────────────────────────────────
var state: GameState = GameState.BOOT
var difficulty: Difficulty = Difficulty.BALANCED
var is_first_launch: bool = true

## ── Level Tracking ───────────────────────────────────────────────────────────
var level_registry: Dictionary = {
	"separation": {
		"scene": "res://scenes/levels/level_01_separation.tscn",
		"order": 0,
		"act": 1,
		"display_name": "The White Room"
	},
	"garden": {
		"scene": "res://scenes/levels/level_02_garden.tscn",
		"order": 1,
		"act": 2,
		"display_name": "Memory Garden"
	},
	"corridor": {
		"scene": "res://scenes/levels/level_03_corridor.tscn",
		"order": 2,
		"act": 2,
		"display_name": "Hospital Corridor"
	},
	"reunion": {
		"scene": "res://scenes/levels/level_04_reunion.tscn",
		"order": 3,
		"act": 3,
		"display_name": "Golden Hour"
	}
}

var current_level_id: String = ""
var levels_completed: Array[String] = []

## ── Player Progress ──────────────────────────────────────────────────────────
var shadow_abilities: Array[String] = ["move"]  ## Start with basic movement
var memory_fragments: Dictionary = {}           ## fragment_id → { collected, data }
var secrets_found: Array[String] = []
var checkpoints: Dictionary = {}                ## level_id → checkpoint_data
var death_count: int = 0
var total_play_time: float = 0.0
var session_start_time: float = 0.0

## ── Performance ──────────────────────────────────────────────────────────────
var _frame_times: PackedFloat64Array = PackedFloat64Array()
var _fps_avg: float = 60.0
var _perf_warnings: int = 0

## ── Settings ─────────────────────────────────────────────────────────────────
var settings: Dictionary = {
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"ambient_volume": 0.6,
	},
	"display": {
		"fullscreen": false,
		"vsync": true,
		"resolution_scale": 1.0,
		"window_size": Vector2i(1920, 1080),
	},
	"graphics": {
		"shadow_quality": 2,          ## 0=low, 1=med, 2=high
		"particle_density": 1.0,
		"ink_effects_enabled": true,
		"light_bloom_enabled": true,
	},
	"gameplay": {
		"input_buffer_ms": 100,
		"screen_shake": true,
		"accessibility_high_contrast": false,
		"accessibility_larger_shadow": false,
	}
}

## ── Timers ────────────────────────────────────────────────────────────────────
var _auto_save_timer: Timer
var _level_timer: float = 0.0

## ── Signals ──────────────────────────────────────────────────────────────────
signal state_changed(old: GameState, new: GameState)
signal progress_updated(completion_pct: float)

## ═══════════════════════════════════════════════════════════════════════════════
## LIFECYCLE
## ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  ## Run even when paused
	_ensure_save_directory()
	_load_settings()
	_apply_settings()
	_setup_auto_save()
	_connect_signals()
	session_start_time = Time.get_unix_time_from_system()
	
	if OS.is_debug_build() and debug_overlay:
		_setup_debug_overlay()
	
	print("[GameManager] UMBRAL v%s initialized" % VERSION)
	change_state(GameState.MAIN_MENU)


func _process(delta: float) -> void:
	match state:
		GameState.PLAYING:
			total_play_time += delta
			_level_timer += delta
		GameState.PAUSED:
			pass  ## Time frozen
	
	_track_performance(delta)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			_on_quit()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if state == GameState.PLAYING:
				pause_game()


## ═══════════════════════════════════════════════════════════════════════════════
## STATE MACHINE
## ═══════════════════════════════════════════════════════════════════════════════

func change_state(new_state: GameState) -> void:
	if state == new_state:
		return
	
	var old := state
	_exit_state(old)
	state = new_state
	_enter_state(new_state)
	state_changed.emit(old, new_state)
	
	if OS.is_debug_build():
		print("[GameManager] State: %s → %s" % [
			GameState.keys()[old], GameState.keys()[new_state]
		])


func _enter_state(s: GameState) -> void:
	match s:
		GameState.MAIN_MENU:
			get_tree().paused = false
			_auto_save_timer.stop()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		GameState.PLAYING:
			get_tree().paused = false
			_auto_save_timer.start()
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
			SignalBus.game_started.emit()
		
		GameState.PAUSED:
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			SignalBus.game_paused.emit(true)
		
		GameState.LEVEL_TRANSITION:
			get_tree().paused = false
			_auto_save_timer.stop()
		
		GameState.MEMORY_SEQUENCE:
			## Game runs but player input locked via state machine
			pass
		
		GameState.GAME_OVER:
			get_tree().paused = true
			death_count += 1
		
		GameState.CREDITS:
			get_tree().paused = false
			_auto_save_timer.stop()


func _exit_state(s: GameState) -> void:
	match s:
		GameState.PAUSED:
			SignalBus.game_paused.emit(false)
		GameState.LEVEL_TRANSITION:
			_level_timer = 0.0


## ═══════════════════════════════════════════════════════════════════════════════
## LEVEL MANAGEMENT
## ═══════════════════════════════════════════════════════════════════════════════

func load_level(level_id: String) -> void:
	if not level_registry.has(level_id):
		push_error("[GameManager] Unknown level: %s" % level_id)
		return
	
	change_state(GameState.LEVEL_TRANSITION)
	current_level_id = level_id
	_level_timer = 0.0
	
	var scene_path: String = level_registry[level_id]["scene"]
	SignalBus.scene_transition_requested.emit(scene_path, "ink_bleed")
	SignalBus.fade_requested.emit(false, 0.8)
	
	await get_tree().create_timer(0.8).timeout
	get_tree().change_scene_to_file(scene_path)
	
	await get_tree().create_timer(0.4).timeout
	SignalBus.fade_requested.emit(true, 1.2)
	change_state(GameState.PLAYING)


func complete_level(level_id: String) -> void:
	if level_id not in levels_completed:
		levels_completed.append(level_id)
	
	var stats := {
		"time": _level_timer,
		"deaths": death_count,
		"fragments": _count_level_fragments(level_id),
		"completed_at": Time.get_unix_time_from_system()
	}
	
	SignalBus.level_completed.emit(level_id)
	progress_updated.emit(get_completion_percentage())
	
	## Auto-save on level complete
	save_game(0)
	
	## Load next level or credits
	var next := _get_next_level(level_id)
	if next.is_empty():
		change_state(GameState.CREDITS)
	else:
		load_level(next)


func _get_next_level(current_id: String) -> String:
	var current_order: int = level_registry[current_id]["order"]
	for id in level_registry:
		if level_registry[id]["order"] == current_order + 1:
			return id
	return ""


func _count_level_fragments(level_id: String) -> int:
	var count := 0
	for frag_id in memory_fragments:
		if memory_fragments[frag_id].get("level", "") == level_id:
			if memory_fragments[frag_id].get("collected", false):
				count += 1
	return count


## ═══════════════════════════════════════════════════════════════════════════════
## PROGRESSION
## ═══════════════════════════════════════════════════════════════════════════════

func unlock_ability(ability_name: String) -> void:
	if ability_name in shadow_abilities:
		return
	shadow_abilities.append(ability_name)
	SignalBus.shadow_ability_gained.emit(ability_name)
	
	if OS.is_debug_build():
		print("[GameManager] Ability unlocked: %s" % ability_name)


func has_ability(ability_name: String) -> bool:
	return ability_name in shadow_abilities


func collect_memory(fragment_id: String, data: Dictionary = {}) -> void:
	memory_fragments[fragment_id] = {
		"collected": true,
		"level": current_level_id,
		"timestamp": Time.get_unix_time_from_system(),
		"data": data
	}
	
	## Check if this fragment unlocks an ability
	var ability := data.get("unlocks_ability", "") as String
	if not ability.is_empty():
		unlock_ability(ability)
	
	SignalBus.memory_fragment_collected.emit(fragment_id, data.get("unlocks_ability", ""))
	progress_updated.emit(get_completion_percentage())


func get_completion_percentage() -> float:
	var total_fragments := 12  ## Total fragments across all levels
	var collected := 0
	for frag_id in memory_fragments:
		if memory_fragments[frag_id].get("collected", false):
			collected += 1
	
	var level_weight := float(levels_completed.size()) / float(level_registry.size())
	var fragment_weight := float(collected) / float(total_fragments)
	
	return clampf((level_weight * 0.6 + fragment_weight * 0.4) * 100.0, 0.0, 100.0)


## ═══════════════════════════════════════════════════════════════════════════════
## PAUSE / UNPAUSE
## ═══════════════════════════════════════════════════════════════════════════════

func pause_game() -> void:
	if state == GameState.PLAYING:
		change_state(GameState.PAUSED)


func resume_game() -> void:
	if state == GameState.PAUSED:
		change_state(GameState.PLAYING)


func toggle_pause() -> void:
	if state == GameState.PLAYING:
		pause_game()
	elif state == GameState.PAUSED:
		resume_game()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()


## ═══════════════════════════════════════════════════════════════════════════════
## SAVE / LOAD
## ═══════════════════════════════════════════════════════════════════════════════

func _ensure_save_directory() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_game(slot: int = 0) -> bool:
	var data := {
		"version": VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"total_play_time": total_play_time,
		"current_level": current_level_id,
		"difficulty": difficulty,
		"shadow_abilities": shadow_abilities.duplicate(),
		"memory_fragments": memory_fragments.duplicate(true),
		"levels_completed": levels_completed.duplicate(),
		"secrets_found": secrets_found.duplicate(),
		"checkpoints": checkpoints.duplicate(true),
		"death_count": death_count,
		"completion_pct": get_completion_percentage()
	}
	
	var path := SAVE_DIR + SAVE_FILE % slot
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("[GameManager] Failed to save: %s" % path)
		SignalBus.save_completed.emit(false, slot)
		return false
	
	file.store_var(data)
	file.close()
	
	SignalBus.save_completed.emit(true, slot)
	if OS.is_debug_build():
		print("[GameManager] Saved to slot %d (%.1f%% complete)" % [slot, data.completion_pct])
	return true


func load_game(slot: int = 0) -> bool:
	var path := SAVE_DIR + SAVE_FILE % slot
	if not FileAccess.file_exists(path):
		push_warning("[GameManager] No save in slot %d" % slot)
		SignalBus.load_completed.emit(false, slot)
		return false
	
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[GameManager] Failed to read save slot %d" % slot)
		SignalBus.load_completed.emit(false, slot)
		return false
	
	var data: Dictionary = file.get_var()
	file.close()
	
	if not data.has("version"):
		push_error("[GameManager] Corrupt save data in slot %d" % slot)
		SignalBus.load_completed.emit(false, slot)
		return false
	
	## Restore state
	total_play_time = data.get("total_play_time", 0.0)
	current_level_id = data.get("current_level", "")
	difficulty = data.get("difficulty", Difficulty.BALANCED)
	shadow_abilities = data.get("shadow_abilities", ["move"])
	memory_fragments = data.get("memory_fragments", {})
	levels_completed = data.get("levels_completed", [])
	secrets_found = data.get("secrets_found", [])
	checkpoints = data.get("checkpoints", {})
	death_count = data.get("death_count", 0)
	
	SignalBus.load_completed.emit(true, slot)
	
	## Load the saved level
	if not current_level_id.is_empty():
		load_level(current_level_id)
	
	return true


func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists(SAVE_DIR + SAVE_FILE % slot)


func delete_save(slot: int) -> void:
	var path := SAVE_DIR + SAVE_FILE % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


## ═══════════════════════════════════════════════════════════════════════════════
## SETTINGS
## ═══════════════════════════════════════════════════════════════════════════════

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_FILE) != OK:
		is_first_launch = true
		return
	
	is_first_launch = false
	for section in settings:
		for key in settings[section]:
			var val = config.get_value(section, key, settings[section][key])
			settings[section][key] = val


func save_settings() -> void:
	var config := ConfigFile.new()
	for section in settings:
		for key in settings[section]:
			config.set_value(section, key, settings[section][key])
	config.save(SETTINGS_FILE)


func update_setting(section: String, key: String, value: Variant) -> void:
	if settings.has(section) and settings[section].has(key):
		settings[section][key] = value
		_apply_setting(section, key, value)
		save_settings()
		SignalBus.settings_changed.emit("%s/%s" % [section, key], value)


func _apply_settings() -> void:
	for section in settings:
		for key in settings[section]:
			_apply_setting(section, key, settings[section][key])


func _apply_setting(section: String, key: String, value: Variant) -> void:
	match "%s/%s" % [section, key]:
		## Audio
		"audio/master_volume":
			AudioServer.set_bus_volume_db(
				AudioServer.get_bus_index("Master"),
				linear_to_db(value as float)
			)
		"audio/music_volume":
			var idx := AudioServer.get_bus_index("Music")
			if idx >= 0:
				AudioServer.set_bus_volume_db(idx, linear_to_db(value as float))
		"audio/sfx_volume":
			var idx := AudioServer.get_bus_index("SFX")
			if idx >= 0:
				AudioServer.set_bus_volume_db(idx, linear_to_db(value as float))
		"audio/ambient_volume":
			var idx := AudioServer.get_bus_index("Ambient")
			if idx >= 0:
				AudioServer.set_bus_volume_db(idx, linear_to_db(value as float))
		
		## Display
		"display/fullscreen":
			if value:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"display/vsync":
			DisplayServer.window_set_vsync_mode(
				DisplayServer.VSYNC_ENABLED if value else DisplayServer.VSYNC_DISABLED
			)
			Engine.max_fps = 0 if value else target_fps


## ═══════════════════════════════════════════════════════════════════════════════
## DIFFICULTY
## ═══════════════════════════════════════════════════════════════════════════════

func get_difficulty_params() -> Dictionary:
	match difficulty:
		Difficulty.STORY:
			return {
				"light_grace_period": 1.0,
				"dissolve_rate": 0.3,
				"reform_speed": 2.0,
				"checkpoint_frequency": "generous",
				"hint_system": true
			}
		Difficulty.BALANCED:
			return {
				"light_grace_period": 0.5,
				"dissolve_rate": 0.6,
				"reform_speed": 1.0,
				"checkpoint_frequency": "standard",
				"hint_system": false
			}
		Difficulty.SHADOW:
			return {
				"light_grace_period": 0.2,
				"dissolve_rate": 1.0,
				"reform_speed": 0.7,
				"checkpoint_frequency": "sparse",
				"hint_system": false
			}
	return {}


## ═══════════════════════════════════════════════════════════════════════════════
## PERFORMANCE MONITORING
## ═══════════════════════════════════════════════════════════════════════════════

func _track_performance(delta: float) -> void:
	_frame_times.append(delta)
	if _frame_times.size() > PERF_SAMPLE_SIZE:
		_frame_times.remove_at(0)
	
	## Calculate rolling average FPS
	if _frame_times.size() >= 10:
		var sum := 0.0
		for ft in _frame_times:
			sum += ft
		_fps_avg = float(_frame_times.size()) / sum
	
	## Warn on sustained drops
	if _fps_avg < 30.0:
		_perf_warnings += 1
		if _perf_warnings >= 60:  ## 1 second of sub-30
			SignalBus.performance_warning.emit("low_fps", {
				"avg_fps": _fps_avg,
				"duration_frames": _perf_warnings
			})
			_perf_warnings = 0


func get_avg_fps() -> float:
	return _fps_avg


func _setup_debug_overlay() -> void:
	## Creates a lightweight debug label — only in debug builds
	var label := Label.new()
	label.name = "DebugOverlay"
	label.position = Vector2(8, 8)
	label.z_index = 100
	label.add_theme_font_size_override("font_size", 12)
	add_child(label)
	
	var timer := Timer.new()
	timer.wait_time = 0.25
	timer.autostart = true
	timer.timeout.connect(func():
		label.text = "FPS: %.0f | State: %s | Level: %s | Mem: %.1fMB" % [
			_fps_avg,
			GameState.keys()[state],
			current_level_id if not current_level_id.is_empty() else "—",
			OS.get_static_memory_usage() / 1048576.0
		]
	)
	add_child(timer)


## ═══════════════════════════════════════════════════════════════════════════════
## INTERNAL
## ═══════════════════════════════════════════════════════════════════════════════

func _connect_signals() -> void:
	SignalBus.level_completed.connect(func(id): complete_level(id))
	SignalBus.shadow_died.connect(func(): death_count += 1)
	SignalBus.shadow_ability_gained.connect(func(a): unlock_ability(a))
	SignalBus.memory_fragment_collected.connect(func(id, _a): collect_memory(id))
	SignalBus.save_requested.connect(func(slot): save_game(slot))
	SignalBus.load_requested.connect(func(slot): load_game(slot))
	SignalBus.settings_changed.connect(func(k, v):
		var parts := k.split("/")
		if parts.size() == 2:
			update_setting(parts[0], parts[1], v)
	)
	SignalBus.checkpoint_reached.connect(func(cp_id, data):
		checkpoints[current_level_id] = {"id": cp_id, "data": data}
		save_game(0)
	)


func _setup_auto_save() -> void:
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	_auto_save_timer.one_shot = false
	_auto_save_timer.timeout.connect(func(): save_game(0))
	add_child(_auto_save_timer)


func _on_quit() -> void:
	if state == GameState.PLAYING:
		save_game(0)
	save_settings()

