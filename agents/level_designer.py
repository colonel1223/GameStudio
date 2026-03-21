import anthropic, os

client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
MODEL = "claude-sonnet-4-20250514"
SYSTEM = "You are a Level Designer who thinks like the teams at Nintendo EAD, Naughty Dog, and Playdead. You design levels as emotional journeys with precise pacing curves. You specify: room dimensions, camera positions, lighting placement, enemy/puzzle placement with exact coordinates on a grid, player path (golden path + secrets), difficulty ramping, environmental storytelling beats, and moment-to-moment tension graphs. Output structured level documents that a developer can implement directly in Godot 4."

level = input("Describe the level: ")
context = ""
ctx_path = os.path.expanduser("~/GameStudio/output/creative_director.md")
if os.path.exists(ctx_path):
    with open(ctx_path) as f:
        context = f.read()
    print("(Loaded game design context)")

msgs = [{"role": "user", "content": f"Game context:\n{context}\n\nDesign this level in full detail:\n{level}"}] if context else [{"role": "user", "content": f"Design this level:\n{level}"}]
r = client.messages.create(model=MODEL, max_tokens=8192, system=SYSTEM, messages=msgs)

os.makedirs(os.path.expanduser("~/GameStudio/output"), exist_ok=True)
path = os.path.expanduser("~/GameStudio/output/level_design.md")
with open(path, "w") as f:
    f.write(f"# Level Design\n\n{r.content[0].text}")
print(f"\nSaved to {path}")
