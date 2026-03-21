```
 ██    ██ ███    ███ ██████  ██████   █████  ██      
 ██    ██ ████  ████ ██   ██ ██   ██ ██   ██ ██      
 ██    ██ ██ ████ ██ ██████  ██████  ███████ ██      
 ██    ██ ██  ██  ██ ██   ██ ██   ██ ██   ██ ██      
  ██████  ██      ██ ██████  ██   ██ ██   ██ ███████ 
```

### AI-Powered Solo Game Studio

> One developer. Ten AI agents. A game about a shadow learning to dance with light.

**[Live Dashboard](https://colonel1223.github.io/GameStudio/)** · **[Design Document](agents/output/FULL_DESIGN_DOC.md)** · **[Game Scripts](game/src/)**

---

## What is this?

UMBRAL is an indie game built by a single developer using 10 AI agents as a virtual studio team. Each agent specializes in a different discipline — from narrative design to shader programming to QA testing. The game is a puzzle/narrative experience about a shadow separated from its child, navigating a world of light and memory rendered in sumi-e ink painting style.

This repository is the entire studio: the agents, the game code, the design documents, and the live dashboard.

## The Agent Roster

| # | Agent | Role | Status |
|---|-------|------|--------|
| 1 | `creative_director` | Game concept, mechanics, vision | ✅ Online |
| 2 | `narrative_designer` | Story, dialogue, 3-act structure | ✅ Online |
| 3 | `art_director` | Visual identity, color palette, shaders | ✅ Online |
| 4 | `sound_designer` | Adaptive 4-layer audio system | ✅ Online |
| 5 | `lead_programmer` | Godot 4 architecture, GDScript | ⚡ Active |
| 6 | `producer` | Sprint planning, risk management | ✅ Online |
| 7 | `shader_artist` | GPU shaders, VFX, particles | ✅ Online |
| 8 | `qa_tester` | Bug detection, code review | ✅ Online |
| 9 | `ux_researcher` | Player psychology, flow state | ✅ Online |
| 10 | `playtester` | Virtual playtesting, feedback | ✅ Online |

## Tech Stack

- **Engine:** Godot 4.6.1
- **AI:** Claude Sonnet 4 (Anthropic API)
- **3D:** Blender 4.5.8
- **Language:** GDScript + Python 3.13
- **Art Style:** Sumi-e ink painting (procedural shaders)
- **Audio:** Adaptive 4-layer system (shakuhachi, cello, prepared piano)

## Project Structure
```
GameStudio/
├── agents/           # 10 AI agent scripts
│   ├── studio.py     # Full 6-agent pipeline
│   ├── codegen.py    # GDScript generator
│   ├── qa_tester.py  # Automated code review
│   └── output/       # Generated design documents
├── game/             # Godot 4 project
│   ├── project.godot
│   ├── src/          # GDScript source files
│   └── scenes/       # Game scenes (.tscn)
└── docs/             # Live dashboard (GitHub Pages)
```

## Current Sprint

**Sprint 1: Foundation** — Week 1 of 25

- [x] Project setup + Git
- [x] SignalBus autoload (165 lines, 38 signals)
- [x] Shadow player controller (335 lines, state machine)
- [ ] Custom 2D lighting prototype
- [ ] Shadow casting to Area2D platforms
- [ ] GameManager autoload

## The Mission

The gaming industry optimized for extraction. UMBRAL is built on the belief that one person with AI tools can ship a game with more artistic integrity than a 200-person team spending $50M on loot box psychology. No microtransactions. No battle pass. No artificial grind. Just a shadow, light, and a story worth telling.

## License

MIT — Build on this. Fork it. Make your own AI studio.

---

*Built by Spencer Cottrell · San Jose, CA · 2026*
