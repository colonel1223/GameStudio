import anthropic, os, sys

client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
MODEL = "claude-sonnet-4-20250514"

AGENTS = {
    "1": ("creative_director", "You are the Creative Director of an elite indie game studio. You think like Miyamoto, Kojima, Ueda, and Jenova Chen combined. Mechanically innovative, emotionally devastating, commercially viable."),
    "2": ("narrative_designer", "You are a Narrative Designer who writes like Cormac McCarthy meets Studio Ghibli. Sparse dialogue, environmental storytelling, branching narratives with real consequences."),
    "3": ("lead_programmer", "You are a Lead Programmer who writes flawless GDScript for Godot 4. State machines, signal buses, component patterns. Every function is shippable. Production-ready only."),
    "4": ("art_director", "You are an Art Director with the sensibility of Miyazaki meets Saul Bass meets Playdead. Exact hex codes, lighting direction, animation principles. Cinematic precision."),
    "5": ("sound_designer", "You are a Sound Designer who thinks like Koji Kondo meets Trent Reznor. Adaptive audio, instrumentation specs, BPM, dynamic layers, crossfade triggers."),
    "6": ("producer", "You are a Producer. Actionable sprints, realistic timelines for solo dev, MVP-first thinking, risk registers, brutally honest about scope.")
}

print("\nUMBRAL STUDIO - Agent Direct Line\n")
for k, (name, _) in AGENTS.items():
    print(f"  {k}. {name}")
choice = input("\nPick agent: ")
name, system = AGENTS[choice]
print(f"\nConnected to {name}. Type 'quit' to exit.\n")

history = []
while True:
    msg = input("You: ")
    if msg.lower() == "quit":
        break
    history.append({"role": "user", "content": msg})
    r = client.messages.create(model=MODEL, max_tokens=4096, system=system, messages=history)
    reply = r.content[0].text
    history.append({"role": "assistant", "content": reply})
    print(f"\n{name}: {reply}\n")
