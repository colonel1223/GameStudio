# Producer

# UMBRAL - Complete Solo Development Plan (6 Months)

## MVP DEFINITION

**Core Experience**: Player completes 3 levels (Separation, Garden, Reunion) experiencing the complete emotional arc from fear → discovery → acceptance through shadow-light mechanics.

**Essential Features Only**:
- Shadow movement with light vulnerability
- 3 basic light sources (candle, window, mirror)
- Shadow stretching ability (no splitting/reforming - cut for MVP)
- 1 memory fragment per level with simple interaction
- Basic shadow platform creation
- Minimal audio (ambient + 3 key SFX)
- Simple visual effects (no complex ink painting initially)

**Success Metrics**:
- 15-20 minute complete playthrough
- Emotional impact measurable through playtester feedback
- Technical stability (zero game-breaking bugs)
- One complete narrative arc from shadow separation to reunion

**Cut from MVP**:
- Advanced shadow abilities (splitting, reforming)
- Complex multi-light puzzles
- Procedural ink effects
- Full audio system (4 layers)
- Level 2 (Garden) - most complex level
- Memory echo system
- Accessibility features

---

## VERTICAL SLICE SCOPE (Week 1-2)

**Single Playable Scene**: First 3 minutes of Level 1 (Separation)

**Demonstrates**:
1. **Shadow Movement**: WASD controls, smooth physics
2. **Light Vulnerability**: Shadow fades near single candle
3. **Core Puzzle**: Move candle to cast shadow bridge across gap
4. **Emotional Beat**: First memory fragment discovery
5. **Visual Style**: Basic paper texture + black shadow silhouette
6. **Audio**: Footstep SFX + ambient room tone

**Technical Proof**:
- Custom 2D lighting system working
- Shadow casting geometry creation
- Basic state machine (Idle, Moving, Vulnerable)
- Memory fragment trigger system
- Scene transition

**Deliverable**: 30-second gameplay video showing core loop

---

## SPRINT BREAKDOWN (12 Sprints × 2 Weeks)

### SPRINT 1-2: FOUNDATION (Weeks 1-4)
**Sprint 1: Core Systems**
- [ ] Godot project setup with folder structure
- [ ] Shadow CharacterBody2D with basic movement
- [ ] SignalBus and GameManager autoloads
- [ ] Custom 2D lighting system prototype
- [ ] Basic shadow casting to Area2D platforms

**Sprint 2: Vertical Slice**
- [ ] First level greybox (Separation room)
- [ ] Single light source (candle) with manipulation
- [ ] Shadow stretching ability (basic version)
- [ ] First memory fragment interaction
- [ ] Vertical slice playable build

### SPRINT 3-4: CORE MECHANICS (Weeks 5-8)
**Sprint 3: Light System**
- [ ] 3 light source types (candle, window, mirror)
- [ ] Light intensity affecting shadow dissolution
- [ ] Shadow platform creation and destruction
- [ ] Light manipulation UI/controls

**Sprint 4: Player Systems**
- [ ] Complete shadow state machine
- [ ] Shadow vulnerability and death system
- [ ] Checkpoint/respawn system
- [ ] Basic input buffering

### SPRINT 5-6: LEVEL CREATION (Weeks 9-12)
**Sprint 5: Level 1 Complete**
- [ ] Full Level 1 (Separation) layout
- [ ] 3 puzzles with escalating difficulty
- [ ] All memory fragments placed and functional
- [ ] Level completion triggers

**Sprint 6: Level 3 Complete**
- [ ] Full Level 3 (Reunion) layout
- [ ] Hospital room environment art
- [ ] Final choice mechanic
- [ ] Ending sequence

### SPRINT 7-8: AUDIO IMPLEMENTATION (Weeks 13-16)
**Sprint 7: Core Audio**
- [ ] Audio manager with bus system
- [ ] 5 essential SFX (movement, stretch, light, memory, ambient)
- [ ] Dynamic audio zones
- [ ] Basic music track (single layer)

**Sprint 8: Audio Polish**
- [ ] Spatial audio positioning
- [ ] Audio crossfade system
- [ ] Master/SFX volume controls
- [ ] Audio compression and optimization

