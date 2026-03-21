# Art Director

# UMBRAL - Visual Identity System

## Color Palette

**#FFFEF7** (Washi White) - Base paper texture, untouched potential
*Usage: World foundation, UI backgrounds, areas unexplored by shadow*

**#0A0A0A** (Sumi Black) - Pure shadow essence, truth revealed
*Usage: Player shadow, memory fragments, interactive shadow geometry*

**#8B4513** (Burnt Umber) - Warm light sources, comfort memories  
*Usage: Lanterns, candles, golden hour moments, positive emotional beats*

**#2F4F4F** (Slate Gray) - Architectural bones, reality anchors
*Usage: Stone walls, hospital equipment, structural elements that exist independent of light/shadow*

**#DC143C** (Vermillion) - Danger light, medical necessity, harsh truth
*Usage: Surgical lights, warning states, moments of painful revelation*

## Lighting Philosophy

**Chiaroscuro Emotionalism**: Light = Vulnerability/Growth, Shadow = Safety/Stagnation
- Light sources breathe with 0.8-second pulses, expanding/contracting 15% intensity
- Hard shadows create platforming geometry; soft shadows indicate narrative space
- Key light always 45° above horizon, mimics natural comfort zones
- Fill light prohibited—embrace pure blacks and paper whites
- Color temperature shifts with emotional state: warm (2700K) for comfort, cool (5500K) for fear, clinical (6500K) for truth

## Character Design Principles

**The Shadow (Player)**
- Pure black silhouette with hand-painted brush texture that shifts based on movement speed
- Edges shimmer when near light (dissolving effect via particle displacement)
- Form language: Organic curves when confident, angular fragments when afraid
- Scale variance: Stretches 300% when reaching, compresses to 60% when hiding
- No facial features—emotion conveyed through posture and edge quality

**Memory Echoes (Child)**
- Translucent white-on-white, visible only through shadow interaction
- Sumi-e brush economy—three strokes maximum per figure
- Drawn with traditional calligraphy pressure variance (thick-to-thin natural tapering)
- Appears solid in shadow, ghostly in light
- Ages backward through memories—youngest = most defined, oldest = most abstract

## Environment Art Rules

**Architectural Hierarchy**
1. **Paper Foundation**: Pure white (#FFFEF7) base layer, visible paper grain texture at 40% opacity
2. **Ink Staining**: Areas touched by shadow leave permanent light gray (#F5F5F5) stains
3. **Light Bloom**: All light sources use watercolor diffusion shader with 80-pixel soft falloff
4. **Shadow Geometry**: Cast shadows render as pure vector shapes with slight brush texture overlay

**Spatial Composition**
- Golden ratio placement for all light sources (1.618:1 positioning)
- Negative space minimum 35% of screen real estate
- Depth through shadow layering only—no perspective tricks
- Environmental storytelling through object arrangement in light cones

## UI/HUD Philosophy

**Invisible Interface**
- Zero persistent UI elements
- Game state communicated through shadow behavior and environmental response
- Interactive elements pulse with subtle ink-drop expansion (2-second cycle)
- Scene transitions via ink bleeding from edges (0.8-second wipe)
- No health bars—shadow degradation shown through edge dissolution
- Settings/pause accessed through specific shadow gesture (curl into spiral)

## Animation Principles

**Brush Physics**
- All movement follows sumi-e brush dynamics: fast attack, slow decay
- Shadow responds to surface texture—smooth on paper, ragged on stone
- 12fps base animation for organic feel, 24fps only for light interactions
- Squash/stretch limited to 140% maximum—preserve shadow's essential form
- Anticipation frames mandatory before major shadow transformations

**Light Interaction**
- Shadow edge dissolves over 8 frames when entering light
- Reformation follows ink-drop surface tension (circular to natural form)
- Light source manipulation uses ease-in-cubic for weight, ease-out-bounce for magic
- Memory fragments fade in using alpha compositing, fade out using edge erosion

## Three Key Visual Moments

**1. The First Stretch (Tutorial)**
- Wide shot: White paper room, single candle (burnt umber), small shadow
- Shadow reaches toward candle, trembling
- As it stretches, brush strokes become visible in the elongated form
- Moment of contact: shadow edge sizzles with ink-drop particles
- Pullback: Shadow recoils, leaving faint gray stain on paper floor
- **Emotional Beat**: Fear of growth, first understanding of vulnerability

**2. The Memory Garden (Mid-game)**
- Establishing shot: Overgrown paper garden, multiple light sources creating complex shadow maze
- Shadow splits into three parts, each navigating different paths
- Central moment: All three pieces reach memory fragment simultaneously
- Ghost-child materializes in center, solid white against dark shadows
- Prism light effect: Single vermillion beam splits into warm spectrum
- Shadow pieces reform as one, now larger and more confident
- **Emotional Beat**: Understanding that division can lead to wholeness

**3. The Final Choice (Climax)**
- Hospital room at golden hour, all five colors present
- Shadow wavers at threshold between darkness and filtered sunlight
- Child's hand reaches toward window (backlit, slightly overexposed)
- Critical moment: Shadow begins to dissolve in light but doesn't retreat
- Instead of dissolution, shadow becomes translucent—still present but transformed
- Final frame: Shadow and child's hand together in sunbeam, casting new shape on wall
- **Emotional Beat**: True connection requires showing up, even when it hurts

## Reference Touchstones

**Visual Style**: Gris (Nomada Studio) meets Limbo (Playdead) meets traditional Japanese ink wash paintings by Sesshū
**Animation Feel**: Journey (Thatgamecompany) cloth physics meets Studio Ghibli's use of negative space
**Lighting Approach**: Inside (Playdead) dramatic chiaroscuro meets Edward Hopper's window light studies
**UI Philosophy**: Monument Valley (ustwo) invisible interface meets traditional scroll presentation

**Core Visual Metaphor**: Each frame should feel like a single brush stroke in a larger poem—purposeful, minimal, emotionally resonant.