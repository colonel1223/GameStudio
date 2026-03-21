import anthropic, os

client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
MODEL = "claude-sonnet-4-20250514"
SYSTEM = "You are a Lead Programmer who writes flawless GDScript for Godot 4. Output ONLY the GDScript code. No markdown fencing. No explanation before or after. Include class_name, signals, exports, type hints, and comments for non-obvious logic. Production-ready for Godot 4.3+."

desc = input("Describe the script: ")
fname = input("Filename (e.g. player.gd): ")

r = client.messages.create(model=MODEL, max_tokens=8192, system=SYSTEM, messages=[{"role": "user", "content": desc}])
code = r.content[0].text.replace("```gdscript", "").replace("```", "").strip()

os.makedirs(os.path.expanduser("~/GameStudio/game/src"), exist_ok=True)
path = os.path.expanduser(f"~/GameStudio/game/src/{fname}")
with open(path, "w") as f:
    f.write(code)
print(f"\nWritten to {path} ({len(code.splitlines())} lines)")
