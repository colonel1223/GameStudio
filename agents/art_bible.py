import anthropic, os

client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
MODEL = "claude-sonnet-4-20250514"
SYSTEM = "You are an Art Director creating a comprehensive art bible for an indie game. You specify exact hex color codes, typography, spacing rules, lighting setups, material properties, animation curves, and UI layouts. Your output is so detailed that any artist could execute without a single follow-up question."

game = input("Game name/concept: ")
r = client.messages.create(model=MODEL, max_tokens=8192, system=SYSTEM, messages=[{"role": "user", "content": f"Create a complete art bible for: {game}. Include: master palette (10 hex codes with usage), typography system, grid/spacing, lighting rigs for 3 moods, material language, animation timing curves, UI kit specs, and 5 key frame compositions described shot-by-shot."}])

os.makedirs(os.path.expanduser("~/GameStudio/output"), exist_ok=True)
path = os.path.expanduser("~/GameStudio/output/ART_BIBLE.md")
with open(path, "w") as f:
    f.write(f"# Art Bible\n\n{r.content[0].text}")
print(f"\nSaved to {path}")
