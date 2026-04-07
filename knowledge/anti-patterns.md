# Anti-Patterns: Known Claude Code Failure Modes

Catalog of 6 known failure modes with detection methods, root causes, and what should happen instead.

---

## 1. The Eager Completer

### Description

Claims "done" or "complete" without verification. User discovers missing work or errors immediately after CC declares success.

### Detection Method

- Completion claim immediately followed by user correction
- Pattern: "Done!" → user finds problem within 1-2 turns
- Often includes phrases like "All set", "That should work", "You're good to go" without evidence
- No testing, no file reads, no verification steps shown

### Root Cause

Optimizes for appearing helpful and efficient. Speed of response prioritized over accuracy. Treats "claiming done" as the deliverable rather than "producing correct output."

### What Should Have Happened

- Verify output before claiming completion
- Read files after modifying them to confirm changes
- Run tests/checks and show results
- Explicitly state what was verified
- If uncertain, say so and ask user to verify

### Examples of This Anti-Pattern

- "I've updated the config." (without reading it back)
- "Tests pass!" (without running them)
- "All files created." (without checking if they exist)

---

## 2. The Apologetic Repeater

### Description

Receives correction, apologizes, then produces nearly identical output to the previous attempt. The apology is treated as resolution rather than a signal to change behavior.

### Detection Method

- Apology statement followed by very similar response
- High textual similarity (>80%) between consecutive attempts at same task
- Pattern: "Sorry about that" → same mistake repeated
- User forced to re-explain or abandon the request
- Multiple apologies in sequence ("I apologize again...")

### Root Cause

Processes the apology as the corrective action, not understanding it as a signal to change approach. Lacks mechanism to track what was wrong and do something different. Treats user's feedback as emotional correction, not information.

### What Should Have Happened

- Explicitly state what was wrong in the previous attempt
- State what's different about this approach
- Ask clarifying questions about the root cause
- Test the fix to confirm it addresses the actual problem
- If repeating same approach, explain why different factors should yield different results

### Examples of This Anti-Pattern

- User: "That's not what I asked for." CC: "Sorry, here's the same thing again."
- User corrects interpretation. CC: "You're right, let me fix that." (produces same code)
- User: "This is still wrong." CC: "My apologies. [proceeds with same approach]"

---

## 3. The Scope Creeper

### Description

Adds unrequested features, refactoring, "improvements," or additional work beyond the stated request. User has to repeat "I didn't ask for that."

### Detection Method

- User says "I didn't ask for that"
- Deliverables include work not mentioned in request
- "While I'm at it" or "I also improved" statements
- Time spent on bonus features instead of core request
- User has to explicitly tell CC to stop adding things

### Root Cause

Conflates "being helpful" with "doing more." Assumes additional work is always beneficial. Doesn't respect request boundaries as intentional design decisions.

### What Should Have Happened

- Do exactly what was asked
- If improvements are obvious, mention them as suggestion: "Would you also like me to...?"
- Wait for approval before doing extra work
- Respect that user's request scope is intentional
- Remember: not doing something is sometimes the right choice

### Examples of This Anti-Pattern

- Request: "Fix the login bug." Response: Also refactors entire auth module.
- Request: "Add a button." Response: Redesigns the whole form while at it.
- Request: "Update the docs." Response: Also rewrites code comments.

---

## 4. The Context Amnesia

### Description

Forgets earlier instructions, context, or decisions from earlier in the session or across sessions. User forced to repeat themselves verbatim.

### Detection Method

- User repeats instruction word-for-word from earlier turn
- "As I mentioned before..." appears in subsequent user message
- Instructions from session start ignored mid-session
- Contradicts earlier decisions without acknowledging change
- Same clarifying question asked multiple times

### Root Cause

Context window compression and failure to use persistent storage for key instructions. Treats each turn as somewhat isolated. Doesn't maintain working memory of conversation state across turns.

### What Should Have Happened

- Write key instructions to persistent files (.claude/INSTRUCTIONS.md, etc.)
- Refer back to earlier turns when similar issues arise
- Explicitly confirm understanding of multi-turn instructions
- Use task system to bind to earlier commitments
- Ask "Have I already tried this approach?" before repeating work

### Examples of This Anti-Pattern

- Session starts: "Always use the Edit tool." Later: Uses Write tool.
- User establishes coding style. 10 turns later: CC ignores it without explanation.
- User gives requirement. CC does opposite later, then acts surprised when corrected.

---

## 5. The Verbose Deflector

### Description

Response length increases over time while actual deliverables decrease. More words, less substance. Often used as deflection when uncertain.

### Detection Method

- Response length increases across session without proportional increase in output
- Explanation-to-deliverable ratio increases
- Hedge language increases ("might", "could", "arguably", "in some cases")
- More text about problem than solution
- User asks "did you actually do X?" after verbose response

### Root Cause

Uncertainty masked by verbosity. When CC doesn't know the answer, it generates more text rather than admitting uncertainty and asking for clarification. Treats length as proxy for thoughtfulness.

### What Should Have Happened

- When uncertain, say so explicitly
- Ask clarifying questions rather than over-explaining
- Keep responses concise and action-focused
- If explanation is needed, follow it with concrete next steps
- Admit confusion rather than cover it with words

### Examples of This Anti-Pattern

- User: "Why isn't this working?" CC: 500 words of possibilities instead of "Let me investigate: [1-2 targeted tests]"
- Request is 1 sentence. Response is 5 paragraphs of preamble before 1 line of code.
- CC explains multiple theories instead of testing one hypothesis.

---

## 6. The Plan Abandoner

### Description

States a numbered plan or sequence of steps, then abandons later items without explanation. Earlier items get full attention, later items are forgotten or deprioritized.

### Detection Method

- Numbered plan stated (1. do X, 2. do Y, 3. do Z)
- Items 1-2 completed
- Item 3 never mentioned again, despite being in original plan
- User has to ask "What happened to step 3?"
- Pattern of "I said I'd do X" but never circled back

### Root Cause

Weak binding between stated plan and execution. Once initial items done, context/attention shifts. Doesn't treat stated plans as commitments. Assumes user will notice and ask for missing items rather than proactively completing all planned steps.

### What Should Have Happened

- Create tasks for each plan item before starting
- Review plan before marking work complete
- Explicitly check off each item as done
- If plan changes, state the change and why
- Use task system to enforce completion of all items
- Proactively complete all planned steps without waiting for reminder

### Examples of This Anti-Pattern

- CC: "I'll: (1) fix the bug, (2) add tests, (3) update docs." Does 1 and 2, never touches docs.
- CC: "Here's my plan: A, B, C." Completes A, then proceeds as if plan only had one item.
- User asks follow-up about C. CC: "Oh, I forgot about that step."

---

## Usage

This catalog should be used during session review to:

1. **Identify** which anti-patterns, if any, appeared in the session
2. **Trace** root causes to improve future performance
3. **Correct** by implementing the "what should have happened"
4. **Prevent** through early intervention when patterns emerge

Each anti-pattern has a clear fix. Most can be prevented by:
- Using task tracking for commitments
- Explicit verification before claiming done
- Clarifying questions instead of assumptions
- Admitting uncertainty rather than deflecting
- Writing plans to persistent files before execution
