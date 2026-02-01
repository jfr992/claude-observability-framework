# The Architect's Guide to AI Collaboration

A framework for human-AI co-intelligence. Not surveillance. Not productivity tracking. **Learning.**

---

## The Core Idea

You are the **Architect**. Claude is your **implementation partner**.

This isn't about measuring how much code Claude writes for you. It's about improving how you communicate, collaborate, and build together.

```
┌─────────────────────────────────────────────────────────────────┐
│                         YOU (Architect)                         │
├─────────────────────────────────────────────────────────────────┤
│  • System design & architecture                                 │
│  • Security principles & threat modeling                        │
│  • Non-functional requirements (performance, HA, scalability)   │
│  • Functional requirements & acceptance criteria                │
│  • Technology & SDK selection                                   │
│  • Code review & quality gates                                  │
│  • DRY, SOLID, patterns - the "why" behind decisions            │
│  • TDD strategy - what to test and why                          │
└─────────────────────────────────────────────────────────────────┘
                              ↕
                    (Clear Communication)
                              ↕
┌─────────────────────────────────────────────────────────────────┐
│                    CLAUDE (Implementation)                      │
├─────────────────────────────────────────────────────────────────┤
│  • Writing code that follows your patterns                      │
│  • Implementing tests you've designed                           │
│  • Exploring approaches you can evaluate                        │
│  • Refactoring with constraints you've set                      │
│  • Generating boilerplate you'd rather not type                 │
│  • Explaining options so you can decide                         │
└─────────────────────────────────────────────────────────────────┘
```

**The metric we care about:** How well does Claude understand your intent?

---

## Why NOT to Track

Before explaining what to measure, let's be clear about what NOT to measure and why:

### Don't Track: Commits, PRs, Lines of Code

These are **vanity metrics** that incentivize wrong behavior:

| Metric | Why It's Harmful |
|--------|------------------|
| Commit count | Incentivizes many small commits to inflate numbers |
| PR count | Incentivizes splitting work artificially |
| Lines of code | More code ≠ better code. Often the opposite. |
| Cost per commit | Penalizes thoughtful, complex work |

**The problem:** If you measure commits, people will commit more. If you measure lines, people will write verbose code. You get what you measure.

### Don't Track: Leaderboards

Comparing developers by AI usage metrics creates:
- Competition instead of collaboration
- Gaming behavior to look good
- Anxiety about being "at the bottom"
- Focus on metrics instead of outcomes

**This isn't a race.** Everyone's work is different. A developer doing complex architecture work will have different metrics than one doing bug fixes.

### Don't Track: "Productivity"

AI collaboration isn't about output volume. It's about:
- Making better decisions
- Catching issues earlier
- Learning new patterns
- Building maintainable systems

None of these show up in token counts.

---

## What TO Measure (And Why)

Three metrics tell you about your **communication quality** with Claude:

### 1. Cache Ratio (Is Your Context Working?)

```
Cache Ratio = Cache Reads / Cache Creates
```

| Ratio | What It Means | Action |
|-------|---------------|--------|
| <5:1 | Claude rebuilds context constantly | Your CLAUDE.md needs work |
| 5-10:1 | Some context reuse | Add more patterns and examples |
| 10-20:1 | Good | Keep refining |
| **>20:1** | **Excellent** | Claude understands your world |

**Why this matters:** A high cache ratio means Claude remembers your patterns, your preferences, your architecture. You're not repeating yourself. Your CLAUDE.md is doing its job.

**How to improve:**
```markdown
# In your CLAUDE.md

## Architecture Decisions
- We use the repository pattern for data access
- All API responses follow RFC 7807 Problem Details
- Example: see src/repositories/UserRepository.ts

## Security Requirements
- All user input must be validated with Zod schemas
- SQL queries use parameterized statements only
- Secrets come from environment variables, never hardcoded

## Our Patterns
- Prefer composition over inheritance
- Use early returns to reduce nesting
- Max function length: 30 lines
```

### 2. Session Size (Are You Going in Circles?)

```
Tokens per Session = Total Tokens / Session Count
```

| Size | What It Means | Action |
|------|---------------|--------|
| <100k | Efficient sessions | Good prompts, clear direction |
| 100-200k | Getting long | Consider breaking into phases |
| 200-300k | Compaction risk | Start fresh more often |
| >300k | Inefficient | Major communication issues |

