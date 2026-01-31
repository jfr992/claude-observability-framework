# Tuning Claude Code Configurations with Metrics

## The Problem

100% accept rate = passive acceptance, not critical thinking.
High cost per PR = inefficient prompting.
Many iterations = unclear instructions.

**Goal:** Use telemetry to optimize your CLAUDE.md, skills, agents, and memory files.

## Quality Indicators

### Accept Rate Interpretation

| Rate | Meaning | Action |
|------|---------|--------|
| <60% | Suggestions miss the mark | Improve context in CLAUDE.md |
| 60-75% | Good critical review | You're engaged, suggestions need work |
| 75-85% | **Optimal** | Good prompts, active review |
| 85-95% | Getting passive | Review more critically |
| >95% | Rubber stamping | You're not thinking |

### Efficiency Metrics

| Metric | Formula | Target |
|--------|---------|--------|
| Cost per PR | `total_cost / pr_count` | <$5 |
| Cost per Commit | `total_cost / commit_count` | <$1 |
| Tokens per Line | `total_tokens / lines_added` | <100 |
| Cache Efficiency | `cache_read / cache_created` | >20:1 |
| Tokens per Session | `total_tokens / session_count` | <100k |

### Compaction Risk (Tokens per Session)

High tokens per session indicates context compaction is likely happening, which means:
- Sessions running too long (unclear initial prompts)
- Too much back-and-forth iteration
- Context being rebuilt repeatedly
- Poor upfront context in CLAUDE.md/skills

| Tokens/Session | Meaning | Action |
|----------------|---------|--------|
| <100k | Efficient sessions | Good prompts, clear instructions |
| 100k-200k | Getting long | Consider clearer initial prompts |
| 200k-300k | Compaction likely | Improve CLAUDE.md, use skills |
| >300k | Highly inefficient | Major prompt/config issues |

**Why compaction is bad:**
1. Loss of context (important details may be summarized away)
2. Wasted tokens rebuilding context
3. Indicates unclear instructions requiring many turns
4. Higher cost for same output

### Session Quality

| Pattern | Indicates |
|---------|-----------|
| Short sessions, high output | Clear prompts, good context |
| Long sessions, low output | Unclear instructions, too much back-and-forth |
| High reject rate on specific tools | Missing permissions or unclear boundaries |
| Falling back to Opus often | Prompts might be too complex for Sonnet |

## A/B Testing Framework

### Step 1: Version Your Configs

Add version tracking to your environment:

```bash
# In your shell profile
export OTEL_RESOURCE_ATTRIBUTES="config_version=v1"
```

Update when you change CLAUDE.md or settings:
```bash
export OTEL_RESOURCE_ATTRIBUTES="config_version=v2"
```

### Step 2: What to Version

| Config | Location | What to Track |
|--------|----------|---------------|
| CLAUDE.md | Project root | Coding style, patterns, rules |
| Memory files | `~/.claude/memory/` | Persistent context |
| Skills | `~/.claude/skills/` | Custom commands |
| Agents | `~/.claude/agents/` | Specialized behaviors |
| Settings | `~/.claude/settings.json` | Permissions, defaults |

### Step 3: Compare Versions

```promql
# Cost efficiency by config version
sum by (config_version) (increase(claude_code_cost_usage_USD_total[7d]))
/
(sum by (config_version) (increase(claude_code_pull_request_count_total[7d])) > 0 or vector(1))

# Accept rate by config version
sum by (config_version) (max_over_time(claude_code_code_edit_tool_decision_total{decision="accept"}[7d]))
/
sum by (config_version) (max_over_time(claude_code_code_edit_tool_decision_total[7d]))
```

## Optimization Experiments

### Experiment 1: CLAUDE.md Specificity

**Hypothesis:** More specific CLAUDE.md = better suggestions = higher accept rate

| Version | CLAUDE.md Style | Expected Result |
|---------|-----------------|-----------------|
| v1 | Generic | Low accept rate, high iterations |
| v2 | Project-specific patterns | Higher accept rate |
| v3 | Examples + anti-patterns | Optimal accept rate (75-85%) |

