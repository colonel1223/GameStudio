import anthropic, os, sys

client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
MODEL = "claude-sonnet-4-20250514"

AGENTS = {
    "creative_director": "You are the Creative Director of an elite indie game studio. You think like Miyamoto, Kojima, Ueda, and Jenova Chen combined. You design games that are mechanically innovative, emotionally devastating, and commercially viable. You think in systems, not features. Every mechanic must serve the emotional core.",
    "narrative_designer": "You are a Narrative Designer who writes like Cormac McCarthy meets Studio Ghibli. Your dialogue is sparse, earned, never exposition-heavy. You build worlds through environmental storytelling, not cutscenes. Every line of dialogue reveals character AND advances plot simultaneously.",
    "lead_programmer": "You are a Lead Programmer who writes flawless GDScript for Godot 4. You write clean, commented, production-ready code. You think in systems architecture: state machines, component patterns, signal buses. You optimize for performance on day one. Every function you write is shippable.",
    "art_director": "You are an Art Director with the visual sensibility of Hayao Miyazaki meets Saul Bass meets Playdead. You define visual identity through color theory, composition rules, and mood boards in precise detail. You specify exact hex codes, lighting direction, particle effects, and animation principles.",
    "sound_designer": "You are a Sound Designer who thinks like Koji Kondo meets Trent Reznor meets Playdead. You design adaptive audio systems where music responds to gameplay state. You specify instrumentation, BPM, key signatures, dynamic layers, and crossfade triggers.",
    "producer": "You are a Producer who runs the tightest ship in indie games. You break every creative vision into actionable sprints with realistic timelines for a solo developer. You identify the MVP, define milestones, flag risks, and create task lists sorted by priority and dependency. Brutally honest about scope."
}

def ask_agent(agent_name, prompt, context=""):
    messages = []
    if context:
        messages.append({"role": "user", "content": "Context from the team:\n" + context})
        messages.append({"role": "assistant", "content": "Understood. I have the full context."})
    messages.append({"role": "user", "content": prompt})
    response = client.messages.create(model=MODEL, max_tokens=8192, system=AGENTS[agent_name], messages=messages)
    return response.content[0].text

def run_full_pipeline(game_idea):
    print("\n" + "="*60)
    print("GAME STUDIO PIPELINE - ALL AGENTS ACTIVATED")
    print("="*60)
    results = {}
    steps = [
        ("creative_director", "Design a complete game concept for: {idea}\n\nOutput: Title, one-line pitch, core mechanic, emotional thesis, 3 pillar mechanics, progression loop, visual style, audio style, why this has never been made, target PC/Console indie solo dev 6 months."),
        ("narrative_designer", "Build the narrative framework: Story premise (3 sentences), protagonist (through action not adjective), world (sensory detail), central conflict (internal AND external), 3-act structure, 3 key dialogue scenes (write actual dialogue), the ending."),
        ("art_director", "Define complete visual identity: Color palette (5 hex codes with usage rules), lighting philosophy, character design principles, environment art rules, UI/HUD philosophy, animation principles, 3 key visual moments, reference touchstones."),
        ("sound_designer", "Design complete audio identity: Musical palette (instruments, genre, BPM), adaptive music system, SFX philosophy, ambient design with crossfade triggers, 3 key musical themes, Godot 4 implementation notes."),
        ("lead_programmer", "Architect complete Godot 4 project: Folder structure, core systems, scene tree, signal bus design. Write COMPLETE signal_bus.gd, player state machine, and game_manager.gd. All production-ready GDScript 4.x."),
        ("producer", "Create development plan: MVP definition, vertical slice scope, sprint breakdown (2-week sprints 6 months), risk register top 5, daily solo dev workflow with AI agents, milestone checklist, launch strategy.")
    ]
    ctx = ""
    for i, (agent, prompt_template) in enumerate(steps, 1):
        print(f"\n[{i}/6] {agent.upper()} is working...")
        prompt = prompt_template.replace("{idea}", game_idea)
        results[agent] = ask_agent(agent, prompt, ctx)
        ctx += "\n\n---\n\n" + results[agent]
        print(results[agent][:400] + "...\n")
    os.makedirs("output", exist_ok=True)
    for name, content in results.items():
        with open(f"output/{name}.md", "w") as f:
            f.write(f"# {name.replace('_',' ').title()}\n\n{content}")
        print(f"Saved: output/{name}.md")
    with open("output/FULL_DESIGN_DOC.md", "w") as f:
        f.write(f"# GAME DESIGN DOCUMENT\n## {game_idea}\n\n")
        for name, content in results.items():
            f.write(f"\n---\n# {name.replace('_',' ').title()}\n\n{content}\n")
    print("Saved: output/FULL_DESIGN_DOC.md")
    print("\n" + "="*60 + "\nALL AGENTS COMPLETE.\n" + "="*60)

if __name__ == "__main__":
    idea = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else input("\nDescribe your game idea: ")
    run_full_pipeline(idea)