**Why this matters:** Long sessions mean either:
1. Deep, complex work (fine)
2. Going in circles, unclear direction (problem)

When sessions get too long, Claude's context gets compacted - it forgets important details. You lose context and waste tokens rebuilding it.

**How to improve:**
- Start sessions with clear goals
- Use `/compact` when context gets stale
- Break large tasks into phases
- Know when a fresh session helps

### 3. Accept Rate (Are You Engaged?)

```
Accept Rate = Accepted Edits / Total Edits
```

| Rate | What It Means | Action |
|------|---------------|--------|
| <60% | Claude misunderstands you | Improve CLAUDE.md, clearer prompts |
| 60-75% | Healthy tension | You're reviewing carefully |
| **75-85%** | **Optimal** | Good communication, engaged review |
| 85-95% | Getting passive | Slow down, read more carefully |
| >95% | Rubber stamping | You've stopped being the Architect |

**Why this matters:** This isn't about Claude being "right" or "wrong." It's about whether you're engaged.

- Too low = Claude doesn't understand your context
- Too high = You're not reviewing critically

**The danger of 95%+:** You've stopped being the Architect. You're just approving code you haven't really read. When Claude makes a mistake (and it will), you won't catch it.

**The goal is NOT 100%.** The goal is thoughtful collaboration.

---

## The Architect's Responsibilities

When you use AI as a co-intelligence partner, your role shifts. You're not typing less - you're **thinking more**.

### 1. Security Principles

You define the security model. Claude implements it.

```markdown
# Your job (in CLAUDE.md or prompts):
- Define authentication strategy (JWT, sessions, OAuth)
- Specify authorization model (RBAC, ABAC, policies)
- Identify sensitive data and handling requirements
- Set encryption requirements (at rest, in transit)
- Define input validation rules

# Claude's job:
- Implement the patterns you've specified
- Follow security best practices you've outlined
- Flag potential issues for your review
```

### 2. Non-Functional Requirements

You set the constraints. Claude works within them.

```markdown
# Performance
- API responses < 200ms p99
- Batch processing handles 10k records
- Database queries must use indexes

# Availability
- Service must handle pod restarts gracefully
- Implement circuit breakers for external calls
- Health checks at /healthz and /readyz

# Scalability
- Stateless services (no local state)
- Horizontal scaling via replicas
- Queue-based processing for async work
```

### 3. Functional Requirements

You define what "done" looks like. Claude builds it.

```markdown
# Feature: User Registration
Given a valid email and password
When the user submits the registration form
Then a new account is created
And a verification email is sent
And the user is redirected to /verify-email

# Edge cases:
- Duplicate email: return 409 with clear message
- Weak password: return 400 with requirements
- Rate limit: 5 attempts per minute per IP
```

### 4. Technology Selection

You choose the stack. Claude works with it.

```markdown
# Stack Decisions
- Runtime: Node.js 20 (we need worker threads)
- Framework: Fastify (performance over Express)
- ORM: Drizzle (type-safe, good migrations)
- Validation: Zod (runtime + TypeScript inference)
- Testing: Vitest (faster than Jest, compatible API)

# Why these choices:
- [Link to ADR or decision doc]
```

### 5. Quality Gates

You define what quality means. Claude helps achieve it.

```markdown
# Code Quality
- All public functions have JSDoc comments
- No any types without explicit justification
- Test coverage > 80% for business logic
- E2E tests for critical paths

# Review Checklist
- [ ] Security: No hardcoded secrets, input validated
- [ ] Performance: No N+1 queries, pagination on lists
- [ ] Maintainability: Functions < 30 lines, clear names
- [ ] Testing: Happy path + edge cases covered
```

---

## The Communication Loop

Good AI collaboration is a feedback loop:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   1. CONTEXT                                                    │
│      └─ CLAUDE.md, memory files, project structure              │
│                         ↓                                       │
│   2. PROMPT                                                     │
│      └─ Clear request with constraints and examples             │
│                         ↓                                       │
│   3. RESULT                                                     │
│      └─ Claude's implementation attempt                         │
│                         ↓                                       │
│   4. REVIEW                                                     │
│      └─ You evaluate: Does this match intent?                   │
│                         ↓                                       │
│   5. FEEDBACK                                                   │
│      └─ Accept, reject, or refine                               │
│                         ↓                                       │
│   6. LEARN                                                      │
│      └─ Update CLAUDE.md if patterns emerge                     │
│                         │                                       │
│                         └───────────────────────────────────────┤
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**The metrics tell you where this loop breaks down:**

