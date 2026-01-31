# Co-Intelligence Guide

A framework for human-AI collaboration that measures growth, not compliance.

## Why We Measure

This isn't surveillance. It's not blame. It's not catching anyone doing something wrong.

**We measure to learn.**

When you track your Claude Code usage, you're developing a feedback loop for growth. Like an athlete watching game film or a musician recording practice sessions, observability gives you data to improve your craft.

The goal: **become a better engineer who happens to use AI, not an AI operator who used to be an engineer.**

## The Philosophy

Claude is not a replacement for your mind. It's an extension of it.

Think of pair programming with an infinitely patient partner who:
- Never gets tired of explaining
- Remembers every pattern they've ever seen
- Types faster than humanly possible
- Has no ego about suggestions being rejected

But this partner also:
- Can't see what you see
- Doesn't know your codebase's history
- Doesn't understand your team's unwritten rules
- Has no intuition about what "feels right"

**You bring judgment. Claude brings speed. Together, you're unstoppable.**

---

## Part 1: Understanding Your Metrics

### Accept Rate (Critical Thinking)

| Rate | What It Means | What To Do |
|------|---------------|------------|
| <60% | Claude doesn't understand your context | Improve CLAUDE.md, add examples |
| 60-75% | Healthy tension | You're engaged, suggestions need work |
| **75-85%** | **Optimal** | Good prompts, active review |
| 85-95% | Getting passive | Review more critically |
| >95% | Rubber stamping | You've stopped thinking |

**The insight:** If your rate changes, ask why. Did you start a new project? Change domains? Get tired? The metric is a mirror, not a judge.

### Cache Ratio (Communication Quality)

| Ratio | Meaning | Action |
|-------|---------|--------|
| <5:1 | Poor context reuse | Improve CLAUDE.md significantly |
| 5-10:1 | Below average | Add more patterns and examples |
| 10-20:1 | Good | Keep refining |
| **>20:1** | **Excellent** | Your documentation is working |

High cache ratio = Claude understands your context = you're communicating effectively.

### Session Size (Efficiency)

| Tokens/Session | Meaning | Action |
|----------------|---------|--------|
| <100k | Efficient | Good prompts, clear instructions |
| 100-200k | Getting long | Consider clearer initial prompts |
| 200-300k | Compaction likely | Improve CLAUDE.md, use skills |
| >300k | Inefficient | Major prompt/config issues |

**Why compaction is bad:**
1. Loss of context (important details summarized away)
2. Wasted tokens rebuilding context
3. Higher cost for same output

### Cost Efficiency

| Metric | Target | Why |
|--------|--------|-----|
| Cost/PR | <$5 | Value delivered per dollar |
| Cost/Commit | <$1 | Granular productivity |
| Cost/Session | <$0.10 | Session efficiency |
| Tokens/Line | <100 | Code output efficiency |

---

## Part 2: Optimizing Your Setup

### What to Put in CLAUDE.md

**DO Include (Improves Suggestions):**

```markdown
## Code Style
- Use early returns
- Prefer composition over inheritance
- Max function length: 30 lines

## Patterns We Use
- Repository pattern for data access
- Factory pattern for object creation
- Example: [link to good code]

## Anti-Patterns to Avoid
- No god objects
- No magic strings
- No nested callbacks >2 levels

## Domain Context
- We're building a fintech app
- Compliance is critical
- All money in cents, not floats
```

**DON'T Include (Wastes Tokens):**

```markdown
## Generic Advice
- Write clean code (too vague)
- Follow best practices (which ones?)
- Be careful (not actionable)
```

### A/B Testing Your Config

Version your configurations to measure impact:

```bash
# In your shell profile
export OTEL_RESOURCE_ATTRIBUTES="config_version=v1,..."
```

Update when you change CLAUDE.md:
```bash
export OTEL_RESOURCE_ATTRIBUTES="config_version=v2,..."
```

**What to version:**

| Config | Location | What to Track |
|--------|----------|---------------|
| CLAUDE.md | Project root | Coding style, patterns, rules |
| Memory files | `~/.claude/memory/` | Persistent context |
| Skills | `~/.claude/skills/` | Custom commands |
| Settings | `~/.claude/settings.json` | Permissions, defaults |

### Optimization Experiments

**Experiment 1: CLAUDE.md Specificity**