### Experiment 2: Memory File Impact

**Hypothesis:** Good memory files = better cache ratio = lower cost

| Version | Memory Setup | Measure |
|---------|--------------|---------|
| v1 | No memory files | Baseline cache ratio |
| v2 | Key decisions documented | Improved cache ratio |
| v3 | Full context + examples | Maximum cache efficiency |

### Experiment 3: Skill Effectiveness

**Hypothesis:** Custom skills = faster task completion = fewer tokens

| Version | Skills | Measure |
|---------|--------|---------|
| v1 | Default only | Baseline tokens/task |
| v2 | Custom /commit, /review | Compare tokens/commit |
| v3 | Domain-specific skills | Tokens per task type |

## What to Put in CLAUDE.md for Better Metrics

### DO Include (Improves Suggestions)

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

### DON'T Include (Wastes Tokens)

```markdown
## Generic Advice
- Write clean code (too vague)
- Follow best practices (which ones?)
- Be careful (not actionable)
```

## Tracking Config Changes

Create a simple log:

```bash
# ~/.claude/config-changelog.md

## v3 - 2024-01-15
- Added specific error handling patterns
- Removed generic "be careful" advice
- Expected: +10% accept rate, -20% cost/PR

## v2 - 2024-01-10
- Added domain context (fintech, compliance)
- Added money handling rules
- Measured: 15% reduction in money-related rejects
```

## Dashboard Queries for Config Tuning

### Compare Config Versions

```promql
# Accepts by version
sum by (config_version) (
  increase(claude_code_code_edit_tool_decision_total{decision="accept"}[7d])
)

# Cost by version
sum by (config_version) (
  increase(claude_code_cost_usage_USD_total[7d])
)

# Cache efficiency by version
sum by (config_version) (increase(claude_code_token_usage_tokens_total{type="cacheRead"}[7d]))
/
sum by (config_version) (increase(claude_code_token_usage_tokens_total{type="cacheCreation"}[7d]))
```

### Detect Problems

```promql
# Sessions with high reject rate (>40%)
(
  sum by (session_id) (claude_code_code_edit_tool_decision_total{decision="reject"})
  /
  sum by (session_id) (claude_code_code_edit_tool_decision_total)
) > 0.4

# Expensive sessions (>$5)
sum by (session_id) (claude_code_cost_usage_USD_total) > 5
```

## Interpretation Guide

### If Accept Rate is Too High (>95%)

You're not reviewing critically. Try:
1. Actually read the diffs before accepting
2. Add stricter standards to CLAUDE.md
3. Look for edge cases Claude missed

### If Accept Rate is Too Low (<60%)

Claude is missing context. Try:
1. Add more examples to CLAUDE.md
2. Include anti-patterns to avoid
3. Document domain-specific rules
4. Add memory files with key decisions

### If Cost per PR is High (>$10)

Too many iterations or unclear prompts. Try:
1. Be more specific in initial prompts
2. Add task templates to skills
3. Include expected output format
4. Break complex tasks into steps

### If Cache Ratio is Low (<10:1)

Context isn't being reused. Try:
1. Consistent CLAUDE.md across sessions
2. Memory files for persistent context
3. Less variation in prompt structure

### If Tokens per Session is High (>200k)

Sessions are running too long before completion. Try:
1. More specific initial prompts (what, why, constraints)
2. Include expected output format upfront
3. Break complex tasks into smaller sessions
4. Add task templates to skills
5. Better CLAUDE.md with patterns and anti-patterns
6. Use memory files for persistent project context

High tokens/session = compaction happening = context being lost and rebuilt.

## The Meta-Goal

**Optimal Claude usage = you thinking critically + Claude executing efficiently**

The metrics should show:
- 75-85% accept rate (you're engaged)
- High cache ratio >20:1 (good context setup)
- Low tokens per session <100k (clear instructions)
- Low cost per output (efficient prompts)
- Few iterations (no compaction)

If you hit 100% accept, you've stopped thinking.
If you hit 50% accept, Claude has stopped understanding.
If your sessions hit 300k tokens, your prompts need work.
Find the balance where both of you contribute.
