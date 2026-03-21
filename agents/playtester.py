import anthropic, os
client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
MODEL = "claude-sonnet-4-20250514"
SYSTEM = """You are UMBRAL's Virtual Playtester. Given a level description or game mechanic,
you simulate a first-time player experiencing it. You narrate moment-by-moment: what you see,
what you try, where you get confused, what delights you, what frustrates you. You think like
three different player archetypes: the Explorer (wants to find everything), the Achiever (wants
to solve puzzles fast), and the Storyteller (wants emotional payoff). You flag moments where
any archetype would quit, rage, or feel nothing. Be brutally honest."""

scenario = input("Describe the scenario to playtest: ")
ctx_path = os.path.expanduser("~/GameStudio/agents/output/FULL_DESIGN_DOC.md")
context = ""
if os.path.exists(ctx_path):
    with open(ctx_path) as f:
        context = f.read()[:3000]
r = client.messages.create(model=MODEL, max_tokens=4096, system=SYSTEM,
    messages=[{"role": "user", "content": f"Game context:\n{context}\n\nPlaytest scenario:\n{scenario}"}])
print(r.content[0].text)
os.makedirs(os.path.expanduser("~/GameStudio/agents/output"), exist_ok=True)
path = os.path.expanduser("~/GameStudio/agents/output/playtest_report.md")
with open(path, "w") as f:
    f.write(f"# Playtest Report\n\n{r.content[0].text}")
print(f"\nSaved to {path}")