| Version | Style | Expected Result |
|---------|-------|-----------------|
| v1 | Generic | Low accept rate |
| v2 | Project-specific patterns | Higher accept rate |
| v3 | Examples + anti-patterns | Optimal (75-85%) |

**Experiment 2: Memory File Impact**

| Version | Setup | Measure |
|---------|-------|---------|
| v1 | No memory files | Baseline cache ratio |
| v2 | Key decisions documented | Improved cache ratio |
| v3 | Full context + examples | Maximum efficiency |

---

## Part 3: Anti-Patterns and Fixes

### The Rubber Stamper (>95% Accept)

**What's happening:** Accepting everything without reading.

**Why:** Trust built up, time pressure, fatigue.

**The cost:** You stop learning. Skills atrophy. When Claude is wrong, you won't catch it.

**The fix:** Not suspicion - curiosity. Read the diffs. Ask: "Would I have written it this way?"

### The Micromanager (<60% Accept)

**What's happening:** Rejecting most suggestions.

**Why:** Claude doesn't understand your context.

**The cost:** You're not getting the speed benefit.

**The fix:** Invest in context. Write better CLAUDE.md. Add examples. Give Claude a chance.

### The Context Burner (>300k tokens)

**What's happening:** Sessions running until they hit limits.

**Why:** Deep work, or going in circles.

**The cost:** Context compacted. Quality degrades.

**The fix:** Recognize when fresh sessions help. Use `/compact`. Break tasks into phases.

### The Expensive Developer (>$10/PR)

**What's happening:** Too many iterations or unclear prompts.

**Why:** Vague initial requests, too much back-and-forth.

**The fix:**
1. Be specific in initial prompts
2. Include expected output format
3. Break complex tasks into steps
4. Add task templates to skills

---

## Part 4: The Growth Mindset

### Questions to Ask Yourself

Instead of "Am I using AI correctly?" ask:

1. **Am I learning?**
   - Do I understand the code Claude wrote?
   - Could I write it myself?
   - Am I picking up new patterns?

2. **Am I curious?**
   - Do I ask Claude to explain its reasoning?
   - Do I experiment with approaches?
   - Do I read the diffs carefully?

3. **Am I improving?**
   - Is my prompting more effective?
   - Am I delivering value faster?
   - Are my code reviews meaningful?

4. **Am I in control?**
   - Do I decide the architecture?
   - Do I set the constraints?
   - Do I make the judgment calls?

### The Commitment

1. **Stay curious** - Ask why, not just whether it works
2. **Stay critical** - Read diffs, push back when needed
3. **Stay learning** - Absorb good patterns from Claude
4. **Stay in charge** - You decide architecture and direction
5. **Stay humble** - Sometimes Claude's way is better

### What Good Looks Like

After a week of healthy usage:

```
Accept Rate:     75-85%     # Critical but trusting
Cache Ratio:     >20:1      # Good context reuse
Tokens/Session:  <100k      # Efficient sessions
Cost/PR:         <$5        # Good ROI
```

This indicates:
- **Engaged review** - not rubber-stamping
- **Clear communication** - Claude understands context
- **Efficient sessions** - not going in circles
- **Value delivery** - producing meaningful output

---

## Part 5: Troubleshooting

### "Claude keeps getting it wrong"

**Check:** CLAUDE.md - comprehensive? patterns? anti-patterns? domain context?

**Try:** More context upfront. Include examples of what you want.

### "I'm spending too much"

**Check:** Cost/PR metric.

**Try:** Haiku for simple tasks. Fresh sessions. Specific initial prompts.

### "I feel like I'm not learning"

**Check:** Accept rate creeping toward 100%?

**Try:** Deliberately slow down. Read every diff. Form your opinion first.

### "Sessions feel inefficient"

**Check:** Tokens/session. Cache ratio.

**Try:** Better upfront context. Clearer problem statements. Know when to start fresh.

---

## The Meta-Goal

```
You + Claude = Better than either alone

Not: Claude doing your job
Not: You doing Claude's job
But: True collaboration where both contribute strengths
```

**The metrics are mirrors, not judges.**

When you see something in the data, don't ask "Is this good or bad?" Ask:
- What does this tell me about how I work?
- What would I like to be different?
- What can I try to change it?

---

*"The best engineers don't just use AI - they collaborate with it. They bring judgment, context, and vision. AI brings speed, breadth, and tireless patience. Together, they create things neither could alone."*
