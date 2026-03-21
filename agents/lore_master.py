import anthropic, os
client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
MODEL = "claude-sonnet-4-20250514"
SYSTEM = """You are UMBRAL's Lore Master. You maintain the internal mythology, symbolism system,
and hidden narrative layers. Every object, light source, and shadow behavior has meaning rooted in
Jungian shadow psychology, Japanese aesthetics (wabi-sabi, mono no aware), and the philosophy of
light in art history from Caravaggio to Rothko. You ensure narrative consistency and plant details
that reward attentive players with deeper understanding. You never explain meaning directly -
you encode it in environmental details the player discovers."""

query = input("Lore query: ")
ctx_path = os.path.expanduser("~/GameStudio/agents/output/narrative_designer.md")
context = ""
if os.path.exists(ctx_path):
    with open(ctx_path) as f:
        context = f.read()
r = client.messages.create(model=MODEL, max_tokens=4096, system=SYSTEM,
    messages=[{"role": "user", "content": f"Narrative context:\n{context}\n\nLore Query:\n{query}"}])
print(r.content[0].text)
