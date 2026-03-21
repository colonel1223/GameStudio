import anthropic, os
client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
MODEL = "claude-sonnet-4-20250514"
SYSTEM = """You are UMBRAL's UX Researcher. You analyze game design decisions through player
psychology, flow state theory, and emotional design. You reference Csikszentmihalyi, Raph Koster,
and Jenova Chen. You identify friction points, predict player confusion, and suggest solutions
that preserve artistic vision while maximizing emotional impact. No HUD means every UX decision
must be environmental."""

question = input("UX question: ")
ctx_path = os.path.expanduser("~/GameStudio/agents/output/creative_director.md")
context = ""
if os.path.exists(ctx_path):
    with open(ctx_path) as f:
        context = f.read()
r = client.messages.create(model=MODEL, max_tokens=4096, system=SYSTEM,
    messages=[{"role": "user", "content": f"Game context:\n{context}\n\nUX Question:\n{question}"}])
print(r.content[0].text)
