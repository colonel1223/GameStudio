extends Node

signal shadow_died
signal shadow_light_contact(intensity: float)
signal memory_discovered(id: String)
signal level_completed(name: String)

func _ready() -> void:
	print("[UMBRAL] Signal bus online")
