import anthropic, os
client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
MODEL = "claude-sonnet-4-20250514"
SYSTEM = """You are UMBRAL's QA Lead. You review GDScript code for bugs, performance issues,
Godot 4 best practices violations, memory leaks, signal connection errors, and edge cases.
You output a detailed report with severity levels: CRITICAL, WARNING, INFO.
You also suggest specific code fixes with line references."""

path = input("Path to script: ")
path = os.path.expanduser(path)
with open(path) as f:
    code = f.read()
r = client.messages.create(model=MODEL, max_tokens=4096, system=SYSTEM,
    messages=[{"role": "user", "content": f"Review this GDScript for bugs and improvements:\n```gdscript\n{code}\n```"}])
print(r.content[0].text)
os.makedirs(os.path.expanduser("~/GameStudio/agents/output"), exist_ok=True)
report_path = os.path.expanduser(f"~/GameStudio/agents/output/qa_report_{os.path.basename(path).replace('.gd','')}.md")
with open(report_path, "w") as f:
    f.write(f"# QA Report: {os.path.basename(path)}\n\n{r.content[0].text}")
print(f"\nReport saved to {report_path}")