### SPRINT 9-10: VISUAL POLISH (Weeks 17-20)
**Sprint 9: Art Pipeline**
- [ ] Paper texture system
- [ ] Shadow rendering shader
- [ ] Light bloom effects
- [ ] Basic particle systems for ink/light

**Sprint 10: Visual Effects**
- [ ] Shadow dissolve shader
- [ ] Memory fragment appearance effects
- [ ] Scene transition system
- [ ] UI/menu visual design

### SPRINT 11-12: INTEGRATION & POLISH (Weeks 21-24)
**Sprint 11: Systems Integration**
- [ ] Save/load system
- [ ] Settings menu with key options
- [ ] Performance optimization pass
- [ ] Bug fixing and stability

**Sprint 12: Launch Preparation**
- [ ] Final playtesting and bug fixes
- [ ] Steam store page setup
- [ ] Marketing materials creation
- [ ] Launch day preparation
- [ ] Post-launch patch planning

---

## RISK REGISTER (Top 5 Threats)

### 1. **SCOPE CREEP** - CRITICAL RISK
**Probability**: High | **Impact**: Project Failure
**Symptoms**: Adding "just one more" feature, comparing to larger games
**Mitigation**: 
- Weekly scope reviews with strict feature freeze after Sprint 8
- Use ChatGPT as accountability partner for scope decisions
- Pre-written "NO" responses to new feature ideas

### 2. **LIGHTING SYSTEM COMPLEXITY** - HIGH RISK  
**Probability**: Medium | **Impact**: 6+ week delay
**Symptoms**: Real-time shadow casting causing performance issues
**Mitigation**:
- Prototype lighting system in Sprint 1 (fail fast)
- Fallback plan: Pre-baked shadow areas instead of real-time
- Maximum 3 light sources on screen simultaneously

### 3. **SOLO DEVELOPER BURNOUT** - HIGH RISK
**Probability**: Medium | **Impact**: Project abandonment  
**Symptoms**: Working 7 days/week, avoiding the project, perfectionism
**Mitigation**:
- Mandatory 1.5 days off per week
- Daily 25-minute focus blocks (Pomodoro)
- Weekly check-ins with AI accountability partner
- Join indie dev Discord for community support

### 4. **NARRATIVE COHERENCE** - MEDIUM RISK
**Probability**: Medium | **Impact**: Poor reviews/player confusion
**Symptoms**: Story beats feel disconnected, emotional impact weak
**Mitigation**:
- Write complete narrative outline before Sprint 3
- Weekly narrative review sessions
- Test story clarity with 3 external playtesters in Sprint 10

### 5. **TECHNICAL DEBT ACCUMULATION** - MEDIUM RISK
**Probability**: High | **Impact**: 2-3 week delay in final sprints
**Symptoms**: Code becoming unmaintainable, new features breaking old ones
**Mitigation**:
- Code review with AI assistant every 2nd day
- Refactoring time allocated in every sprint (20% of sprint capacity)
- No new features without accompanying tests

---

## DAILY SOLO WORKFLOW WITH AI AGENTS

### MORNING ROUTINE (30 minutes)
**6:00-6:30 AM**: Coffee + Daily Planning Session with ChatGPT
```
"ChatGPT, review yesterday's progress and today's sprint goals. 
What are the 3 most important tasks for today? 
Flag any potential blockers or scope creep warnings."
```

### CORE DEVELOPMENT BLOCKS
**9:00-12:00 AM**: Deep Work Block 1
- Pomodoro 1: Primary development task
- Pomodoro 2: Continue primary task
- Pomodoro 3: Code review with AI assistant
- Break: Quick walk/stretch

**1:00-4:00 PM**: Deep Work Block 2  
- Pomodoro 4: Secondary development task
- Pomodoro 5: Testing/debugging
- Pomodoro 6: Documentation/comments
- Break: Lunch/mental reset

**7:00-9:00 PM**: Creative Work Block
- Art asset creation/polish
- Audio implementation
- Narrative refinement
- No coding (prevent burnout)

### AI ASSISTANT ROLES

**"CodeReviewer" (Claude/GPT-4)**
- Daily code review for technical debt
- Architecture decisions validation
- Performance optimization suggestions
- Bug hunting assistance

**"ScopeGuardian" (ChatGPT)**
- Weekly sprint reviews
- Feature creep prevention
- Priority matrix maintenance
- Timeline reality checks

