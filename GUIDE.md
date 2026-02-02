# The Architect's Guide to AI Collaboration

A framework for human-AI co-intelligence. We measure **communication quality**, not productivity.

---

## The Core Idea

You are the **Architect**. Claude is your **implementation partner**.

| You Own | Claude Helps With |
|---------|-------------------|
| System design & architecture | Writing code within your constraints |
| Security principles & threat modeling | Implementing patterns you've defined |
| Non-functional requirements | Exploring options for you to evaluate |
| Technology & SDK selection | Generating tests you've designed |
| Code review & quality gates | Refactoring with your rules |
| DRY, SOLID, patterns - the "why" | Explaining tradeoffs so you can decide |

**The metric we care about:** How well does Claude understand your intent?

---

## Three Metrics That Matter

All three measure **communication quality**, not output volume.

### 1. Cache Ratio

```
Cache Ratio = Cache Reads / Cache Creates
```

| Ratio | Meaning | Action |
|-------|---------|--------|
| <5:1 | Claude rebuilds context constantly | Improve your CLAUDE.md |
| 5-10:1 | Some context reuse | Add more patterns and examples |
| 10-20:1 | Good | Keep refining |
| >20:1 | Excellent | Claude understands your world |

A high cache ratio means Claude remembers your patterns. You're not repeating yourself.

**To improve:** Document your architecture decisions, security requirements, and coding patterns in CLAUDE.md with concrete examples.

### 2. Session Size

```
Tokens per Session = Total Tokens / Session Count
```

| Size | Meaning | Action |
|------|---------|--------|
| <100k | Efficient | Good prompts, clear direction |
| 100-200k | Getting long | Consider breaking into phases |
| 200-300k | Compaction risk | Start fresh more often |
| >300k | Inefficient | Likely going in circles |

Long sessions mean either deep complex work (fine) or unclear direction (problem). When sessions get too long, context compaction loses important details.

**To improve:** Start sessions with clear goals. Use `/compact` when context gets stale. Break large tasks into phases.

### 3. Accept Rate

```
Accept Rate = Accepted Edits / Total Edits
```

| Rate | Meaning | Action |
|------|---------|--------|
| <60% | Claude misunderstands you | Improve CLAUDE.md, clearer prompts |
| 60-75% | Healthy tension | You're reviewing carefully |
| 75-85% | Optimal | Good communication, engaged review |
| 85-95% | Getting passive | Slow down, read more carefully |
| >95% | Rubber stamping | You've stopped being the Architect |

**The goal is NOT 100%.** The goal is thoughtful collaboration.

**Limitation:** This metric only captures the initial accept/reject decision. If you accept → test → iterate, that shows as 100% accept rate. Interpret alongside your other metrics.

---

## What NOT to Measure

| Metric | Problem |
|--------|---------|
| Commits, PRs, LOC | Gameable vanity metrics |
| Cost per output | Penalizes complex, thoughtful work |
| Developer comparisons | Creates competition, not collaboration |

You get what you measure. If you measure commits, people commit more. If you measure lines, people write verbose code.

---

## The Communication Loop

```
CONTEXT (CLAUDE.md, memory, structure)
    ↓
PROMPT (clear request with constraints)
    ↓
RESULT (Claude's implementation)
    ↓
REVIEW (does this match intent?)
    ↓
FEEDBACK (accept, reject, refine)
    ↓
LEARN (update CLAUDE.md if patterns emerge)
    ↓
  (loop)
```

**Where metrics diagnose problems:**

| Problem | Symptom | Fix |
|---------|---------|-----|
| Poor context | Low cache ratio | Better CLAUDE.md |
| Unclear prompts | Long sessions | Clearer initial requests |
| Not reviewing | High accept rate | Slow down, read diffs |
| Misalignment | Low accept rate | More examples, patterns |

---

## Prompt Review (Optional)

Share what works. Learn from each other.

**In PRs:**
```markdown
## How this was built
Key prompt: "Implement rate limiting using token bucket algorithm,
100 requests per minute per user, return 429 with Retry-After header"

What worked: Specifying the algorithm and response format upfront
```

This is not mandatory documentation or performance review material. It's collective learning.

---

## Quick Reference

| Metric | Target | Meaning |
|--------|--------|---------|
| Cache Ratio | >20:1 | Your context is working |
| Session Size | <100k | You're being efficient |
| Accept Rate | 75-85% | You're engaged |

---

*"The Architect decides what to build. AI helps build it right."*
