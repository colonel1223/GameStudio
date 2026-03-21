# Sound Designer

# UMBRAL - Complete Audio Identity System

## Musical Palette

**Core Instrumentation (Minimal Orchestration)**
- **Shakuhachi Flute** - Primary melodic voice, represents the shadow's longing
- **Prepared Piano** - Percussive textures, light sources, memory fragments
- **Bowed Cello (Sul Ponticello)** - Tension, fear, shadow stretching
- **Glass Harmonica** - Light interaction, magical moments
- **Field Recordings** - Paper rustling, ink drops, brush strokes

**Genre Fusion**: Ambient Minimalism meets Japanese Traditional meets Industrial Texture
- **Base BPM**: 60 (heartbeat tempo, allows for half-time at 30 for contemplative moments)
- **Key Centers**: D Minor (melancholy), A Major (hope), F# Diminished (tension)
- **Harmonic Approach**: Pentatonic scales, sus chords, avoid perfect resolution

## Adaptive Music System Architecture

**Four-Layer Dynamic Scoring**

**Layer 1: Foundational Drone (Always Present)**
- Bowed cello sustained tones
- Responds to shadow's emotional state: D minor = fear, A major = curiosity, F# dim = danger
- Volume: -18dB baseline, crossfades over 2-second intervals
- Triggered by: Shadow proximity to light sources

**Layer 2: Rhythmic Pulse (Context Dependent)**
- Prepared piano drops and rustling sounds
- BPM scales with puzzle complexity: 30 BPM (exploration) → 60 BPM (active puzzle) → 90 BPM (danger)
- Volume: -24dB to -12dB based on player agency
- Triggered by: Light manipulation actions, shadow movement speed

**Layer 3: Melodic Voice (Emotional Beats)**
- Shakuhachi phrases, 4-8 note motifs
- Only plays during memory discoveries and reunification moments
- Volume: -6dB (prominent but not overwhelming)
- Triggered by: Narrative progression states, memory fragment interactions

**Layer 4: Textural Enhancement (Environmental)**
- Glass harmonica, field recordings, processed paper sounds
- Responds to visual elements: more texture = more complex environment
- Volume: -30dB to -18dB, subtle atmospheric layer
- Triggered by: Environmental complexity, visual particle density

## SFX Philosophy: "Haptic Poetry"

**Sound Categories**

**Shadow Movement**
- **Soft Paper Brush** - Normal shadow movement on paper surfaces
- **Rough Charcoal** - Shadow movement on stone/hard surfaces  
- **Ink Drop** - Shadow landing after stretching/jumping
- **Paper Tear** - Shadow splitting or being damaged by light
- **Brush Loading** - Shadow reformation after dispersal

**Light Interactions**
- **Match Strike** - Light source activation
- **Candle Flutter** - Dynamic light source movement
- **Glass Resonance** - Mirror/prism manipulation
- **Electrical Hum** - Harsh artificial light (hospital scenes)
- **Paper Singe** - Shadow touching light (damage feedback)

**Memory Fragments**
- **Watercolor Bloom** - Memory fragment appearing
- **Ink Settle** - Memory fragment solidifying
- **Page Turn** - Transitioning between memory states
- **Whispered Breath** - Emotional revelation moments

## Ambient Design & Crossfade System

**Environmental Audio Zones**

**Zone 1: The White Room (Opening)**
- Base: Subtle room tone (-36dB), paper texture rustling
- Dynamic: Heartbeat at 60 BPM (barely audible, -42dB)
- Crossfade Trigger: Shadow movement activates paper brush sounds
- Musical Layer: Foundational drone in D minor

**Zone 2: Memory Garden (Mid-game)**
- Base: Wind through paper leaves, distant water droplets
- Dynamic: Multiple light sources create polyrhythmic pulse patterns
- Crossfade Trigger: Proximity to memory fragments adds harmonica layer
- Musical Layer: Rhythmic pulse increases, melodic voice emerges

