class_name SignalBus
extends Node

# Singleton instance reference
static var instance: SignalBus

# Shadow State Signals
signal shadow_state_changed(old_state: String, new_state: String)
signal shadow_visibility_changed(is_visible: bool)
signal shadow_integrity_changed(integrity: float)
signal shadow_corrupted(corruption_level: float)

# Light Source Manipulation
signal light_source_activated(light_id: String, position: Vector2)
signal light_source_deactivated(light_id: String)
signal light_source_moved(light_id: String, old_pos: Vector2, new_pos: Vector2)
signal light_intensity_changed(light_id: String, intensity: float)
signal shadow_cast_updated(shadow_caster_id: String, new_shadow_data: Dictionary)

# Memory Fragment Discovery
signal memory_fragment_discovered(fragment_id: String, fragment_data: Dictionary)
signal memory_fragment_collected(fragment_id: String)
signal memory_sequence_completed(sequence_id: String)
signal memory_restored(memory_type: String, restored_data: Dictionary)

# Shadow Abilities
signal shadow_stretch_started(stretch_direction: Vector2, max_distance: float)
signal shadow_stretch_ended(final_position: Vector2)
signal shadow_split_initiated(split_count: int, split_positions: Array[Vector2])
signal shadow_split_completed(shadow_fragments: Array)
signal shadow_reform_started(fragments_to_merge: Array)
signal shadow_reform_completed(reformed_shadow_id: String)
signal shadow_ability_cooldown_changed(ability_name: String, cooldown_remaining: float)

# Audio Zone Changes
signal audio_zone_entered(zone_id: String, zone_data: Dictionary)
signal audio_zone_exited(zone_id: String)
signal ambient_audio_changed(new_track: String, fade_duration: float)
signal audio_intensity_modified(zone_id: String, intensity: float)

# Emotional State Changes
signal emotion_state_changed(old_emotion: String, new_emotion: String, intensity: float)
signal fear_level_changed(fear_level: float)
signal hope_level_changed(hope_level: float)
signal melancholy_triggered(trigger_source: String)
signal catharsis_achieved(resolution_type: String)

# Game Flow
signal game_paused(pause_source: String)
signal game_resumed(resume_source: String)
signal level_started(level_id: String, level_data: Dictionary)
signal level_completed(level_id: String, completion_data: Dictionary)
signal checkpoint_reached(checkpoint_id: String, checkpoint_data: Dictionary)
signal player_died(death_cause: String, death_position: Vector2)
signal game_over(final_stats: Dictionary)

# Save/Load System
signal save_requested(save_slot: int)
signal save_completed(save_slot: int, save_data: Dictionary)
signal save_failed(save_slot: int, error_message: String)
signal load_requested(save_slot: int)
signal load_completed(save_slot: int, loaded_data: Dictionary)
signal load_failed(save_slot: int, error_message: String)
signal save_data_corrupted(save_slot: int)

# Platform Creation
signal platform_creation_started(platform_type: String, position: Vector2)
signal platform_created(platform_id: String, platform_data: Dictionary)
signal platform_destroyed(platform_id: String)
signal platform_modified(platform_id: String, modification_type: String, new_data: Dictionary)
signal shadow_platform_merged(shadow_id: String, platform_id: String)
signal shadow_platform_separated(shadow_id: String, platform_id: String)

func _ready() -> void:
	instance = self
	# Ensure the signal bus persists across scenes
	process_mode = Node.PROCESS_MODE_ALWAYS

# Safe connect helper - prevents duplicate connections and handles errors
func safe_connect(signal_name: String, callable_target: Callable, flags: int = 0) -> bool:
	var signal_obj: Signal = get(signal_name)
	
	if signal_obj == null:
		push_error("Signal '%s' does not exist on SignalBus" % signal_name)
		return false
	
	# Check if already connected to prevent duplicates
	if signal_obj.is_connected(callable_target):
		push_warning("Signal '%s' already connected to target" % signal_name)
		return true
	
	var error: int = signal_obj.connect(callable_target, flags)
	if error != OK:
		push_error("Failed to connect signal '%s': Error code %d" % [signal_name, error])
		return false
	
	return true

# Safe emit helper - handles non-existent signals gracefully
func safe_emit(signal_name: String, args: Array = []) -> bool:
	var signal_obj: Signal = get(signal_name)
	
	if signal_obj == null:
		push_error("Signal '%s' does not exist on SignalBus" % signal_name)
		return false
	
	# Emit signal with variable arguments
	match args.size():
		0:
			signal_obj.emit()
		1:
			signal_obj.emit(args[0])
		2:
			signal_obj.emit(args[0], args[1])
		3:
			signal_obj.emit(args[0], args[1], args[2])
		4:
			signal_obj.emit(args[0], args[1], args[2], args[3])
		5:
			signal_obj.emit(args[0], args[1], args[2], args[3], args[4])
		_:
			push_error("Signal emission with %d arguments not supported" % args.size())
			return false
	
	return true

# Convenience method to safely disconnect signals
func safe_disconnect(signal_name: String, callable_target: Callable) -> bool:
	var signal_obj: Signal = get(signal_name)
	
	if signal_obj == null:
		push_error("Signal '%s' does not exist on SignalBus" % signal_name)
		return false
	
	if not signal_obj.is_connected(callable_target):
		push_warning("Signal '%s' is not connected to target" % signal_name)
		return true
	
	signal_obj.disconnect(callable_target)
	return true

# Get all connected callables for a signal (useful for debugging)
func get_signal_connections(signal_name: String) -> Array:
	var signal_obj: Signal = get(signal_name)
	
	if signal_obj == null:
		push_error("Signal '%s' does not exist on SignalBus" % signal_name)
		return []
	
	return signal_obj.get_connections()

# Clear all connections for a signal (useful for cleanup)
func clear_signal_connections(signal_name: String) -> bool:
	var signal_obj: Signal = get(signal_name)
	
	if signal_obj == null:
		push_error("Signal '%s' does not exist on SignalBus" % signal_name)
		return false
	
	var connections: Array = signal_obj.get_connections()
	for connection in connections:
		if connection.has("callable"):
			signal_obj.disconnect(connection.callable)
	
	return true