---
name: elegance-first
description: >
  Structured problem-framing discipline before solving non-trivial problems.
  Activate ONLY when the user explicitly requests it — phrases like "frame this",
  "think through this first", "elegance-first", "analyze before solving",
  "structure this problem", or "step back and think". Do NOT auto-trigger on
  general coding or implementation requests.
---

# Elegance-First Problem Framing

Before solving the problem, work through these four checkpoints and output each one
visibly under its own header. A checkpoint can be a single sentence — the discipline
is structure before solution, not structure instead of solution.

## 1. Structural Analysis

Identify explicitly:
- **What varies** across uses
- **What stays fixed** (invariants that must hold)
- **Where the problem actually starts and ends** — often not where the user described

If the user's description doesn't answer these, stop and ask. Don't assume and proceed.

## 2. Framing Check

Before optimizing, verify the framing is correct:
- Does the solution require separate handling of edge cases? If yes, consider whether
  reframing eliminates the distinction between edge and general case.
- Is the request to optimize *within* a bad framing? Name it before proceeding.
- Would a different abstraction boundary make adjacent problems simpler too?

If you reframe the problem, say so explicitly — never reframe silently.

## 3. Solution Selection

When multiple solutions work, prefer the one that:
- Collapses special cases into the general case
- Makes adjacent problems trivial (not just the current one simpler)
- Removes distinctions rather than handles them

If only one approach is viable, state that and why.

## 4. Implementation

Only after steps 1–3 are complete:
- Implement exactly what was agreed — no extras, no preemptive improvements
- If an improvement opportunity appears during implementation, mention it; don't implement it
- One change per interaction

## Interrupt Conditions

Return to step 1 if during implementation you encounter:
- An undiscussed edge case
- A conflict with stated invariants
- Ambiguity about scope

Do not resolve these silently. Surface the issue and re-run the relevant checkpoints.

## Example

User asks: "Write a function that normalizes different date formats to ISO 8601."

**1. Structural Analysis**
- Varies: input format (US, EU, ISO, natural language, timestamps)
- Fixed: output is always ISO 8601; invalid inputs must be rejected, not guessed
- Actual boundary: starts at a string, ends at a validated date — but the user may also need to handle timezone, which they haven't mentioned

→ Question: should the function handle timezone-aware inputs, or assume naive dates?

**2. Framing Check**
The natural approach is a chain of format-specific parsers tried in order. But that makes
every new format a new branch. Reframing: treat it as "parse any unambiguous date
representation" using a single flexible parser, and reject genuinely ambiguous inputs
(like 01/02/03) rather than guessing.

**3. Solution Selection**
Single parser with explicit ambiguity rejection > format-specific chain. Collapses the
per-format branches and makes adding new formats zero-cost.

**4. Implementation**
[proceeds after user confirms the timezone question]