| Problem | Symptom | Fix |
|---------|---------|-----|
| Poor context | Low cache ratio | Better CLAUDE.md |
| Unclear prompts | Long sessions | Clearer initial requests |
| Not reviewing | High accept rate | Slow down, read diffs |
| Misalignment | Low accept rate | More examples, patterns |

---

## Anti-Patterns

### The Rubber Stamper

**Symptom:** Accept rate > 95%

**What's happening:** You're approving everything without reading.

**The cost:** Skills atrophy. When Claude is wrong, you won't catch it. You're no longer the Architect - you're just a button-clicker.

**The fix:** Before accepting, ask yourself: "Would I have written it this way? Why or why not?"

### The Micromanager

**Symptom:** Accept rate < 60%

**What's happening:** Claude doesn't understand your context.

**The cost:** You're not getting the collaboration benefit. Might as well type it yourself.

**The fix:** Invest in context. Write a proper CLAUDE.md. Include examples of code you like. Give Claude a chance to understand your style.

### The Context Burner

**Symptom:** Sessions > 300k tokens regularly

**What's happening:** You're either doing genuinely complex work or going in circles.

**The cost:** Context compaction loses important details. You spend tokens rebuilding context that was lost.

**The fix:** Fresh sessions for new tasks. Use `/compact` intentionally. Break large work into phases.

### The Vague Requester

**Symptom:** Low cache ratio, frequent misunderstandings

**What's happening:** Your prompts lack specificity. Claude guesses and often guesses wrong.

**The fix:** Include constraints, examples, and acceptance criteria. "Add pagination" → "Add cursor-based pagination, 50 items default, return next_cursor in response."

---

## Prompt Review (Not Audit)

Share what works. Learn from each other.

### The Idea

Code review made code quality visible. **Prompt review** makes AI collaboration visible.

When you review a PR, you see what changed. You don't see the prompts that created it. Sharing prompts helps everyone improve.

### How to Do It (Lightweight)

**In PRs:**
```markdown
## How this was built
Key prompt: "Implement rate limiting using token bucket algorithm,
100 requests per minute per user, return 429 with Retry-After header"

What worked: Specifying the algorithm and response format upfront
```

**In retros:**
- Share a prompt that worked surprisingly well
- Share one that took many iterations (and what finally worked)

**In your team:**
- Keep a shared doc of effective prompts
- Note what context they assume

### This Is NOT

- ❌ Mandatory documentation
- ❌ Tracking who prompts "correctly"
- ❌ Performance review material
- ❌ Another compliance checkbox

### This IS

- ✅ Sharing what works
- ✅ Learning from each other
- ✅ Building collective skill
- ✅ Making the implicit explicit

---

## The Meta-Point

```
You + Claude = Better than either alone

Your judgment + Claude's speed
Your context + Claude's patterns
Your vision + Claude's implementation
```

The metrics aren't scorecards. They're **mirrors**.

When you see something in the data, don't ask "Is this good enough?" Ask:

- What does this tell me about how I'm communicating?
- What would help Claude understand me better?
- Am I still the Architect, or have I abdicated?

---

## Quick Reference

### What You Own (Architect)
- Architecture & system design
- Security model & principles
- Performance & availability requirements
- Technology selection & rationale
- Code review & quality gates
- The "why" behind every decision

### What Claude Helps With (Implementation)
- Writing code within your constraints
- Implementing patterns you've defined
- Exploring options for you to evaluate
- Generating tests you've designed
- Refactoring with your rules
- Explaining tradeoffs so you can decide

### What to Measure (Communication)
| Metric | Target | Meaning |
|--------|--------|---------|
| Cache Ratio | >20:1 | Your context is working |
| Session Size | <100k | You're being efficient |
| Accept Rate | 75-85% | You're engaged |

### What NOT to Measure
- Commits, PRs, lines of code (gameable, meaningless)
- Cost per output (penalizes complex work)
- Developer comparisons (creates wrong incentives)

---

*"The best engineers don't just use AI - they architect with it. They bring judgment, security, and vision. AI brings speed, patterns, and patience. The Architect decides what to build. AI helps build it right."*