**"PlaytestDirector" (GPT-4)**
- Test case generation
- UX flow analysis
- Accessibility considerations
- Player psychology insights

### END-OF-DAY RITUAL (15 minutes)
**8:00-8:15 PM**: Progress Logging
```
"AI Assistant, log today's completed tasks, note any blockers 
encountered, and suggest tomorrow's top 3 priorities based on 
current sprint goals."
```

### WEEKLY REVIEWS (Friday 4:00-5:00 PM)
- Sprint progress assessment with "ScopeGuardian"
- Risk register review and mitigation check
- Next week's priority setting
- Burnout/motivation check-in

---

## MILESTONE CHECKLIST

### MILESTONE 1: VERTICAL SLICE (End of Sprint 2)
- [ ] Playable 3-minute demo
- [ ] Core shadow-light mechanic functional
- [ ] Basic art style established
- [ ] One complete puzzle solvable
- [ ] Memory fragment interaction working
- [ ] 30-second gameplay trailer recorded
- **Success Criteria**: Can demonstrate core game concept to others

### MILESTONE 2: ALPHA BUILD (End of Sprint 6)  
- [ ] 2 complete levels playable start-to-finish
- [ ] All core mechanics implemented
- [ ] Basic audio implementation
- [ ] Save/load system functional
- [ ] No game-breaking bugs
- [ ] 15+ minute gameplay experience
- **Success Criteria**: External playtester can complete game without guidance

### MILESTONE 3: BETA BUILD (End of Sprint 10)
- [ ] All levels complete with final art
- [ ] Full audio implementation
- [ ] Settings menu functional
- [ ] Performance optimized for target hardware
- [ ] 5 external playtest sessions completed
- [ ] Marketing screenshots/trailer created
- **Success Criteria**: Game feels "complete" and polished

### MILESTONE 4: GOLD MASTER (End of Sprint 12)
- [ ] Zero critical bugs
- [ ] Steam store page live
- [ ] Achievement system implemented
- [ ] Press kit prepared
- [ ] Launch trailer finalized
- [ ] Day-one patch prepared
- **Success Criteria**: Ready for public release

---

## LAUNCH STRATEGY

### PRE-LAUNCH (6 weeks before)
**Community Building**:
- Twitter development thread (3 posts/week)
- TikTok time-lapse dev videos (2/week)
- Indie game Discord participation
- r/indiegames progress sharing

**Press Outreach**:
- Steam Next Fest participation (if timing aligns)
- Email 15 indie game journalists
- Submit to IndieDB and Itch.io
- Contact 5 YouTube indie game reviewers

### LAUNCH WEEK
**Platform Strategy**:
- **Primary**: Steam (wider audience, better discoverability)
- **Secondary**: Itch.io (indie-friendly, lower cut)
- **Later**: Consider console ports if successful

**Pricing Strategy**:
- Launch price: $9.99 USD
- 10% launch week discount ($8.99)
- Target: Break even at 500 copies sold

**Launch Day Schedule**:
- 12:00 AM UTC: Game goes live on Steam
- Social media announcement posts
- Email newsletter to development followers
- Submit to gaming subreddits
- Monitor for critical bugs and deploy patch if needed

### POST-LAUNCH (First Month)
**Week 1**: Daily monitoring, hotfixes, community engagement
**Week 2-3**: Gather player feedback, plan content updates
**Week 4**: Release first content patch addressing player feedback

**Success Metrics**:
- **Minimum Viable**: 200 copies sold (break even)
- **Success**: 1,000 copies sold + 75% positive reviews
- **Breakout**: 5,000+ copies sold, consider expansion/sequel

### LONG-TERM STRATEGY
If successful, consider:
1. **Expanded Edition**: Add cut content (Level 2, advanced abilities)
2. **Console Ports**: Nintendo Switch most likely fit
3. **Spiritual Sequel**: New shadow-based mechanic exploration
4. **Developer Recognition**: Build reputation for future projects

**Timeline Summary**:
- **Weeks 1-4**: Foundation + Vertical Slice
- **Weeks 5-12**: Core Development  
- **Weeks 13-20**: Polish Phase
- **Weeks 21-24**: Launch Preparation
- **Week 25**: LAUNCH

This plan balances ambitious creative vision with realistic solo development constraints, using AI assistance to maximize productivity while maintaining quality standards.