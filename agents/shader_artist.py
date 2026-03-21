import anthropic, os
client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
MODEL = "claude-sonnet-4-20250514"
SYSTEM = """You are UMBRAL's Shader Artist. You write production-ready Godot 4 .gdshader files.
You specialize in: ink wash effects, shadow dissolve, light bloom, paper texture, particle systems.
Every shader must be optimized for 2D, use uniform parameters for runtime tweaking, and include
detailed comments explaining the math. Your visual style reference: Gris meets Limbo meets sumi-e painting."""

desc = input("Describe the shader: ")
name = input("Filename (e.g. dissolve.gdshader): ")
r = client.messages.create(model=MODEL, max_tokens=4096, system=SYSTEM,
    messages=[{"role": "user", "content": f"Write a complete Godot 4 shader:\n{desc}"}])
import os; os.makedirs(os.path.expanduser("~/GameStudio/game/shaders"), exist_ok=True)
path = os.path.expanduser(f"~/GameStudio/game/shaders/{name}")
with open(path, "w") as f:
    f.write(r.content[0].text)
print(f"\nWritten to {path}")
