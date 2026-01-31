# Human-AI Collaboration: Co-Intelligence, Not Replacement

## The Philosophy

Claude is a **co-intelligence** - designed to amplify your thinking, not replace it.

When you accept every suggestion without reading, you're not using AI assistance. You're abdicating your role as an engineer. Your mind atrophies. Your judgment weakens. You become a button-presser, not a craftsman.

**The goal is synergy:** Claude's speed and breadth + your judgment and depth.

## The Metrics That Keep You Human

### 1. Critical Thinking (Accept Rate)

| Rate | What It Means | What To Do |
|------|---------------|------------|
| <60% | Claude doesn't understand your context | Improve CLAUDE.md, add examples |
| 60-75% | Healthy friction | You're engaged, keep tuning |
| **75-85%** | **OPTIMAL** | You're reviewing critically |
| 85-95% | Getting passive | Slow down, read the diffs |
| >95% | **DANGER** | You've stopped thinking |

**Ask yourself before accepting:**
- Did I actually read this diff?
- Would I write it this way?
- Are there edge cases Claude missed?
- Does this match our patterns?

### 2. Prompt Quality (Cache Ratio)

High cache ratio means Claude understands your context. It means your CLAUDE.md, skills, and prompts are working.

| Ratio | Meaning |
|-------|---------|
| <5:1 | Claude is rebuilding context every time |
| 10-20:1 | Good context reuse |
| >20:1 | Excellent - your setup is working |

**To improve:** Write better CLAUDE.md with patterns, anti-patterns, and domain context.

### 3. Instruction Clarity (Tokens/Session)

High tokens per session means compaction is happening - context is being lost and rebuilt.

| Tokens | Meaning |
|--------|---------|
| <100k | Clear prompts, efficient sessions |
| 100-200k | Getting verbose |
| >300k | Compaction happening - context lost |

**To improve:** Be specific upfront. Include constraints, expected output, and context in your first message.

## Skills You Must Not Lose

### Technical Skills

| Skill | How AI Tempts Atrophy | How To Stay Sharp |
|-------|----------------------|-------------------|
| **Debugging** | "Claude will fix it" | Read the error first, form a hypothesis |
| **Architecture** | "Claude knows patterns" | Design the structure, let Claude implement |
| **Code Reading** | "Just accept and move on" | Read every diff, understand the changes |
| **Problem Decomposition** | "Give Claude the whole thing" | Break it down, prompt for pieces |
| **Testing** | "Claude writes tests" | Define the test cases, verify the logic |

### Judgment Skills

| Skill | What It Is | How To Preserve It |
|-------|------------|-------------------|
| **Trade-off Analysis** | Knowing when to choose X over Y | Ask Claude for options, YOU decide |
| **Context Awareness** | Understanding the bigger picture | Explain context to Claude, don't assume |
| **Quality Standards** | Knowing "good enough" | Reject suggestions that don't meet your bar |
| **Pattern Recognition** | Seeing what's wrong before running | Review code before testing |

## The Collaboration Contract

### What Claude Should Do

1. Execute your vision, not replace it
2. Offer options, not mandates
3. Explain reasoning, so you learn
4. Catch your blind spots
5. Move faster on boilerplate

### What You Should Do

1. **Think first** - Form an opinion before prompting
2. **Read everything** - Every diff, every suggestion
3. **Question suggestions** - "Is this the best way?"
4. **Provide context** - Claude can't read your mind
5. **Stay curious** - Understand why, not just what

## Red Flags: When You're Over-Relying

- You can't explain what the code does
- You haven't rejected a suggestion in days
- You prompt before thinking
- You feel anxious when Claude is slow
- Your code reviews are "LGTM" with no comments
- You can't work without AI assistance

## Green Flags: Healthy Co-Intelligence

- You reject ~20% of suggestions after consideration
- You modify suggestions to fit your style
- You can explain every line of code
- You use Claude for speed, not for thinking
- You're learning from Claude's suggestions
- You could work without AI (just slower)

## Prompting for Growth

### Instead of: "Fix this bug"
**Try:** "Here's my hypothesis about this bug: [X]. Can you verify and implement a fix?"

### Instead of: "Write tests for this"
**Try:** "I want to test these scenarios: [list]. Generate tests for them."

### Instead of: "Refactor this code"
**Try:** "This code has [specific problems]. Refactor with [specific constraints]."

### Instead of: "Build this feature"
**Try:** "I'm implementing [feature]. Here's my design: [sketch]. Implement with these patterns: [list]."

## Daily Practices

1. **Morning:** Review yesterday's AI-assisted code. Could you write it yourself?
2. **Before prompting:** Form your own approach first
3. **After accepting:** Verify you understand every change
4. **Weekly:** Try one task without AI to stay sharp
5. **Monthly:** Review your Accept Rate trend

## The Meta-Goal

```
Your skills + Claude's speed = 10x output at 10x quality

NOT:

Claude's skills replacing yours = 10x output at 1x understanding
```

When your Accept Rate is 75-85%, your Cache Ratio is >20, and your Tokens/Session is <100k, you're in the sweet spot:

- **You're thinking critically** (not rubber-stamping)
- **Claude understands you** (context is working)
- **Your prompts are clear** (efficient sessions)

This is co-intelligence. This is the goal.

---

*"The computer is incredibly fast, accurate, and stupid. The human is incredibly slow, inaccurate, and brilliant. Together they are powerful beyond imagination."* - Unknown (often misattributed to Einstein)