**Zone 3: Hospital Corridor (Late game)**
- Base: Fluorescent electrical hum, distant medical equipment
- Dynamic: Harsh lighting creates dissonant harmonic intervals
- Crossfade Trigger: Shadow vulnerability adds cello tension
- Musical Layer: All layers active, building toward climax

**Zone 4: Reunion Chamber (Finale)**
- Base: Gentle natural light ambience, soft breathing
- Dynamic: Light becomes musical - each beam plays harmonica notes
- Crossfade Trigger: Final choice moment strips all sound except heartbeat
- Musical Layer: Solo shakuhachi melody over silence

## Three Key Musical Themes

### Theme 1: "Separation" (Opening/Trauma)
**Instrumentation**: Solo cello sul ponticello, prepared piano drops
**Key**: D minor, emphasis on tritone intervals
**BPM**: 30 (half-time, dragging, reluctant)
**Melodic Shape**: Descending minor thirds, unresolved phrases
**Implementation**: 
```gdscript
# Godot AudioStreamPlayer2D
separation_theme = preload("res://audio/themes/separation.ogg")
cello_layer = $SeparationTheme/CelloLayer
piano_layer = $SeparationTheme/PianoLayer

func play_separation_theme():
    cello_layer.volume_db = -18
    piano_layer.volume_db = -24
    cello_layer.play()
    # Piano drops triggered by player movement
```

### Theme 2: "Journey" (Exploration/Growth)
**Instrumentation**: Shakuhachi lead, glass harmonica accompaniment, paper rustling rhythm
**Key**: Modal interchange between D minor and F major
**BPM**: 60, can shift to 90 during active puzzle solving
**Melodic Shape**: Rising pentatonic phrases, call-and-response structure
**Dynamic Behavior**: Builds complexity as shadow learns new abilities
**Implementation**:
```gdscript
# Adaptive layering system
journey_theme = {
    "base": preload("res://audio/themes/journey_base.ogg"),
    "harmony": preload("res://audio/themes/journey_harmony.ogg"),
    "rhythm": preload("res://audio/themes/journey_rhythm.ogg")
}

func update_journey_complexity(shadow_abilities_count):
    var complexity = clamp(shadow_abilities_count / 3.0, 0.0, 1.0)
    harmony_layer.volume_db = lerp(-60, -12, complexity)
    rhythm_layer.pitch_scale = lerp(0.8, 1.2, complexity)
```

### Theme 3: "Reunification" (Climax/Resolution)
**Instrumentation**: Full ensemble - shakuhachi melody, cello harmony, prepared piano, glass harmonica
**Key**: A major with suspended fourths resolving to major thirds
**BPM**: 45 (slower, more deliberate, ceremonial)
**Melodic Shape**: Ascending spiral pattern, finally resolving home
**Emotional Arc**: Starts tentative, builds to triumphant but gentle
**Implementation**:
```gdscript
# Triggered by final choice moment
reunification_theme = preload("res://audio/themes/reunification.ogg")

func trigger_reunification():
    # Fade out all other audio first
    fade_all_audio(2.0)
    await get_tree().create_timer(2.0).timeout
    
    # Play final theme with careful volume control
    reunification_player.volume_db = -6
    reunification_player.play()
    
    # Dynamic crescendo based on player choice commitment
    var tween = create_tween()
    tween.tween_method(update_theme_intensity, 0.0, 1.0, 8.0)
```

## Godot 4 Implementation Architecture

### Audio Bus Structure
```
Master Bus (0dB)
├── Music Bus (-6dB)
│   ├── Drone Layer Bus (-18dB)
│   ├── Rhythm Layer Bus (-24dB) 
│   ├── Melody Layer Bus (-6dB)
│   └── Texture Layer Bus (-30dB)
├── SFX Bus (-12dB)
│   ├── Shadow SFX Bus (-18dB)
│   ├── Light SFX Bus (-12dB)
│   └── Memory SFX Bus (-6dB)
└── Ambient Bus (-18dB)
    ├── Environmental Bus (-24dB)
    └── Room Tone Bus (-36dB)
```

