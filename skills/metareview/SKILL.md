---
name: metareview
description: Mid-session quality audit — reads the captured conversation transcript and analyzes session health, communication breakdowns, and process gaps
---

## Overview

You are performing a mid-session quality audit. The transcript file is EXTERNAL EVIDENCE — treat it as ground truth. Do not rely on your own potentially-compressed or summarized context window memory. Reading the raw transcript breaks the self-referential loop where CC diagnoses itself using the same degraded state causing the problem.

## Step 1: Locate and Read the Transcript

Check the environment variable `METAREVIEW_TRANSCRIPT`. Use the Bash tool to resolve it:

```bash
echo "$METAREVIEW_TRANSCRIPT"
```

If the variable is empty or unset, stop and tell the user:

> "No transcript capture active. This session wasn't started through the metareview wrapper. To enable mid-session review, start your session with: `metareview <session-id>`"

If the variable is set, use the Read tool to read the file at that path. If the file does not exist or cannot be read, tell the user:

> "Transcript file not found at `$METAREVIEW_TRANSCRIPT`. The capture process may have failed or the path is stale."

If the file exists and is readable, proceed to Step 2.

## Step 2: Analyze the Transcript

Read the full file. Strip out ANSI escape codes and terminal formatting noise — focus on the actual content of the exchange. Look for:

### Delivery Check
- Identify every commitment CC made ("I will", "I'll", "let me", "here's", "done", "fixed", "added", "created", etc.)
- For each commitment: did CC actually deliver the artifact or complete the action?
- Did the user explicitly confirm it worked, or did they dispute it, or was it left unacknowledged?
- Flag anything promised but not verifiably delivered.

### Communication Check
- Has the user rephrased the same request more than once? Count instances.
- Has CC apologized and then produced output that repeats the same error or pattern?
- Is CC's response length increasing over time without a corresponding increase in actual deliverables? (Verbosity creep)
- Are there signs CC is hedging, over-explaining, or padding instead of acting?

### Process Check
- Were there moments where a skill should have been invoked but wasn't?
  - Complex feature work → `superpowers:writing-plans` before diving in
  - Creative or strategic decisions → `superpowers:brainstorming`
  - Bugs and test failures → `superpowers:systematic-debugging`
  - Completing a branch → `superpowers:finishing-a-development-branch`
  - Executing a multi-step plan → `superpowers:executing-plans`
- Were there multi-step tasks that should have had a written PLAN.md before execution?
- Should tasks have been created to track work items?
- Were the right tools used (Read vs Bash, Edit vs Write, Grep vs manual search)?

### User Pattern Check
- Is the user batching too many requests into a single prompt, making it hard for CC to track all items?
- Are any instructions ambiguous or under-specified in ways that caused preventable rework?
- Is there a mismatch between the user's apparent urgency and CC's pacing?

## Step 3: Check for Hard Exit Conditions

Evaluate whether ANY of these are true:
- 3 or more correction cycles on the same item (user corrects → CC fixes → same issue recurs)
- User rephrased the same core request 3 or more times
- CC apologized and produced substantially similar (wrong) output 3 or more times
- Clear signs of context window degradation: CC forgetting earlier decisions, contradicting itself, losing track of file paths or variable names, re-implementing things that were already done

If ANY hard exit condition is met, include a **HARD EXIT RECOMMENDATION** at the top of the report (before the session health score), formatted as:

```
⚠️  STRONG RECOMMENDATION: Start a new session.

This session shows [specific condition]. Continuing will likely compound the problem.

After exiting, run: metareview <session-id>
to get the full post-session diagnosis with transcript analysis.
```

## Step 4: Output the Report

Format the report exactly as follows:

```
## Mid-Session Review

**Session health:** [Green / Yellow / Red]

**Delivery status:**
- [Commitment description] (turn ~N): [delivered / missing / disputed]
- ...

**Issues detected:**
- [Issue description with turn reference or quote]
- ...

**Process notes:**
- [Skills that should have been invoked but weren't]
- [Plans or task lists that should have been written]
- [Tool misuse or suboptimal tool choices]

**User prompting notes:**
- [Constructive, non-judgmental suggestions for the user]
- ...

**Recommendation:**
[Continue / Address items before continuing / Start new session]
```

### Session health scoring:
- **Green**: Delivery is tracking, no repeated issues, communication is clear, right tools used
- **Yellow**: 1-2 missed items, some communication friction, minor process gaps, no hard exit triggers
- **Red**: Multiple missed commitments, repeated correction cycles, process breakdown, or any hard exit condition present

### Tone and style:
- Be precise and evidence-based. Quote from the transcript when citing an issue.
- Do not moralize or over-explain. Short, clear bullets.
- User prompting notes should be constructive — frame as "consider X" not "you did Y wrong."
- If the session is clean, say so clearly and briefly. Don't invent issues.
- The goal is a fast, honest read on session state — not a comprehensive literature review.