### Core Audio Manager Script
```gdscript
extends AudioManager
class_name UmbralAudioManager

@export var fade_duration: float = 2.0
@export var crossfade_curve: Curve

var current_zone: String = ""
var shadow_emotional_state: String = "neutral"
var music_layers: Dictionary = {}
var ambient_players: Dictionary = {}

signal audio_zone_changed(zone_name: String)
signal emotional_state_changed(state: String)

func _ready():
    initialize_audio_layers()
    connect_shadow_events()
    setup_zone_triggers()

func initialize_audio_layers():
    # Create AudioStreamPlayer2D nodes for each layer
    for layer in ["drone", "rhythm", "melody", "texture"]:
        var player = AudioStreamPlayer2D.new()
        player.bus = "Music/" + layer.capitalize() + " Layer"
        add_child(player)
        music_layers[layer] = player

func update_emotional_state(new_state: String):
    if shadow_emotional_state == new_state:
        return
    
    var old_state = shadow_emotional_state
    shadow_emotional_state = new_state
    
    # Crossfade drone layer to new emotional key
    crossfade_drone_layer(old_state, new_state)
    emotional_state_changed.emit(new_state)

func crossfade_drone_layer(from_state: String, to_state: String):
    var from_stream = get_drone_stream(from_state)
    var to_stream = get_drone_stream(to_state)
    
    var tween = create_tween()
    tween.parallel().tween_method(
        fade_stream_volume, 
        music_layers["drone"], 
        0.0, 
        fade_duration
    )
    
    await tween.finished
    
    music_layers["drone"].stream = to_stream
    music_layers["drone"].play()
    
    tween = create_tween()
    tween.tween_method(
        fade_stream_volume,
        music_layers["drone"],
        1.0,
        fade_duration
    )

func trigger_memory_fragment():
    # Play memory discovery sound
    play_sfx("memory_bloom")
    
    # Temporarily bring melody layer up
    var melody_tween = create_tween()
    melody_tween.tween_property(
        music_layers["melody"],
        "volume_db",
        -6.0,
        1.0
    )
    
    # Play shakuhachi phrase
    music_layers["melody"].play()
```

### Shadow Movement Audio Sync
```gdscript
extends CharacterBody2D
class_name Shadow

@onready var movement_audio: AudioStreamPlayer2D = $MovementAudio
@onready var audio_manager: UmbralAudioManager = get_node("/root/AudioManager")

var last_surface_type: String = "paper"
var movement_speed: float = 0.0

func _physics_process(delta):
    movement_speed = velocity.length()
    update_movement_audio()

func update_movement_audio():
    var surface_type = detect_surface_type()
    
    if surface_type != last_surface_type:
        crossfade_surface_audio(last_surface_type, surface_type)
        last_surface_type = surface_type
    
    # Adjust volume based on movement speed
    var volume_multiplier = clamp(movement_speed / max_speed, 0.0, 1.0)
    movement_audio.volume_db = lerp(-60.0, -18.0, volume_multiplier)
    
    # Adjust pitch slightly for texture
    movement_audio.pitch_scale = lerp(0.9, 1.1, volume_multiplier)

func on_light_contact():
    audio_manager.play_sfx("paper_singe")
    audio_manager.update_emotional_state("pain")
    
    # Brief silence moment for impact
    audio_manager.pause_music_layers(0.5)
```

### Adaptive Music Trigger System
```gdscript
extends Area2D
class_name AudioZone

@export var zone_name: String
@export var ambient_stream: AudioStream
@export var music_intensity: float = 0.5
@export var emotional_state: String = "neutral"

func _on_body_entered(body):
    if body is Shadow:
        var audio_manager = get_node("/root/AudioManager")
        audio_manager.enter_audio_zone(zone_name, ambient_stream, music_intensity)
        audio_manager.update_emotional_state(emotional_state)

func _on_body_exited(body):
    if body is Shadow:
        var audio_manager = get_node("/root/AudioManager")
        audio_manager.exit_audio_zone(zone_name)
```

This audio system creates an intimate, responsive soundscape that breathes with the shadow's emotional journey while maintaining technical feasibility for solo development in Godot 4.